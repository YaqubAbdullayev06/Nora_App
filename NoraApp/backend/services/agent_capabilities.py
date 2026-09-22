from datetime import datetime, timedelta, timezone
from typing import Any, Optional
from urllib.parse import urlencode
import secrets


def _utcnow() -> datetime:
    """Naive UTC now — matches naive DateTime columns and focus windows."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


class AgentCapabilities:
    """Authenticated, app-safe capabilities exposed to NoraApp."""

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
        self._focus: dict[int, dict[str, Any]] = {}
        self._settings: dict[int, dict[str, Any]] = {}
        self._connected_accounts: dict[int, dict[str, str]] = {}
        self._oauth_states: dict[int, dict[str, str]] = {}

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

    def _user_settings(self, user_id: int) -> dict[str, Any]:
        return self._settings.setdefault(user_id, {
            "brightness": 60,
            "volume": 45,
            "airplane_mode": False,
            "screen_timeout": 60,
            "wifi": True,
        })

    def read_setting(self, user_id: int, name: str) -> dict[str, Any]:
        normalized = (name or "").strip().lower()
        if normalized not in self.device_settings:
            return {"success": False, "error": f'Setting "{name}" is not in the approved device settings allowlist.'}
        return {"success": True, "setting": normalized, "value": self._user_settings(user_id)[normalized]}

    def update_setting(self, user_id: int, name: str, value: Any, user_approved: bool) -> dict[str, Any]:
        normalized = (name or "").strip().lower()
        if normalized not in self.device_settings:
            return {"success": False, "error": f'Setting "{name}" is not in the approved device settings allowlist.'}
        if not user_approved:
            return {"success": False, "error": "Explicit user approval is required before changing a device setting."}

        rule = self.device_settings[normalized]
        if rule["type"] == "int":
            try:
                converted = int(value)
            except (TypeError, ValueError):
                return {"success": False, "error": f"Value for {normalized} must be an integer."}
            if not rule["min"] <= converted <= rule["max"]:
                return {"success": False, "error": f"Value for {normalized} must be between {rule['min']} and {rule['max']}."}
        else:
            if isinstance(value, str):
                lowered = value.strip().lower()
                if lowered in {"true", "1", "on", "yes"}:
                    converted = True
                elif lowered in {"false", "0", "off", "no"}:
                    converted = False
                else:
                    return {"success": False, "error": f"Value for {normalized} must be a boolean."}
            else:
                converted = bool(value)

        self._user_settings(user_id)[normalized] = converted
        return {"success": True, "setting": normalized, "value": converted}

    def focus_status(self, user_id: int, now: Optional[datetime] = None) -> dict[str, Any]:
        current = now or _utcnow()
        focus = self._focus.get(user_id)
        active = bool(focus and focus["start_at"] <= current < focus["end_at"])
        return {
            "success": True,
            "active": active,
            "label": focus["label"] if focus else None,
            "starts_at": focus["start_at"].isoformat() if focus else None,
            "ends_at": focus["end_at"].isoformat() if focus else None,
            "social_media_blocked": active,
        }

    def schedule_focus(self, user_id: int, start_time: str, duration_minutes: int, label: str) -> dict[str, Any]:
        try:
            parsed = datetime.strptime(start_time.strip(), "%H:%M").time()
            duration = int(duration_minutes)
        except (AttributeError, TypeError, ValueError):
            return {"success": False, "error": "Use a 24-hour start time such as 09:00 and an integer duration."}
        if duration <= 0 or duration > 1440:
            return {"success": False, "error": "Focus duration must be between 1 and 1440 minutes."}

        now = _utcnow()
        start = datetime.combine(now.date(), parsed)
        if start < now:
            start += timedelta(days=1)
        self._focus[user_id] = {"start_at": start, "end_at": start + timedelta(minutes=duration), "label": label.strip() or "Focus session"}
        return self.focus_status(user_id, now)

    def start_focus(self, user_id: int, duration_minutes: int, label: str) -> dict[str, Any]:
        now = _utcnow()
        start = (now - timedelta(seconds=1)).strftime("%H:%M")
        return self.schedule_focus(user_id, start, duration_minutes, label)

    def stop_focus(self, user_id: int) -> dict[str, Any]:
        self._focus.pop(user_id, None)
        return self.focus_status(user_id)

    def _social_blocked(self, user_id: int) -> Optional[dict[str, Any]]:
        if self.focus_status(user_id)["active"]:
            return {"success": False, "error": "Social-media access is blocked while focus mode is active."}
        return None

    def start_oauth(self, user_id: int, platform: str, redirect_uri: str) -> dict[str, Any]:
        blocked = self._social_blocked(user_id)
        if blocked:
            return blocked
        config = self.social_platforms.get((platform or "").strip().lower())
        if not config:
            return {"success": False, "error": "Platform is not in the approved social-media allowlist."}
        # H12: unpredictable CSRF state (timestamp was guessable)
        state = secrets.token_urlsafe(32)
        normalized = platform.strip().lower()
        self._oauth_states.setdefault(user_id, {})[normalized] = state
        query = urlencode({
            "client_id": config["client_id"],
            "redirect_uri": redirect_uri,
            "response_type": "code",
            "scope": " ".join(config["scopes"]),
            "state": state,
        })
        return {"success": True, "platform": normalized, "authorization_url": f"{config['auth_url']}?{query}", "state": state}

    def connect_account(self, user_id: int, platform: str, account_id: str) -> dict[str, Any]:
        blocked = self._social_blocked(user_id)
        if blocked:
            return blocked
        normalized = (platform or "").strip().lower()
        if normalized not in self.social_platforms:
            return {"success": False, "error": "Platform is not in the approved social-media allowlist."}
        if not account_id.strip():
            return {"success": False, "error": "Account ID is required."}
        self._connected_accounts.setdefault(user_id, {})[normalized] = account_id.strip()
        return {"success": True, "platform": normalized, "account_id": account_id.strip()}

    def post_content(self, user_id: int, platform: str, account_id: str, text: str) -> dict[str, Any]:
        blocked = self._social_blocked(user_id)
        if blocked:
            return blocked
        normalized = (platform or "").strip().lower()
        connected = self._connected_accounts.get(user_id, {}).get(normalized)
        if normalized not in self.social_platforms or connected != account_id.strip():
            return {"success": False, "error": "Connect the approved account before posting."}
        if not text.strip():
            return {"success": False, "error": "Text content is required."}
        return {"success": True, "platform": normalized, "account_id": account_id.strip(), "content_preview": text.strip()[:280]}


agent_capabilities = AgentCapabilities()
