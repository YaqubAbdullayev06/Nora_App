"""
Agent capability routes — focus scheduling, device settings, social media.
"""

from fastapi import APIRouter, Depends

from core.security import get_current_user
from models.orm import UserModel
from schemas import (
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
def get_agent_capabilities():
    return agent_capabilities.capabilities()


# ─── Focus ───


@router.get("/focus/status")
def get_agent_focus_status(current_user: UserModel = Depends(get_current_user)):
    return agent_capabilities.focus_status(current_user.id)


@router.post("/focus/schedule")
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


@router.post("/focus/start")
def start_agent_focus(
    request: FocusStartRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.start_focus(
        current_user.id,
        request.duration_minutes,
        request.label,
    )


@router.post("/focus/stop")
def stop_agent_focus(current_user: UserModel = Depends(get_current_user)):
    return agent_capabilities.stop_focus(current_user.id)


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
):
    return agent_capabilities.read_setting(current_user.id, setting)


@router.post("/device/settings")
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
):
    return agent_capabilities.start_oauth(
        current_user.id,
        request.platform,
        request.redirect_uri,
    )


@router.post("/social/connect")
def connect_agent_social_account(
    request: SocialConnectRequest,
    current_user: UserModel = Depends(get_current_user),
):
    return agent_capabilities.connect_account(
        current_user.id,
        request.platform,
        request.account_id,
    )


@router.post("/social/post")
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
