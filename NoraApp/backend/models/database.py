from sqlalchemy import create_engine, Column, Integer, String, DateTime, Boolean, Float, ForeignKey, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship, sessionmaker
from datetime import datetime
import os

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./nora.db")

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    is_active = Column(Boolean, default=True)

    # Relationships
    sessions = relationship("FocusSession", back_populates="user")
    achievements = relationship("UserAchievement", back_populates="user")
    preferences = relationship("UserPreferences", back_populates="user", uselist=False)

class FocusSession(Base):
    __tablename__ = "focus_sessions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    duration_minutes = Column(Integer, nullable=False)
    completed = Column(Boolean, default=False)
    points_earned = Column(Integer, default=0)
    session_type = Column(String, default="pomodoro", index=True)  # pomodoro, deep_work, break
    started_at = Column(DateTime, default=datetime.now, index=True)
    ended_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)

    # Relationships
    user = relationship("User", back_populates="sessions")

class Content(Base):
    __tablename__ = "content"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String, nullable=False, index=True)
    content_type = Column(String, nullable=False, index=True)  # video, article, flashcard
    duration_minutes = Column(Integer, nullable=False)
    points = Column(Integer, default=0)
    url = Column(String, nullable=True)
    tags = Column(Text, nullable=True)  # JSON array of tags
    created_at = Column(DateTime, default=datetime.now)
    is_active = Column(Boolean, default=True)

class Achievement(Base):
    __tablename__ = "achievements"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    icon = Column(String, nullable=False)
    color = Column(String, nullable=False)
    requirement_type = Column(String, nullable=False)  # sessions, minutes, streak
    requirement_value = Column(Integer, nullable=False)
    points = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.now)

class UserAchievement(Base):
    __tablename__ = "user_achievements"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    achievement_id = Column(Integer, ForeignKey("achievements.id"), nullable=False, index=True)
    earned_at = Column(DateTime, default=datetime.now)

    # Relationships
    user = relationship("User", back_populates="achievements")
    achievement = relationship("Achievement")

class UserPreferences(Base):
    __tablename__ = "user_preferences"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, nullable=False)
    daily_goal_minutes = Column(Integer, default=60)
    pomodoro_duration = Column(Integer, default=25)
    break_duration = Column(Integer, default=5)
    long_break_duration = Column(Integer, default=15)
    notifications_enabled = Column(Boolean, default=True)
    theme = Column(String, default="dark")
    language = Column(String, default="en")

    # Relationships
    user = relationship("User", back_populates="preferences")

class AIRecommendation(Base):
    __tablename__ = "ai_recommendations"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    content_id = Column(Integer, ForeignKey("content.id"), nullable=False, index=True)
    reason = Column(Text, nullable=False)
    confidence_score = Column(Float, nullable=False)
    created_at = Column(DateTime, default=datetime.now)
    is_dismissed = Column(Boolean, default=False)

# Create tables
def init_db():
    Base.metadata.create_all(bind=engine)

# Get database session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()