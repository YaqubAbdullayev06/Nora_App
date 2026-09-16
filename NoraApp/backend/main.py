from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr, Field, validator
from typing import Any, List, Optional
from datetime import datetime, timedelta
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Float, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker, Session
import jwt
from jwt.exceptions import PyJWTError as JWTError
import uvicorn
import os
import bcrypt
from dotenv import load_dotenv

# ─── Load .env BEFORE importing AI modules (they read env vars at import time) ───
load_dotenv()

from ai.ollama_client import ollama
from ai.llm_provider import llm
from ai.prompts import get_system_prompt, get_assistant_system_prompt, check_crisis, CRISIS_RESPONSE
from services.agent_capabilities import agent_capabilities
from services.app_classifier import app_classifier

# ─── Database Setup ───

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./nora.db")
# SQLite needs check_same_thread; PostgreSQL/MySQL do not
_connect_args = {"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
engine = create_engine(DATABASE_URL, connect_args=_connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# ─── JWT Config ───

SECRET_KEY = os.getenv("SECRET_KEY", "nora-secret-key-change-in-production")
ALGORITHM = "HS256"

# SECURITY: Access tokens expire in 15 minutes (not 7 days).
# Refresh tokens last 30 days. The client stores both in secure storage
# and rotates the access token automatically via /auth/refresh.
ACCESS_TOKEN_EXPIRE_MINUTES = 15
REFRESH_TOKEN_EXPIRE_DAYS = 30

# ─── Password Hashing ───

security = HTTPBearer(auto_error=False)

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")

def verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))

# ─── Database Models ───

class UserModel(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(255), nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    sessions = relationship("SessionModel", back_populates="user")
    achievements = relationship("UserAchievementModel", back_populates="user")

class SessionModel(Base):
    __tablename__ = "focus_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    completed = Column(Boolean, default=False)
    points_earned = Column(Integer, default=0)
    session_type = Column(String(50), default="pomodoro")
    started_at = Column(DateTime, default=datetime.utcnow)
    ended_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)

    user = relationship("UserModel", back_populates="sessions")

class ContentModel(Base):
    __tablename__ = "content"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(100), nullable=False)
    content_type = Column(String(50), nullable=False)
    duration_minutes = Column(Integer, nullable=False)
    points = Column(Integer, default=0)
    url = Column(String(500), nullable=True)
    tags = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

class AchievementModel(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=False)
    icon = Column(String(100), nullable=False)
    color = Column(String(50), nullable=False)
    requirement_type = Column(String(100), nullable=False)
    requirement_value = Column(Integer, nullable=False)
    points = Column(Integer, default=0)

class UserAchievementModel(Base):
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    achievement_id = Column(Integer, ForeignKey("achievements.id"), nullable=False)
    earned_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("UserModel", back_populates="achievements")
    achievement = relationship("AchievementModel")

class RecommendationModel(Base):
    __tablename__ = "ai_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content_id = Column(Integer, ForeignKey("content.id"), nullable=False)
    reason = Column(Text, nullable=False)
    confidence_score = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_dismissed = Column(Boolean, default=False)


class AccountabilityLockModel(Base):
    __tablename__ = "accountability_locks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    pin_hash = Column(String(255), nullable=False)
    guardian_name = Column(String(255), nullable=True)
    lock_duration_days = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)
    is_active = Column(Boolean, default=True)


class DailyHardCapModel(Base):
    __tablename__ = "daily_hard_caps"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    cap_minutes = Column(Integer, nullable=False)  # Total daily screen time limit
    soft_warning_percent = Column(Integer, default=80)  # Show soft warning at 80%
    hard_warning_percent = Column(Integer, default=90)  # Show hard warning at 90%
    require_pin_to_override = Column(Boolean, default=False)  # Need PIN to bypass at 100%
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    user = relationship("UserModel")


class HabitModel(Base):
    __tablename__ = "habits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False)
    category = Column(String, default="general")  # exercise, reading, meditation, outdoor, custom
    icon = Column(String, default="check_circle")  # Icon name
    color = Column(String, default="#4CAF50")  # Hex color
    screen_time_minutes = Column(Integer, default=15)  # Minutes earned per completion
    target_per_day = Column(Integer, default=1)  # How many times per day
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("UserModel")


