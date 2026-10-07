"""
Agent capability routes — focus scheduling, device settings, social media.
"""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from core.database import get_db
from core.security import get_current_user
from models.orm import UserModel
from schemas import (
    DeviceSettingProposeRequest,
    DeviceSettingUpdateRequest,
    FocusScheduleRequest,
    FocusStartRequest,
    SocialConnectRequest,
    SocialOAuthRequest,
    SocialPostRequest,
)
from services.agent_capabilities import agent_capabilities

router = APIRouter(prefix="/agent", tags=["agent"])


@router.get("/capabilities")
def get_agent_capabilities(current_user: UserModel = Depends(get_current_user)):
    # H13: capabilities probe previously required no auth
    return agent_capabilities.capabilities()


# ─── Focus ───


@router.get("/focus/status")
def get_agent_focus_status(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.focus_status(current_user.id, db=db)


@router.post("/focus/schedule")
def schedule_agent_focus(
    request: FocusScheduleRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.schedule_focus(
        current_user.id,
        request.start_time,
        request.duration_minutes,
        request.label,
        request.tz_offset_minutes,
        db=db,
    )


@router.post("/focus/start")
def start_agent_focus(
    request: FocusStartRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.start_focus(
        current_user.id,
        request.duration_minutes,
        request.label,
        db=db,
    )


@router.post("/focus/stop")
def stop_agent_focus(
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.stop_focus(current_user.id, db=db)


# ─── Device Settings ───


@router.get("/device/settings")
def list_agent_device_settings(current_user: UserModel = Depends(get_current_user)):
    return {
        "success": True,
        "settings": sorted(agent_capabilities.device_settings),
    }


@router.get("/device/settings/{setting}")
def read_agent_device_setting(
    setting: str,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.read_setting(current_user.id, setting, db=db)


@router.post("/device/settings/propose")
def propose_agent_device_setting(
    request: DeviceSettingProposeRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """M11: step 1 — validate a change and issue a short-lived approval token."""
    return agent_capabilities.propose_setting(
        current_user.id,
        request.setting,
        request.value,
        db=db,
    )


@router.post("/device/settings")
def update_agent_device_setting(
    request: DeviceSettingUpdateRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """M11: step 2 — apply only with the server-issued approval token."""
    return agent_capabilities.update_setting(
        current_user.id,
        request.setting,
        request.value,
        request.approval_token,
        db=db,
    )


# ─── Social Media ───


@router.get("/social/platforms")
def list_agent_social_platforms(current_user: UserModel = Depends(get_current_user)):
    return {
        "success": True,
        "platforms": sorted(agent_capabilities.social_platforms),
    }


@router.post("/social/oauth/start")
def start_agent_social_oauth(
    request: SocialOAuthRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.start_oauth(
        current_user.id,
        request.platform,
        request.redirect_uri,
        db=db,
    )


@router.post("/social/connect")
def connect_agent_social_account(
    request: SocialConnectRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.connect_account(
        current_user.id,
        request.platform,
        request.account_id,
        request.state,
        db=db,
    )


@router.post("/social/post")
def post_agent_social_content(
    request: SocialPostRequest,
    current_user: UserModel = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return agent_capabilities.post_content(
        current_user.id,
        request.platform,
        request.account_id,
        request.text,
        db=db,
    )
