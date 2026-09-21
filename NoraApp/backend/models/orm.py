"""
SQLAlchemy ORM models — one canonical source for all database tables.
"""

from datetime import datetime

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import relationship

from core.database import Base


class UserModel(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    name = Column(String(255), nullable=False)
    password_hash = Column(String(255), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    refresh_token_family = Column(String(36), nullable=True, index=True)

    sessions = relationship("SessionModel", back_populates="user")
    achievements = relationship("UserAchievementModel", back_populates="user")


class SessionModel(Base):
    __tablename__ = "focus_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
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
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    achievement_id = Column(Integer, ForeignKey("achievements.id"), nullable=False, index=True)
    earned_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("UserModel", back_populates="achievements")
    achievement = relationship("AchievementModel")


class RecommendationModel(Base):
    __tablename__ = "ai_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    content_id = Column(Integer, ForeignKey("content.id"), nullable=False, index=True)
    reason = Column(Text, nullable=False)
    confidence_score = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_dismissed = Column(Boolean, default=False)


class AccountabilityLockModel(Base):
    __tablename__ = "accountability_locks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
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
    cap_minutes = Column(Integer, nullable=False)
    soft_warning_percent = Column(Integer, default=80)
    hard_warning_percent = Column(Integer, default=90)
    require_pin_to_override = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=True)

    user = relationship("UserModel")


class HabitModel(Base):
    __tablename__ = "habits"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    name = Column(String, nullable=False)
    category = Column(String, default="general")
    icon = Column(String, default="check_circle")
    color = Column(String, default="#4CAF50")
    screen_time_minutes = Column(Integer, default=15)
    target_per_day = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("UserModel")


class HabitCompletionModel(Base):
    __tablename__ = "habit_completions"

    id = Column(Integer, primary_key=True, index=True)
    habit_id = Column(Integer, ForeignKey("habits.id"), nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    completed_at = Column(DateTime, default=datetime.utcnow)
    duration_minutes = Column(Integer, default=0)
    screen_time_earned = Column(Integer, default=0)

    habit = relationship("HabitModel")
    user = relationship("UserModel")
