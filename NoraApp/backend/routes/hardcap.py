"""
Daily Hard Cap routes — set / query / deactivate screen time limits.
"""

from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user
from models.orm import DailyHardCapModel, UserModel
from schemas import HardCapSetupRequest, HardCapStatusResponse

router = APIRouter(prefix="/hardcap", tags=["hardcap"])


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
            today_usage_minutes=None,
            created_at=cap.created_at,
        ).model_dump(),
    }


@router.get("/status")
def get_hard_cap_status(
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
            today_usage_minutes=None,
            created_at=None,
        ).model_dump()

    return HardCapStatusResponse(
        is_active=True,
        cap_minutes=cap.cap_minutes,
        soft_warning_percent=cap.soft_warning_percent,
        hard_warning_percent=cap.hard_warning_percent,
        require_pin_to_override=cap.require_pin_to_override,
        today_usage_minutes=None,
        created_at=cap.created_at,
    ).model_dump()


@router.post("/deactivate")
def deactivate_hard_cap(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deactivate the user's hard cap."""
    cap = db.query(DailyHardCapModel).filter(
        DailyHardCapModel.user_id == current_user.id,
        DailyHardCapModel.is_active == True,
    ).first()

    if not cap:
        raise HTTPException(status_code=404, detail="No active hard cap found")

    cap.is_active = False
    db.commit()

    return {"success": True, "deactivated": True}
