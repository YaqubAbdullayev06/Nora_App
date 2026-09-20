"""
Central router — includes all feature routers into a single app.
"""

from fastapi import APIRouter

from routes.accountability import router as accountability_router
from routes.agent import router as agent_router
from routes.ai import router as ai_router
from routes.auth import router as auth_router
from routes.focus import router as focus_router
from routes.habits import router as habits_router
from routes.hardcap import router as hardcap_router

api_router = APIRouter()

api_router.include_router(auth_router)
api_router.include_router(accountability_router)
api_router.include_router(hardcap_router)
api_router.include_router(habits_router)
api_router.include_router(agent_router)
api_router.include_router(ai_router)
api_router.include_router(focus_router)
