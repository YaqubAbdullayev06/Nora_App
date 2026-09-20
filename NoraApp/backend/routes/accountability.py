"""
Accountability Lock routes — guardian-set PIN locks on screen time.
"""

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user, hash_password, verify_password
from models.orm import AccountabilityLockModel, UserModel
from schemas import (
    AccountabilitySetupRequest,
    AccountabilityStatusResponse,
    AccountabilityVerifyRequest,
)

router = APIRouter(prefix="/accountability", tags=["accountability"])


@router.post("/setup")
def setup_accountability_lock(
    request: AccountabilitySetupRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Guardian sets a PIN lock on the user's account."""
    existing = db.query(AccountabilityLockModel).filter(
        AccountabilityLockModel.user_id == current_user.id,
        AccountabilityLockModel.is_active == True,
    ).first()

    if existing:
        raise HTTPException(status_code=400, detail="An active lock already exists. Unlink it first.")

    pin_hash = hash_password(request.pin)
    expires_at = None
    if request.lock_duration_days is not None and request.lock_duration_days > 0:
        expires_at = datetime.utcnow() + timedelta(days=request.lock_duration_days)

    lock = AccountabilityLockModel(
        user_id=current_user.id,
        pin_hash=pin_hash,
        guardian_name=request.guardian_name,
        lock_duration_days=request.lock_duration_days,
        expires_at=expires_at,
    )
    db.add(lock)
    db.commit()
    db.refresh(lock)

    return {
        "success": True,
        "lock": AccountabilityStatusResponse(
            is_active=True,
            guardian_name=lock.guardian_name,
            created_at=lock.created_at,
            expires_at=lock.expires_at,
            is_expired=False,
        ).model_dump(),
    }


@router.post("/verify")
def verify_accountability_pin(
    request: AccountabilityVerifyRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """User submits PIN to verify accountability lock."""
    lock = db.query(AccountabilityLockModel).filter(
        AccountabilityLockModel.user_id == current_user.id,
        AccountabilityLockModel.is_active == True,
    ).first()

    if not lock:
        raise HTTPException(status_code=404, detail="No active lock found")

    if lock.expires_at and datetime.utcnow() > lock.expires_at:
        lock.is_active = False
        db.commit()
        raise HTTPException(status_code=404, detail="Lock has expired")

    if not verify_password(request.pin, lock.pin_hash):
        raise HTTPException(status_code=401, detail="Incorrect PIN")

    return {"success": True, "verified": True}


@router.get("/status")
def get_accountability_status(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Check if an accountability lock is active."""
    lock = db.query(AccountabilityLockModel).filter(
        AccountabilityLockModel.user_id == current_user.id,
        AccountabilityLockModel.is_active == True,
    ).first()

    if not lock:
        return AccountabilityStatusResponse(
            is_active=False,
            guardian_name=None,
            created_at=None,
            expires_at=None,
            is_expired=False,
        ).model_dump()

    is_expired = lock.expires_at is not None and datetime.utcnow() > lock.expires_at
    if is_expired:
        lock.is_active = False
        db.commit()

    return AccountabilityStatusResponse(
        is_active=not is_expired,
        guardian_name=lock.guardian_name,
        created_at=lock.created_at,
        expires_at=lock.expires_at,
        is_expired=is_expired,
    ).model_dump()


@router.post("/unlink")
def unlink_accountability_lock(
    request: AccountabilityVerifyRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Guardian removes the lock (requires PIN)."""
    lock = db.query(AccountabilityLockModel).filter(
        AccountabilityLockModel.user_id == current_user.id,
        AccountabilityLockModel.is_active == True,
    ).first()

    if not lock:
        raise HTTPException(status_code=404, detail="No active lock found")

    if not verify_password(request.pin, lock.pin_hash):
        raise HTTPException(status_code=401, detail="Incorrect PIN")

    lock.is_active = False
    db.commit()

    return {"success": True, "unlinked": True}
