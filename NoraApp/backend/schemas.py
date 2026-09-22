"""
Pydantic request / response schemas.
"""

from datetime import datetime
from typing import Any, List, Optional

from pydantic import BaseModel, validator

# ─── Auth ───


class UserCreate(BaseModel):
    email: str
    name: str
    password: str
    age_group: Optional[str] = None


class UserLogin(BaseModel):
    email: str
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    name: str
    created_at: datetime
    is_active: bool
    age_group: Optional[str] = None

    class Config:
        from_attributes = True


# ─── Focus Sessions ───


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


# ─── Content ───


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


# ─── AI Chat ───


class ChatRequest(BaseModel):
    message: str
    age_group: str = "adult"
    conversation_history: list[dict] = []


class ChatResponse(BaseModel):
    response: str
    model: str


# ─── Agent / Device ───


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


# ─── App Classification ───


class ClassifyAppsRequest(BaseModel):
    apps: list[dict]
    age_group: str = "adult"


class AnalyzeUsageRequest(BaseModel):
    usage_data: dict
    age_group: str = "adult"


# ─── AI Command ───


class AICommandRequest(BaseModel):
    command: str
    context: dict = {}
    age_group: str = "adult"
    conversation_history: list[dict] = []


class NotificationTextRequest(BaseModel):
    event_type: str
    age_group: str = "adult"
    context: dict = {}


# ─── Accountability Lock ───


class AccountabilitySetupRequest(BaseModel):
    pin: str
    guardian_name: str
    lock_duration_days: Optional[int] = None
    current_pin: Optional[str] = None

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


# ─── Daily Hard Cap ───


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


# ─── Habits ───


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
    # H2: client's UTC offset in minutes (east positive) for local-day boundaries
    tz_offset_minutes: int = 0


class HabitStatsResponse(BaseModel):
    total_habits: int
    active_habits: int
    today_completions: int
    today_screen_time_earned: int
    week_screen_time_earned: int


# ─── AI Task Decomposition ───


class TaskDecompositionRequest(BaseModel):
    task: str
    age_group: str = "adult"


# ─── AI Daily Plan ───


class DailyPlanRequest(BaseModel):
    age_group: str = "adult"
    goals: list[str] = []
    available_hours: float = 8.0
    energy_pattern: str = "normal"  # "morning_person", "night_owl", "normal"
    existing_commitments: list[dict] = []
    preferences: dict = {}


class DailyPlanResponse(BaseModel):
    success: bool
    plan: list[dict] = []
    summary: str = ""
    total_focus_minutes: int = 0
    total_break_minutes: int = 0
    tip: str = ""


# ─── AI Sentiment Check-in ───


class SentimentCheckinRequest(BaseModel):
    message: str
    age_group: str = "adult"
    context: dict = {}


class SentimentCheckinResponse(BaseModel):
    success: bool
    sentiment: str  # "positive", "negative", "neutral", "stressed", "motivated"
    confidence: float  # 0.0 - 1.0
    response: str
    suggestion: str = ""
    mood_score: int = 5  # 1-10 scale


# ─── AI Predictive Blocking ───


class PredictiveBlockingRequest(BaseModel):
    age_group: str = "adult"
    current_time: str = ""  # ISO format or "HH:MM"
    day_of_week: str = ""  # "monday", "tuesday", etc.
    recent_usage: dict = {}
    installed_apps: list[dict] = []


class PredictiveBlockingResponse(BaseModel):
    success: bool
    predictions: list[dict] = []
    proactive_nudges: list[dict] = []
    suggested_block: list[dict] = []
    summary: str = ""
