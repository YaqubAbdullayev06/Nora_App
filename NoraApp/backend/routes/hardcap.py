"""
Daily Hard Cap routes — set / query / deactivate screen time limits.
"""

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user, verify_password
from models.orm import AccountabilityLockModel, DailyHardCapModel, SessionModel, UserModel
from schemas import HardCapDeactivateRequest, HardCapSetupRequest, HardCapStatusResponse

router = APIRouter(prefix="/hardcap", tags=["hardcap"])


def _today_usage_minutes(db: Session, user_id: int, tz_offset_minutes: int = 0) -> int:
    """Sum of focus-session minutes started today (local day).

    Uses tz_offset_minutes to calculate the user's local midnight.
    """
    from routes.habits import _local_today_start
    today_start = _local_today_start(tz_offset_minutes)
    total = (
        db.query(func.coalesce(func.sum(SessionModel.duration_minutes), 0))
        .filter(
            SessionModel.user_id == user_id,
            SessionModel.started_at >= today_start,
        )
        .scalar()
    )
    return int(total or 0)


@router.post("/setup")
def setup_hard_cap(
    request: HardCapSetupRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """User sets a daily total screen time hard cap."""
    existing = db.query(DailyHardCapModel).filter(
        DailyHardCapModel.user_id == current_user.id,
        DailyHardCapModel.is_active == True,
    ).first()

    if existing:
        # Update existing cap
        existing.cap_minutes = request.cap_minutes
        existing.soft_warning_percent = request.soft_warning_percent
        existing.hard_warning_percent = request.hard_warning_percent
        existing.require_pin_to_override = request.require_pin_to_override
        db.commit()
        db.refresh(existing)
        cap = existing
    else:
        cap = DailyHardCapModel(
            user_id=current_user.id,
            cap_minutes=request.cap_minutes,
            soft_warning_percent=request.soft_warning_percent,
            hard_warning_percent=request.hard_warning_percent,
            require_pin_to_override=request.require_pin_to_override,
        )
        db.add(cap)
        db.commit()
        db.refresh(cap)

    return {
        "success": True,
        "cap": HardCapStatusResponse(
            is_active=True,
            cap_minutes=cap.cap_minutes,
            soft_warning_percent=cap.soft_warning_percent,
            hard_warning_percent=cap.hard_warning_percent,
            require_pin_to_override=cap.require_pin_to_override,
            today_usage_minutes=_today_usage_minutes(db, current_user.id, request.tz_offset_minutes if hasattr(request, 'tz_offset_minutes') else 0),
            created_at=cap.created_at,
        ).model_dump(),
    }


@router.get("/status")
def get_hard_cap_status(
    tz_offset_minutes: int = 0,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Check if a hard cap is active."""
    cap = db.query(DailyHardCapModel).filter(
        DailyHardCapModel.user_id == current_user.id,
        DailyHardCapModel.is_active == True,
    ).first()

    if not cap:
        return HardCapStatusResponse(
            is_active=False,
            cap_minutes=None,
            soft_warning_percent=80,
            hard_warning_percent=90,
            require_pin_to_override=False,
            today_usage_minutes=_today_usage_minutes(db, current_user.id, tz_offset_minutes),
            created_at=None,
        ).model_dump()

    return HardCapStatusResponse(
        is_active=True,
        cap_minutes=cap.cap_minutes,
        soft_warning_percent=cap.soft_warning_percent,
        hard_warning_percent=cap.hard_warning_percent,
        require_pin_to_override=cap.require_pin_to_override,
        today_usage_minutes=_today_usage_minutes(db, current_user.id, tz_offset_minutes),
        created_at=cap.created_at,
    ).model_dump()


@router.post("/deactivate")
def deactivate_hard_cap(
    request: Optional[HardCapDeactivateRequest] = None,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deactivate the user's hard cap.

    M32: when the cap was set up with require_pin_to_override, deactivation
    (an override) requires the accountability-lock PIN — previously the flag
    was stored but never enforced anywhere.
    """
    cap = db.query(DailyHardCapModel).filter(
        DailyHardCapModel.user_id == current_user.id,
        DailyHardCapModel.is_active == True,
    ).first()

    if not cap:
        raise HTTPException(status_code=404, detail="No active hard cap found")

    if cap.require_pin_to_override:
        lock = db.query(AccountabilityLockModel).filter(
            AccountabilityLockModel.user_id == current_user.id,
            AccountabilityLockModel.is_active == True,
        ).first()
        lock_expired = bool(
            lock and lock.expires_at and datetime.utcnow() > lock.expires_at
        )
        # Enforce only while an unexpired lock (and its PIN) actually exists;
        # with no lock there is no PIN to check and the user would be locked out.
        if lock and not lock_expired:
            pin = request.pin if request else None
            if not pin:
                raise HTTPException(
                    status_code=400,
                    detail="PIN required to deactivate this hard cap",
                )
            if not verify_password(pin, lock.pin_hash):
                raise HTTPException(status_code=401, detail="Incorrect PIN")

    cap.is_active = False
    db.commit()

    return {"success": True, "deactivated": True}
