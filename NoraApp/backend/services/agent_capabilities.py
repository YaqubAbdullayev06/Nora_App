from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from urllib.parse import urlencode
import json
import secrets


def _utcnow() -> datetime:
    """Naive UTC now — matches naive DateTime columns and focus windows."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _default_settings() -> dict[str, Any]:
    return {
        "brightness": 60,
        "volume": 45,
        "airplane_mode": False,
        "screen_timeout": 60,
        "wifi": True,
    }


def _default_state() -> dict[str, Any]:
    """M13: full per-user agent state shape (persisted in agent_state table)."""
    return {
        "focus": None,
        "settings": _default_settings(),
        "connected_accounts": {},
        "oauth_states": {},
        "pending_approval": None,
    }


_STATE_KEYS = ("focus", "settings", "connected_accounts", "oauth_states", "pending_approval")

# M11: approval tokens are short-lived and single-use
APPROVAL_TTL_SECONDS = 300


class AgentCapabilities:
    """Authenticated, app-safe capabilities exposed to NoraApp.

    M13: all state (focus window, device settings, connected accounts, OAuth
    states, pending approvals) is persisted per user in the agent_state table
    so it survives process restarts (Render free tier restarts frequently).
    An in-memory dict remains as fallback when no DB session is provided
    (unit tests without a database).
    """

    device_settings = {
        "brightness": {"type": "int", "min": 0, "max": 100},
        "volume": {"type": "int", "min": 0, "max": 100},
        "airplane_mode": {"type": "bool"},
        "screen_timeout": {"type": "int", "min": 15, "max": 600},
        "wifi": {"type": "bool"},
    }
    social_platforms = {
        "x": {
            "auth_url": "https://twitter.com/i/oauth2/authorize",
            "token_url": "https://api.twitter.com/2/oauth2/token",
            "scopes": ["tweet.write", "users.read", "offline.access"],
            "client_id": "demo-x-client-id",
        },
        "linkedin": {
            "auth_url": "https://www.linkedin.com/oauth/v2/authorization",
            "token_url": "https://www.linkedin.com/oauth/v2/accessToken",
            "scopes": ["w_member_social", "r_liteprofile"],
            "client_id": "demo-linkedin-client-id",
        },
        "youtube": {
            "auth_url": "https://accounts.google.com/o/oauth2/v2/auth",
            "token_url": "https://oauth2.googleapis.com/token",
            "scopes": ["https://www.googleapis.com/auth/youtube.force-ssl"],
            "client_id": "demo-youtube-client-id",
        },
    }

    def __init__(self) -> None:
        # M13: fallback store used only when no DB session is passed
        self._memory: dict[int, dict[str, Any]] = {}

    def capabilities(self) -> dict[str, Any]:
        return {
            "success": True,
            "capabilities": {
                "focus_mode": ["schedule", "start", "status", "stop"],
                "device_settings": sorted(self.device_settings),
                "social_media": sorted(self.social_platforms),
                "system_access": ["read_only_status"],
            },
            "restricted": [
                "shell_execution",
                "arbitrary_file_write",
                "file_delete",
                "unrestricted_device_control",
            ],
        }

    # ─── M13: persisted state helpers ───

    def _load_state(self, db, user_id: int) -> dict[str, Any]:
        state = _default_state()
        if db is None:
            mem = self._memory.get(user_id)
            if mem is None:
                mem = self._memory[user_id] = state
            else:
                # pick up any keys added by a new app version
                for key, value in state.items():
                    mem.setdefault(key, value)
            return mem

        from models.orm import AgentStateModel

        rows = db.query(AgentStateModel).filter(
            AgentStateModel.user_id == user_id,
            AgentStateModel.state_key.in_(_STATE_KEYS),
        ).all()
        by_key = {row.state_key: row.state_value for row in rows}
        for key in _STATE_KEYS:
            raw = by_key.get(key)
            if raw is None:
                continue
            try:
                state[key] = json.loads(raw)
            except (json.JSONDecodeError, TypeError):
                pass  # corrupt row — keep default

        # focus window needs real datetimes back
        focus = state.get("focus")
        if isinstance(focus, dict) and focus.get("start_at") and focus.get("end_at"):
            try:
                focus["start_at"] = datetime.fromisoformat(str(focus["start_at"]))
                focus["end_at"] = datetime.fromisoformat(str(focus["end_at"]))
            except (ValueError, TypeError):
                state["focus"] = None
        else:
            state["focus"] = None

        settings = state.get("settings")
        if not isinstance(settings, dict):
            state["settings"] = _default_settings()
        else:
            for key, value in _default_settings().items():
                settings.setdefault(key, value)
        if not isinstance(state.get("connected_accounts"), dict):
            state["connected_accounts"] = {}
        if not isinstance(state.get("oauth_states"), dict):
            state["oauth_states"] = {}
        return state

    def _save_state(self, db, user_id: int, key: str, value: Any) -> None:
        if key not in _STATE_KEYS:
            raise ValueError(f"Unknown agent state key: {key}")

        serializable = value
        if key == "focus" and isinstance(value, dict):
            serializable = {
                "start_at": value["start_at"].isoformat()
                if isinstance(value.get("start_at"), datetime)
                else value.get("start_at"),
                "end_at": value["end_at"].isoformat()
                if isinstance(value.get("end_at"), datetime)
                else value.get("end_at"),
                "label": value.get("label", ""),
            }
        payload = json.dumps(serializable) if serializable is not None else None

        if db is None:
            mem = self._memory.setdefault(user_id, _default_state())
            mem[key] = value
            return

        from models.orm import AgentStateModel

        row = db.query(AgentStateModel).filter(
            AgentStateModel.user_id == user_id,
            AgentStateModel.state_key == key,
        ).first()
        if row:
            row.state_value = payload
            row.updated_at = datetime.utcnow()
        else:
            db.add(AgentStateModel(user_id=user_id, state_key=key, state_value=payload))
        db.commit()

    # ─── Device Settings ───

    def _coerce_setting_value(self, normalized: str, value: Any):
        """Validate + convert a setting value.

        Returns (True, converted) on success or (False, error_message).
        """
        rule = self.device_settings[normalized]
        if rule["type"] == "int":
            try:
                converted = int(value)
            except (TypeError, ValueError):
                return False, f"Value for {normalized} must be an integer."
            if not rule["min"] <= converted <= rule["max"]:
                return False, f"Value for {normalized} must be between {rule['min']} and {rule['max']}."
            return True, converted

        if isinstance(value, str):
            lowered = value.strip().lower()
            if lowered in {"true", "1", "on", "yes"}:
                return True, True
            if lowered in {"false", "0", "off", "no"}:
                return True, False
            return False, f"Value for {normalized} must be a boolean."
        return True, bool(value)

    def read_setting(self, user_id: int, name: str, db=None) -> dict[str, Any]:
        normalized = (name or "").strip().lower()
        if normalized not in self.device_settings:
            return {"success": False, "error": f'Setting "{name}" is not in the approved device settings allowlist.'}
        settings = self._load_state(db, user_id)["settings"]
        return {"success": True, "setting": normalized, "value": settings[normalized]}

    def propose_setting(self, user_id: int, name: str, value: Any, db=None) -> dict[str, Any]:
        """M11, step 1: validate a proposed change and issue a short-lived,
        single-use approval token. The client must show this change to the user
        and only then call update_setting with the returned token.
        """
        normalized = (name or "").strip().lower()
        if normalized not in self.device_settings:
            return {"success": False, "error": f'Setting "{name}" is not in the approved device settings allowlist.'}
        ok, converted = self._coerce_setting_value(normalized, value)
        if not ok:
            return {"success": False, "error": converted}

        token = secrets.token_urlsafe(32)
        self._save_state(db, user_id, "pending_approval", {
            "token": token,
            "setting": normalized,
            "value": converted,
            "expires_at": (_utcnow() + timedelta(seconds=APPROVAL_TTL_SECONDS)).isoformat(),
        })
        return {
            "success": True,
            "setting": normalized,
            "value": converted,
            "approval_token": token,
            "expires_in_seconds": APPROVAL_TTL_SECONDS,
        }

    def update_setting(
        self,
        user_id: int,
        name: str,
        value: Any,
        approval_token: Optional[str],
        db=None,
    ) -> dict[str, Any]:
        """M11, step 2: apply a change only with the server-issued token.

        The old boolean `user_approved` was client-asserted — any caller could
        claim approval without the user seeing anything.
        """
        normalized = (name or "").strip().lower()
        if normalized not in self.device_settings:
            return {"success": False, "error": f'Setting "{name}" is not in the approved device settings allowlist.'}

        state = self._load_state(db, user_id)
        pending = state.get("pending_approval")
        if (
            not approval_token
            or not isinstance(pending, dict)
            or not secrets.compare_digest(str(pending.get("token", "")), str(approval_token))
        ):
            return {
                "success": False,
                "error": "Explicit user approval is required before changing a device setting: "
                "call POST /agent/device/settings/propose, confirm the change with the user, "
                "then resend it with the issued approval_token.",
            }

        try:
            expires_at = datetime.fromisoformat(str(pending.get("expires_at", "")))
        except ValueError:
            expires_at = None
        if expires_at is None or _utcnow() > expires_at:
            self._save_state(db, user_id, "pending_approval", None)
            return {"success": False, "error": "Approval token expired — request a new one."}

        if pending.get("setting") != normalized:
            return {"success": False, "error": "Approval token was issued for a different setting."}

        ok, converted = self._coerce_setting_value(normalized, value)
        if not ok:
            return {"success": False, "error": converted}
        if pending.get("value") != converted:
            return {"success": False, "error": "Value differs from the change the user approved."}

        # Token is single-use — consume it before applying
        self._save_state(db, user_id, "pending_approval", None)
        settings = dict(self._load_state(db, user_id)["settings"])
        settings[normalized] = converted
        self._save_state(db, user_id, "settings", settings)
        return {"success": True, "setting": normalized, "value": converted}

    # ─── Focus ───

    def focus_status(self, user_id: int, now: Optional[datetime] = None, db=None) -> dict[str, Any]:
        current = now or _utcnow()
        focus = self._load_state(db, user_id).get("focus")
        active = bool(focus and focus["start_at"] <= current < focus["end_at"])
        return {
            "success": True,
            "active": active,
            "label": focus["label"] if focus else None,
            "starts_at": focus["start_at"].isoformat() if focus else None,
            "ends_at": focus["end_at"].isoformat() if focus else None,
            "social_media_blocked": active,
        }

    def schedule_focus(
        self,
        user_id: int,
        start_time: str,
        duration_minutes: int,
        label: str,
        tz_offset_minutes: int = 0,
        db=None,
    ) -> dict[str, Any]:
        try:
            parsed = datetime.strptime(start_time.strip(), "%H:%M").time()
            duration = int(duration_minutes)
        except (AttributeError, TypeError, ValueError):
            return {"success": False, "error": "Use a 24-hour start time such as 09:00 and an integer duration."}
        if duration <= 0 or duration > 1440:
            return {"success": False, "error": "Focus duration must be between 1 and 1440 minutes."}

        now = _utcnow()
        # M9: interpret start_time on the CLIENT's clock (minutes east of UTC),
        # not the server's UTC clock — "09:00" must mean the user's 9am.
        offset = timedelta(minutes=max(-840, min(840, int(tz_offset_minutes or 0))))
        local_now = now + offset
        start_local = datetime.combine(local_now.date(), parsed)
        if start_local < local_now:
            start_local += timedelta(days=1)
        start = start_local - offset  # back to UTC

        self._save_state(db, user_id, "focus", {
            "start_at": start,
            "end_at": start + timedelta(minutes=duration),
            "label": label.strip() or "Focus session",
        })
        return self.focus_status(user_id, now, db=db)

    def start_focus(self, user_id: int, duration_minutes: int, label: str, db=None) -> dict[str, Any]:
        """Start a focus session immediately.

        Previously this formatted "now" as HH:MM and went through
        schedule_focus, whose past-time check pushed the session to TOMORROW,
        so start-focus never reported active.
        """
        try:
            duration = int(duration_minutes)
        except (TypeError, ValueError):
            return {"success": False, "error": "Focus duration must be an integer number of minutes."}
        if duration <= 0 or duration > 1440:
            return {"success": False, "error": "Focus duration must be between 1 and 1440 minutes."}

        now = _utcnow()
        self._save_state(db, user_id, "focus", {
            "start_at": now - timedelta(seconds=1),
            "end_at": now + timedelta(minutes=duration),
            "label": label.strip() or "Focus session",
        })
        return self.focus_status(user_id, now, db=db)

    def stop_focus(self, user_id: int, db=None) -> dict[str, Any]:
        self._save_state(db, user_id, "focus", None)
        return self.focus_status(user_id, db=db)

    def _social_blocked(self, user_id: int, db=None) -> Optional[dict[str, Any]]:
        if self.focus_status(user_id, db=db)["active"]:
            return {"success": False, "error": "Social-media access is blocked while focus mode is active."}
        return None

    # ─── Social Media ───

    def start_oauth(self, user_id: int, platform: str, redirect_uri: str, db=None) -> dict[str, Any]:
        blocked = self._social_blocked(user_id, db=db)
        if blocked:
            return blocked
        config = self.social_platforms.get((platform or "").strip().lower())
        if not config:
            return {"success": False, "error": "Platform is not in the approved social-media allowlist."}
        # H12: unpredictable CSRF state (timestamp was guessable)
        state = secrets.token_urlsafe(32)
        normalized = platform.strip().lower()
        states = dict(self._load_state(db, user_id).get("oauth_states") or {})
        states[normalized] = state
        self._save_state(db, user_id, "oauth_states", states)
        query = urlencode({
            "client_id": config["client_id"],
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(config["scopes"]),
            "state": state,
        })
        return {"success": True, "platform": normalized, "authorization_url": f"{config['auth_url']}?{query}", "state": state}

    def connect_account(
        self,
        user_id: int,
        platform: str,
        account_id: str,
        state: Optional[str] = None,
        db=None,
    ) -> dict[str, Any]:
        blocked = self._social_blocked(user_id, db=db)
        if blocked:
            return blocked
        normalized = (platform or "").strip().lower()
        if normalized not in self.social_platforms:
            return {"success": False, "error": "Platform is not in the approved social-media allowlist."}
        if not account_id.strip():
            return {"success": False, "error": "Account ID is required."}

        # M14: verify the CSRF state issued by start_oauth, then consume it
        oauth_states = dict(self._load_state(db, user_id).get("oauth_states") or {})
        stored_state = oauth_states.get(normalized)
        if not stored_state:
            return {"success": False, "error": "No pending OAuth flow for this platform — start OAuth first."}
        if not state or not secrets.compare_digest(str(stored_state), str(state)):
            return {"success": False, "error": "OAuth state mismatch — restart the OAuth flow."}
        oauth_states.pop(normalized, None)  # single-use
        self._save_state(db, user_id, "oauth_states", oauth_states)

        accounts = dict(self._load_state(db, user_id).get("connected_accounts") or {})
        accounts[normalized] = account_id.strip()
        self._save_state(db, user_id, "connected_accounts", accounts)
        return {"success": True, "platform": normalized, "account_id": account_id.strip()}

    def post_content(self, user_id: int, platform: str, account_id: str, text: str, db=None) -> dict[str, Any]:
        blocked = self._social_blocked(user_id, db=db)
        if blocked:
            return blocked
        normalized = (platform or "").strip().lower()
        connected = (self._load_state(db, user_id).get("connected_accounts") or {}).get(normalized)
        if normalized not in self.social_platforms or connected != account_id.strip():
            return {"success": False, "error": "Connect the approved account before posting."}
        if not text.strip():
            return {"success": False, "error": "Text content is required."}
        return {"success": True, "platform": normalized, "account_id": account_id.strip(), "content_preview": text.strip()[:280]}


agent_capabilities = AgentCapabilities()
