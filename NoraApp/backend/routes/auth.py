"""
Auth routes — register, login, token refresh, /me.
"""

import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import (
    create_access_token,
    create_refresh_token,
    get_current_user,
    hash_password,
    parse_subject,
    verify_password,
)
from models.orm import UserModel
from schemas import UserCreate, UserLogin, UserResponse

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(UserModel).filter(UserModel.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = UserModel(
        email=user.email,
        name=user.name,
        password_hash=hash_password(user.password),
        refresh_token_family=str(uuid.uuid4()),
        age_group=user.age_group,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = create_access_token({"sub": new_user.id})
    refresh = create_refresh_token({"sub": new_user.id}, family=new_user.refresh_token_family)
    return {"user": UserResponse.model_validate(new_user), "token": token, "refresh_token": refresh}


@router.post("/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.email == credentials.email).first()
    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token({"sub": user.id})
    # Rotate refresh token family on login — invalidates any previously issued refresh token
    new_family = str(uuid.uuid4())
    user.refresh_token_family = new_family
    db.commit()
    refresh = create_refresh_token({"sub": user.id}, family=new_family)
    return {"user": UserResponse.model_validate(user), "token": token, "refresh_token": refresh}


@router.post("/refresh")
def refresh_token(refresh_req: dict, db: Session = Depends(get_db)):
    """Exchange a valid refresh token for a new access + refresh token pair.

    Validates token family to detect refresh token reuse (theft).
    On successful rotation, the old refresh token is invalidated.
    """
    from core.security import SECRET_KEY, ALGORITHM
    from jwt.exceptions import PyJWTError as JWTError
    import jwt as _jwt

    token_str = refresh_req.get("refresh_token")
    if not token_str:
        raise HTTPException(status_code=400, detail="refresh_token required")

    try:
        payload = _jwt.decode(token_str, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        user_id = parse_subject(payload)
        token_family = payload.get("family")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    # Validate token family — if it doesn't match, the token was reused (stolen)
    if token_family and user.refresh_token_family and token_family != user.refresh_token_family:
        # Family mismatch = token reuse detected. Invalidate all sessions for this user.
        user.refresh_token_family = str(uuid.uuid4())
        db.commit()
        raise HTTPException(
            status_code=401,
            detail="Refresh token reuse detected — all sessions invalidated",
        )

    # Rotate: issue new family so the old refresh token is now invalid
    new_family = str(uuid.uuid4())
    user.refresh_token_family = new_family
    db.commit()

    new_access = create_access_token({"sub": user.id})
    new_refresh = create_refresh_token({"sub": user.id}, family=new_family)
    return {"token": new_access, "refresh_token": new_refresh}


@router.get("/me", response_model=UserResponse)
def get_me(current_user: UserModel = Depends(get_current_user)):
    return UserResponse.model_validate(current_user)
