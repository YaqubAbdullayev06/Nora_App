"""
Focus session & content routes — CRUD for focus sessions, content, focus score, recommendations.
"""

from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, Integer, cast
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user
from models.orm import ContentModel, SessionModel, UserModel
from schemas import (
    ContentCreate,
    ContentResponse,
    FocusScoreResponse,
    SessionCreate,
    SessionResponse,
    UserResponse,
)

router = APIRouter(tags=["focus"])


# ─── Users ───


@router.get("/users/{user_id}", response_model=UserResponse)
def get_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
    if current_user.id != user_id:
        raise HTTPException(status_code=403, detail="Not authorized to view this user")
    user = db.query(UserModel).filter(UserModel.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return UserResponse.model_validate(user)


# ─── Focus Sessions ───


@router.post("/sessions/", response_model=SessionResponse, status_code=201)
def create_session(
    session: SessionCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
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
    return SessionResponse.model_validate(new_session)


@router.get("/sessions/", response_model=List[SessionResponse])
def get_user_sessions(
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
    sessions = (
        db.query(SessionModel)
        .filter(SessionModel.user_id == current_user.id)
        .order_by(SessionModel.started_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )
    return [SessionResponse.model_validate(s) for s in sessions]


@router.put("/sessions/{session_id}/complete")
def complete_session(
    session_id: int,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
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


@router.get("/content/", response_model=List[ContentResponse])
def get_content(category: Optional[str] = None, db: Session = Depends(get_db)):
    query = db.query(ContentModel).filter(ContentModel.is_active == True)
    if category:
        query = query.filter(ContentModel.category == category)
    return [ContentResponse.model_validate(c) for c in query.all()]


@router.post("/content/", response_model=ContentResponse, status_code=201)
def create_content(
    content: ContentCreate,
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
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
    return ContentResponse.model_validate(new_content)


# ─── Focus Score ───


@router.get("/focus-score/", response_model=FocusScoreResponse)
def get_focus_score(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
    """Get focus score using SQL aggregation (no full table load)."""
    result = db.query(
        func.coalesce(func.sum(SessionModel.points_earned), 0).label("total_points"),
        func.coalesce(
            func.sum(
                cast(SessionModel.completed, Integer) * SessionModel.duration_minutes
            ),
            0,
        ).label("total_minutes"),
        func.count(SessionModel.id).label("total_sessions"),
        func.coalesce(
            func.sum(cast(SessionModel.completed, Integer)), 0
        ).label("completed_count"),
    ).filter(SessionModel.user_id == current_user.id).first()

    total_points = result.total_points
    total_minutes = result.total_minutes
    completed_count = result.completed_count

    return FocusScoreResponse(
        user_id=current_user.id,
        total_points=total_points,
        total_focus_minutes=total_minutes,
        average_session_length=total_minutes / completed_count if completed_count > 0 else 0,
        sessions_completed=completed_count,
    )


# ─── Recommendations ───


@router.get("/recommendations/")
def get_recommendations(
    db: Session = Depends(get_db),
    current_user: UserModel = Depends(get_current_user),
):
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
