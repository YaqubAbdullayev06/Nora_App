"""
Habits CRUD routes — create, list, complete, delete, stats.
"""

from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user
from models.orm import HabitCompletionModel, HabitModel, UserModel
from schemas import HabitCompleteRequest, HabitCreateRequest

router = APIRouter(prefix="/habits", tags=["habits"])


@router.post("")
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


@router.get("")
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
    # Batch-load all today's completions in ONE query (fixes N+1)
    today_counts = dict(
        db.query(HabitCompletionModel.habit_id, func.count(HabitCompletionModel.id))
        .filter(
            HabitCompletionModel.user_id == current_user.id,
            HabitCompletionModel.completed_at >= today_start,
        )
        .group_by(HabitCompletionModel.habit_id)
        .all()
    )
    result = []
    for habit in habits:
        result.append({
            "id": habit.id,
            "name": habit.name,
            "category": habit.category,
            "icon": habit.icon,
            "color": habit.color,
            "screen_time_minutes": habit.screen_time_minutes,
            "target_per_day": habit.target_per_day,
            "is_active": habit.is_active,
            "completions_today": today_counts.get(habit.id, 0),
            "created_at": habit.created_at,
        })
    return {"success": True, "habits": result}


@router.post("/complete")
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


@router.delete("/{habit_id}")
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


@router.get("/stats")
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