class HabitCompletionModel(Base):
    __tablename__ = "habit_completions"

    id = Column(Integer, primary_key=True, index=True)
    habit_id = Column(Integer, ForeignKey("habits.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    completed_at = Column(DateTime, default=datetime.utcnow)
    duration_minutes = Column(Integer, default=0)  # Optional: actual duration
    screen_time_earned = Column(Integer, default=0)  # Minutes earned

    habit = relationship("HabitModel")
    user = relationship("UserModel")


# ─── Pydantic Schemas ───

class UserCreate(BaseModel):
    email: str
    name: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime
    is_active: bool

    class Config:
        from_attributes = True

class SessionCreate(BaseModel):
    duration_minutes: int
    session_type: str = "pomodoro"
    notes: Optional[str] = None

class SessionResponse(BaseModel):
    id: int
    user_id: int
    duration_minutes: int
    completed: bool
    points_earned: int
    session_type: str
    started_at: datetime
    ended_at: Optional[datetime]

    class Config:
        from_attributes = True

class ContentCreate(BaseModel):
    title: str
    description: Optional[str] = None
    category: str
    content_type: str
    duration_minutes: int
    points: int = 0
    url: Optional[str] = None
    tags: List[str] = []

class ContentResponse(BaseModel):
    id: int
    title: str
    description: Optional[str]
    category: str
    content_type: str
    duration_minutes: int
    points: int
    url: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

class FocusScoreResponse(BaseModel):
    user_id: int
    total_points: int
    total_focus_minutes: int
    average_session_length: float
    sessions_completed: int

class ChatRequest(BaseModel):
    message: str
    age_group: str = "adult"
    conversation_history: list[dict] = []

class ChatResponse(BaseModel):
    response: str
    model: str


class FocusScheduleRequest(BaseModel):
    start_time: str
    duration_minutes: int
    label: str = "Focus session"


class FocusStartRequest(BaseModel):
    duration_minutes: int
    label: str = "Focus session"


class DeviceSettingUpdateRequest(BaseModel):
    setting: str
    value: Any
    user_approved: bool = False


class SocialOAuthRequest(BaseModel):
    platform: str
    redirect_uri: str


class SocialConnectRequest(BaseModel):
    platform: str
    account_id: str


class SocialPostRequest(BaseModel):
    platform: str
    account_id: str
    text: str


class ClassifyAppsRequest(BaseModel):
    apps: list[dict]
    age_group: str = "adult"


class AccountabilitySetupRequest(BaseModel):
    pin: str
    guardian_name: str
    lock_duration_days: Optional[int] = None

    @validator("pin")
    def pin_must_be_4_to_6_digits(cls, v):
        if not v.isdigit() or len(v) < 4 or len(v) > 6:
            raise ValueError("PIN must be 4-6 digits")
        return v


class AccountabilityVerifyRequest(BaseModel):
    pin: str


class AccountabilityStatusResponse(BaseModel):
    is_active: bool
    guardian_name: Optional[str]
    created_at: Optional[datetime]
    expires_at: Optional[datetime]
    is_expired: bool


class HardCapSetupRequest(BaseModel):
    cap_minutes: int
    soft_warning_percent: int = 80
    hard_warning_percent: int = 90
    require_pin_to_override: bool = False

    @validator("cap_minutes")
    def cap_must_be_reasonable(cls, v):
        if v < 30 or v > 720:  # 30 min to 12 hours
            raise ValueError("Cap must be between 30 and 720 minutes")
        return v


class HardCapStatusResponse(BaseModel):
    is_active: bool
    cap_minutes: Optional[int]
    soft_warning_percent: int
    hard_warning_percent: int
    require_pin_to_override: bool
    today_usage_minutes: Optional[int]
    created_at: Optional[datetime]


class HabitCreateRequest(BaseModel):
    name: str
    category: str = "general"
    icon: str = "check_circle"
    color: str = "#4CAF50"
    screen_time_minutes: int = 15
    target_per_day: int = 1

    @validator("screen_time_minutes")
    def screen_time_must_be_reasonable(cls, v):
        if v < 5 or v > 120:  # 5 min to 2 hours
            raise ValueError("Screen time earned must be between 5 and 120 minutes")
        return v


class HabitResponse(BaseModel):
    id: int
    name: str
    category: str
    icon: str
    color: str
    screen_time_minutes: int
    target_per_day: int
    is_active: bool
    completions_today: int = 0
    created_at: Optional[datetime]

    class Config:
        from_attributes = True


class HabitCompleteRequest(BaseModel):
    habit_id: int
    duration_minutes: int = 0


class HabitStatsResponse(BaseModel):
    total_habits: int
    active_habits: int
    today_completions: int
    today_screen_time_earned: int
    week_screen_time_earned: int


class AnalyzeUsageRequest(BaseModel):
    usage_data: dict
    age_group: str = "adult"


class AICommandRequest(BaseModel):
    command: str
    context: dict = {}
    age_group: str = "adult"
    conversation_history: list[dict] = []


# ─── Structured Action Schemas (Pydantic) ───
# Model output is UNTRUSTED. Every action must validate against these schemas.

VALID_ACTION_TYPES = {"scan_apps", "block_apps", "unblock_apps", "start_focus", "show_usage", "show_recommendations", "analyze_usage"}
BLOCKED_EMERGENCY_PACKAGES = {"com.android.phone", "com.android.dialer", "com.apple.mobilephone", "com.google.android.apps.maps"}


class ValidatedAction(BaseModel):
    """A validated AI action. Model output is parsed and checked against this schema."""
    action: str
    packages: list[str] = []
    minutes: int = 25
    description: str = ""

    @validator("action")
    def action_must_be_valid(cls, v):
        if v not in VALID_ACTION_TYPES:
            raise ValueError(f"Invalid action type: {v}. Must be one of: {VALID_ACTION_TYPES}")
        return v

    @validator("packages")
    def no_emergency_apps_blocked(cls, v):
        for pkg in v:
            if pkg in BLOCKED_EMERGENCY_PACKAGES:
                raise ValueError(f"Cannot block emergency app: {pkg}")
        return v

    @validator("minutes")
    def minutes_in_range(cls, v):
        if v < 1 or v > 120:
            raise ValueError(f"Minutes must be 1-120, got {v}")
        return v


def validate_actions(raw_actions: list[dict]) -> list[dict]:
    """Validate raw action dicts against Pydantic schemas. Returns only valid actions."""
    validated = []
    for raw in raw_actions:
        try:
            action = ValidatedAction(**raw)
            validated.append(action.model_dump())
        except Exception as e:
            # Invalid action — skip it, log it, do NOT execute it
            print(f"[ACTION VALIDATION FAILED] {raw} — {e}")
    return validated

# ─── App Setup ───

app = FastAPI(
    title="Nora API",
    description="AI-Powered Focus & Productivity App Backend",
    version="1.0.0"
)

# CORS: allow your Flutter app domains + localhost for dev
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
):
    if credentials is None:
        raise HTTPException(status_code=401, detail="Not authenticated")
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = int(payload.get("sub"))
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    return user

def create_access_token(data: dict):
    to_encode = data.copy()
    to_encode["sub"] = str(to_encode["sub"])
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire, "type": "access"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def create_refresh_token(data: dict):
    to_encode = data.copy()
    to_encode["sub"] = str(to_encode["sub"])
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

# ─── Seed Data ───

def seed_content(db: Session):
    if db.query(ContentModel).count() == 0:
        contents = [
            ContentModel(title="Python Basics", description="Learn the fundamentals of Python programming", category="Programming", content_type="video", duration_minutes=5, points=50, tags="coding,python,beginner"),
            ContentModel(title="Meditation Tips", description="5 techniques for better focus and clarity", category="Wellness", content_type="article", duration_minutes=3, points=30, tags="meditation,focus,wellness"),
            ContentModel(title="Business Strategy", description="Essential strategies for startups", category="Business", content_type="video", duration_minutes=7, points=70, tags="business,startup,strategy"),
            ContentModel(title="Language Learning", description="Effective methods to learn new languages", category="Education", content_type="flashcard", duration_minutes=4, points=40, tags="languages,learning,education"),
            ContentModel(title="Financial Literacy", description="Understanding personal finance basics", category="Finance", content_type="article", duration_minutes=6, points=60, tags="finance,money,budgeting"),
            ContentModel(title="Public Speaking", description="Tips for confident presentations", category="Skills", content_type="video", duration_minutes=8, points=80, tags="speaking,presentation,confidence"),
        ]
        db.add_all(contents)
        db.commit()

# ─── Routes ───

@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    seed_content(db)
    db.close()

@app.get("/")
async def root():
    return {"message": "Nora API is running", "version": "1.0.0"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

# ─── Auth ───

@app.post("/auth/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(UserModel).filter(UserModel.email == user.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = UserModel(
        email=user.email,
        name=user.name,
        password_hash=hash_password(user.password)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    token = create_access_token({"sub": new_user.id})
    refresh = create_refresh_token({"sub": new_user.id})
    return {"user": UserResponse.from_orm(new_user), "token": token, "refresh_token": refresh}

@app.post("/auth/login")
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.email == credentials.email).first()
    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    token = create_access_token({"sub": user.id})
    refresh = create_refresh_token({"sub": user.id})
    return {"user": UserResponse.from_orm(user), "token": token, "refresh_token": refresh}

@app.post("/auth/refresh")
def refresh_token(refresh_req: dict, db: Session = Depends(get_db)):
    """Exchange a valid refresh token for a new access + refresh token pair."""
    token_str = refresh_req.get("refresh_token")
    if not token_str:
        raise HTTPException(status_code=400, detail="refresh_token required")

    try:
        payload = jwt.decode(token_str, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(status_code=401, detail="Invalid token type")
        user_id = int(payload.get("sub"))
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid token")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired refresh token")

    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")

    new_access = create_access_token({"sub": user.id})
    new_refresh = create_refresh_token({"sub": user.id})
    return {"token": new_access, "refresh_token": new_refresh}

@app.get("/auth/me", response_model=UserResponse)
def get_me(current_user: UserModel = Depends(get_current_user)):
    return UserResponse.from_orm(current_user)


# ─── Accountability Lock ───

@app.post("/accountability/setup")
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


@app.post("/accountability/verify")
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


@app.get("/accountability/status")
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
            is_active=False, guardian_name=None,
            created_at=None, expires_at=None, is_expired=False,
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


@app.post("/accountability/unlink")
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


# ─── Daily Hard Cap ───

@app.post("/hardcap/setup")
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


@app.get("/hardcap/status")
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
            is_active=False, cap_minutes=None,
            soft_warning_percent=80, hard_warning_percent=90,
            require_pin_to_override=False, today_usage_minutes=None,
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


@app.post("/hardcap/deactivate")
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


# ─── Habits ───

@app.post("/habits")
def create_habit(
    request: HabitCreateRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Create a new habit."""
    habit = HabitModel(
        user_id=current_user.id,
        name=request.name,
        category=request.category,
        icon=request.icon,
        color=request.color,
        screen_time_minutes=request.screen_time_minutes,
        target_per_day=request.target_per_day,
    )
    db.add(habit)
    db.commit()
    db.refresh(habit)
    return {"success": True, "habit_id": habit.id}


@app.get("/habits")
def list_habits(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List user's habits with today's completion count."""
    habits = db.query(HabitModel).filter(
        HabitModel.user_id == current_user.id,
        HabitModel.is_active == True,
    ).all()

    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    result = []
    for habit in habits:
        completions_today = db.query(HabitCompletionModel).filter(
            HabitCompletionModel.habit_id == habit.id,
            HabitCompletionModel.user_id == current_user.id,
            HabitCompletionModel.completed_at >= today_start,
        ).count()
        result.append({
            "id": habit.id,
            "name": habit.name,
            "category": habit.category,
            "icon": habit.icon,
            "color": habit.color,
            "screen_time_minutes": habit.screen_time_minutes,
            "target_per_day": habit.target_per_day,
            "is_active": habit.is_active,
            "completions_today": completions_today,
            "created_at": habit.created_at,
        })
    return {"success": True, "habits": result}


@app.post("/habits/complete")
def complete_habit(
    request: HabitCompleteRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Log habit completion and earn screen time."""
    habit = db.query(HabitModel).filter(
        HabitModel.id == request.habit_id,
        HabitModel.user_id == current_user.id,
        HabitModel.is_active == True,
    ).first()

    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")

    # Check daily limit
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    today_completions = db.query(HabitCompletionModel).filter(
        HabitCompletionModel.habit_id == habit.id,
        HabitCompletionModel.user_id == current_user.id,
        HabitCompletionModel.completed_at >= today_start,
    ).count()

    if today_completions >= habit.target_per_day:
        raise HTTPException(status_code=400, detail="Daily target already reached")

    # Create completion
    completion = HabitCompletionModel(
        habit_id=habit.id,
        user_id=current_user.id,
        duration_minutes=request.duration_minutes,
        screen_time_earned=habit.screen_time_minutes,
    )
    db.add(completion)
    db.commit()

    return {
        "success": True,
        "screen_time_earned": habit.screen_time_minutes,
        "completions_today": today_completions + 1,
        "target_per_day": habit.target_per_day,
    }


@app.delete("/habits/{habit_id}")
def delete_habit(
    habit_id: int,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Deactivate a habit."""
    habit = db.query(HabitModel).filter(
        HabitModel.id == habit_id,
        HabitModel.user_id == current_user.id,
    ).first()

    if not habit:
        raise HTTPException(status_code=404, detail="Habit not found")

    habit.is_active = False
    db.commit()

    return {"success": True, "deactivated": True}


@app.get("/habits/stats")
def get_habit_stats(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get habit completion statistics."""
    today_start = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    week_start = today_start - timedelta(days=7)

    total_habits = db.query(HabitModel).filter(
        HabitModel.user_id == current_user.id,
    ).count()

    active_habits = db.query(HabitModel).filter(
        HabitModel.user_id == current_user.id,
        HabitModel.is_active == True,
    ).count()

    today_completions = db.query(HabitCompletionModel).filter(
        HabitCompletionModel.user_id == current_user.id,
        HabitCompletionModel.completed_at >= today_start,
    ).count()

    today_screen_time = db.query(func.sum(HabitCompletionModel.screen_time_earned)).filter(
        HabitCompletionModel.user_id == current_user.id,
        HabitCompletionModel.completed_at >= today_start,
    ).scalar() or 0

    week_screen_time = db.query(func.sum(HabitCompletionModel.screen_time_earned)).filter(
        HabitCompletionModel.user_id == current_user.id,
        HabitCompletionModel.completed_at >= week_start,
    ).scalar() or 0

    return {
        "success": True,
        "total_habits": total_habits,
        "active_habits": active_habits,
        "today_completions": today_completions,
        "today_screen_time_earned": today_screen_time,
        "week_screen_time_earned": week_screen_time,
    }


# ─── Safe Agent Capabilities ───

@app.get("/agent/capabilities")
def get_agent_capabilities():
    return agent_capabilities.capabilities()


@app.get("/agent/focus/status")
def get_agent_focus_status(current_user: UserModel = Depends(get_current_user)):
    return agent_capabilities.focus_status(current_user.id)


@app.post("/agent/focus/schedule")
def schedule_agent_focus(
    request: FocusScheduleRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.schedule_focus(
        current_user.id,
        request.start_time,
        request.duration_minutes,
        request.label,
    )


@app.post("/agent/focus/start")
def start_agent_focus(
    request: FocusStartRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.start_focus(
        current_user.id,
        request.duration_minutes,
        request.label,
    )


@app.post("/agent/focus/stop")
def stop_agent_focus(current_user: UserModel = Depends(get_current_user)):
    return agent_capabilities.stop_focus(current_user.id)


@app.get("/agent/device/settings")
def list_agent_device_settings(current_user: UserModel = Depends(get_current_user)):
    return {
        "success": True,
        "settings": sorted(agent_capabilities.device_settings),
    }


@app.get("/agent/device/settings/{setting}")
def read_agent_device_setting(
    setting: str,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.read_setting(current_user.id, setting)


@app.post("/agent/device/settings")
def update_agent_device_setting(
    request: DeviceSettingUpdateRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.update_setting(
        current_user.id,
        request.setting,
        request.value,
        request.user_approved,
    )


@app.get("/agent/social/platforms")
def list_agent_social_platforms(current_user: UserModel = Depends(get_current_user)):
    return {
        "success": True,
        "platforms": sorted(agent_capabilities.social_platforms),
    }


@app.post("/agent/social/oauth/start")
def start_agent_social_oauth(
    request: SocialOAuthRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.start_oauth(
        current_user.id,
        request.platform,
        request.redirect_uri,
    )


@app.post("/agent/social/connect")
def connect_agent_social_account(
    request: SocialConnectRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.connect_account(
        current_user.id,
        request.platform,
        request.account_id,
    )


@app.post("/agent/social/post")
def post_agent_social_content(
    request: SocialPostRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.post_content(
        current_user.id,
        request.platform,
        request.account_id,
        request.text,
    )


# ─── AI App Classification ───

@app.post("/ai/classify-apps")
def classify_apps(request: ClassifyAppsRequest):
    """AI-powered app classification and blocking recommendations."""
    return app_classifier.classify_apps(request.apps, request.age_group)


@app.post("/ai/analyze-usage")
def analyze_usage(request: AnalyzeUsageRequest):
    """AI-powered usage analysis with insights and recommendations."""
    return app_classifier.analyze_usage(request.usage_data, request.age_group)


# ─── AI Digital Assistant Command ───

@app.post("/ai/command")
async def ai_command(request: AICommandRequest):
    """
    AI Digital Assistant — processes commands and executes actions.
    The AI can: scan apps, block apps, analyze usage, start focus, etc.
    """
    from ai.prompts import get_assistant_system_prompt

    # SAFETY: Children (1-6) do NOT use the digital assistant
    if request.age_group == "child":
        return {
            "response": "Nora Little is a learning companion for young children. "
                        "For device management, please use the parent's account.",
            "model": "none",
            "actions": [],
        }

    # CRISIS DETECTION: Check user input for crisis keywords
    if check_crisis(request.command):
        return {
            "response": CRISIS_RESPONSE,
            "model": ollama.get_model_for_age_group(request.age_group),
            "actions": [],
            "crisis_detected": True,
        }

    system_prompt = get_assistant_system_prompt(request.age_group, request.context)
    messages = [{"role": "system", "content": system_prompt}]

    for msg in request.conversation_history:
        messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})

    messages.append({"role": "user", "content": request.command})

    try:
        response = await ollama.chat(messages, temperature=0.5)

        # CRISIS DETECTION: Check AI response for crisis content too
        if check_crisis(response):
            return {
                "response": CRISIS_RESPONSE,
                "model": ollama.get_model_for_age_group(request.age_group),
                "actions": [],
                "crisis_detected": True,
            }

        # Parse response for actions
        raw_actions = _parse_actions_from_response(response)

        # VALIDATE actions against Pydantic schemas (model output is untrusted)
        validated_actions = validate_actions(raw_actions)

        return {
            "response": response,
            "model": ollama.get_model_for_age_group(request.age_group),
            "actions": validated_actions,
        }
    except Exception as e:
        return {
            "response": f"I had trouble processing that. Error: {str(e)}",
            "model": ollama.get_model_for_age_group(request.age_group),
            "actions": [],
        }


def _parse_actions_from_response(response: str) -> list[dict]:
    """Parse AI response for structured actions.

    Strategy:
      1. Extract JSON objects from the response (LLM is prompted to output JSON actions).
      2. Keep only objects that contain an "action" key with a valid action type.
      3. If no JSON actions found, fall back to keyword matching for simple intents.
    """
    import json as _json

    actions = []

    # ── Pass 1: Extract JSON action blocks from the response ──
    i = 0
    while i < len(response):
        brace = response.find('{', i)
        if brace == -1:
            break

        # Find matching closing brace (handles nested braces inside arrays)
        depth = 0
        j = brace
        while j < len(response):
            if response[j] == '{':
                depth += 1
            elif response[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1

        if depth == 0:
            candidate = response[brace:j + 1]
            try:
                parsed = _json.loads(candidate)
                if isinstance(parsed, dict) and "action" in parsed:
                    actions.append(parsed)
            except _json.JSONDecodeError:
                pass  # Not valid JSON — skip
            i = j + 1
        else:
            i += 1

    # ── Pass 2: Keyword fallback (only if no JSON actions found) ──
    if not actions:
        response_lower = response.lower()

        if any(phrase in response_lower for phrase in ["scan your apps", "scan installed", "check your apps"]):
            actions.append({"action": "scan_apps"})

        if any(phrase in response_lower for phrase in ["start focus", "begin focus", "start a focus session"]):
            actions.append({"action": "start_focus", "minutes": 25})

        if any(phrase in response_lower for phrase in ["usage report", "screen time", "usage summary", "show usage"]):
            actions.append({"action": "show_usage"})

        if any(phrase in response_lower for phrase in ["show recommendation", "ai recommendation"]):
            actions.append({"action": "show_recommendations"})

        # NOTE: "block_apps" is NOT included in keyword fallback because we need
        # the actual package names from the LLM. If the user asks to block apps
        # and the LLM doesn't return JSON, it just gives a text suggestion.

    return actions

# ─── Users ───

@app.get("/users/{user_id}", response_model=UserResponse)
def get_user(user_id: int, db: Session = Depends(get_db)):
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.from_orm(user)

# ─── Focus Sessions ───

@app.post("/sessions/", response_model=SessionResponse)
def create_session(
    session: SessionCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    new_session = SessionModel(
        user_id=current_user.id,
        duration_minutes=session.duration_minutes,
        session_type=session.session_type,
        notes=session.notes,
    )
    db.add(new_session)
    db.commit()
    db.refresh(new_session)
    return SessionResponse.from_orm(new_session)

@app.get("/sessions/", response_model=List[SessionResponse])
def get_user_sessions(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    sessions = db.query(SessionModel).filter(
        SessionModel.user_id == current_user.id
    ).order_by(SessionModel.started_at.desc()).all()
    return [SessionResponse.from_orm(s) for s in sessions]

@app.put("/sessions/{session_id}/complete")
def complete_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    session = db.query(SessionModel).filter(
        SessionModel.id == session_id,
        SessionModel.user_id == current_user.id,
    ).first()
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")

    session.completed = True
    session.ended_at = datetime.utcnow()
    session.points_earned = session.duration_minutes * 10
    db.commit()

    return {"message": "Session completed", "points_earned": session.points_earned}

# ─── Content ───

@app.get("/content/", response_model=List[ContentResponse])
def get_content(category: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(ContentModel).filter(ContentModel.is_active == True)
    if category:
        query = query.filter(ContentModel.category == category)
    return [ContentResponse.from_orm(c) for c in query.all()]

@app.post("/content/", response_model=ContentResponse)
def create_content(content: ContentCreate, db: Session = Depends(get_db)):
    new_content = ContentModel(
        title=content.title,
        description=content.description,
        category=content.category,
        content_type=content.content_type,
        duration_minutes=content.duration_minutes,
        points=content.points,
        url=content.url,
        tags=",".join(content.tags) if content.tags else None,
    )
    db.add(new_content)
    db.commit()
    db.refresh(new_content)
    return ContentResponse.from_orm(new_content)

# ─── Focus Score ───

@app.get("/focus-score/", response_model=FocusScoreResponse)
def get_focus_score(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    sessions = db.query(SessionModel).filter(
        SessionModel.user_id == current_user.id
    ).all()

    total_points = sum(s.points_earned for s in sessions)
    total_minutes = sum(s.duration_minutes for s in sessions if s.completed)
    completed = [s for s in sessions if s.completed]

    return FocusScoreResponse(
        user_id=current_user.id,
        total_points=total_points,
        total_focus_minutes=total_minutes,
        average_session_length=total_minutes / len(completed) if completed else 0,
        sessions_completed=len(completed),
    )

# ─── AI Chat ───

@app.post("/ai/chat", response_model=ChatResponse)
async def ai_chat(request: ChatRequest):
    """Chat with Nora AI — powered by local Ollama LLM."""

    # SAFETY: Children (1-6) do NOT chat with the LLM
    if request.age_group == "child":
        return ChatResponse(
            response="Nora Little is a learning companion for young children. "
                     "Let's read a story or learn colors together!",
            model="none",
        )

    # CRISIS DETECTION: Check user input for crisis keywords
    if check_crisis(request.message):
        return ChatResponse(
            response=CRISIS_RESPONSE,
            model=ollama.get_model_for_age_group(request.age_group),
        )

    # Build messages with age-appropriate system prompt
    system_prompt = get_system_prompt(request.age_group)
    messages = [{"role": "system", "content": system_prompt}]

    # Add conversation history
    for msg in request.conversation_history:
        messages.append({"role": msg.get("role", "user"), "content": msg.get("content", "")})

    # Add current user message
    messages.append({"role": "user", "content": request.message})

    # Pick best model for age group
    model = ollama.get_model_for_age_group(request.age_group)

    # Get response from Ollama
    try:
        response = await ollama.chat(messages, temperature=0.7)

        # CRISIS DETECTION: Check AI response for crisis content
        if check_crisis(response):
            return ChatResponse(response=CRISIS_RESPONSE, model=model)

        return ChatResponse(response=response, model=model)
    except Exception as e:
        return ChatResponse(
            response=f"I'm having trouble connecting to my brain right now. All LLM providers failed. Error: {str(e)}",
            model=model,
        )

@app.get("/ai/health")
async def ai_health():
    """Check which LLM providers are available (Groq, Gemini, Cloudflare, Ollama)."""
    provider_status = await llm.is_available()
    any_available = any(provider_status.values())
    return {
        "providers": provider_status,
        "ollama_running": any_available,  # backward compat: True if ANY provider works
        "llm_available": any_available,
        "active_provider": llm.preferred_provider,
        "groq_model": llm.groq_model,
        "gemini_model": llm.gemini_model,
        "cloudflare_model": llm.cloudflare_model,
        "ollama_base_url": llm.ollama_base_url,
        "ollama_colab_url": llm.ollama_colab_url or "(not set)",
    }

# ─── AI Task Decomposition ───

class TaskDecompositionRequest(BaseModel):
    task: str = Field(..., min_length=2, max_length=500, description="Task to decompose")
    age_group: str = Field(default="adult", description="User age group")

@app.post("/ai/decompose-task")
async def decompose_task(request: TaskDecompositionRequest):
    """
    Decompose a broad task into Pomodoro-sized subtasks (15-25 min each).

    Example: "Write quarterly report" -> 5 subtasks with priorities and time estimates.
    """
    from ai.task_decomposer import decompose_task as _decompose

    result = await _decompose(
        task=request.task,
        age_group=request.age_group,
    )

    if result["success"]:
        return {
            "success": True,
            "subtasks": result["data"].get("subtasks", []),
            "original_task": result["data"].get("original_task", request.task),
            "total_estimated_minutes": result["data"].get("total_estimated_minutes", 0),
            "tip": result["data"].get("tip", ""),
            "provider": result.get("provider", "unknown"),
        }
    else:
        raise HTTPException(
            status_code=500,
            detail=f"Task decomposition failed: {result.get('error', 'unknown')}"
        )

# ─── Recommendations ───

@app.get("/recommendations/")
def get_recommendations(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user)
):
    # Simple recommendation: return random content
    contents = db.query(ContentModel).filter(ContentModel.is_active == True).limit(3).all()
    return [
        {
            "content_id": c.id,
            "title": c.title,
            "reason": f"Based on your interest in {c.category}",
            "confidence_score": 0.85,
        }
        for c in contents
    ]

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
