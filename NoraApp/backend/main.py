"""
Nora API — Application entry point.

This file is intentionally minimal. All models, schemas, routes, and
dependencies live under their own modules:

  core/        — database, JWT, password hashing
  models/      — SQLAlchemy ORM models
  schemas.py   — Pydantic request/response schemas
  routes/      — FastAPI routers (auth, habits, AI, agent, etc.)
  services/    — agent capabilities, app classifier
  ai/          — LLM providers, prompts, task decomposer
"""

from datetime import datetime

import os
import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

# ─── Load .env BEFORE importing AI modules (they read env vars at import time) ───
load_dotenv()

from core.database import Base, SessionLocal, engine
from routes import api_router

# ─── Seed Data ───

from models.orm import ContentModel


def seed_content(db):
    """Populate the content library if empty."""
    if db.query(ContentModel).count() == 0:
        contents = [
            ContentModel(
                title="Python Basics",
                description="Learn the fundamentals of Python programming",
                category="Programming",
                content_type="video",
                duration_minutes=5,
                points=50,
                tags="coding,python,beginner",
            ),
            ContentModel(
                title="Meditation Tips",
                description="5 techniques for better focus and clarity",
                category="Wellness",
                content_type="article",
                duration_minutes=3,
                points=30,
                tags="meditation,focus,wellness",
            ),
            ContentModel(
                title="Business Strategy",
                description="Essential strategies for startups",
                category="Business",
                content_type="video",
                duration_minutes=7,
                points=70,
                tags="business,startup,strategy",
            ),
            ContentModel(
                title="Language Learning",
                description="Effective methods to learn new languages",
                category="Education",
                content_type="flashcard",
                duration_minutes=4,
                points=40,
                tags="languages,learning,education",
            ),
            ContentModel(
                title="Financial Literacy",
                description="Understanding personal finance basics",
                category="Finance",
                content_type="article",
                duration_minutes=6,
                points=60,
                tags="finance,money,budgeting",
            ),
            ContentModel(
                title="Public Speaking",
                description="Tips for confident presentations",
                category="Skills",
                content_type="video",
                duration_minutes=8,
                points=80,
                tags="speaking,presentation,confidence",
            ),
        ]
        db.add_all(contents)
        db.commit()


# ─── App Setup ───

app = FastAPI(
    title="Nora API",
    description="AI-Powered Focus & Productivity App Backend",
    version="1.0.0",
)

# CORS: allow your Flutter app domains + localhost for dev.
# SECURITY: browsers reject `Access-Control-Allow-Origin: *` combined with
# credentials, and a wildcard + credentials would let any site make credentialed
# requests. Only enable credentials when explicit origins are configured.
CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "").split(",") if o.strip()]
_allow_credentials = bool(CORS_ORIGINS) and CORS_ORIGINS != ["*"]
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS or ["*"],
    allow_credentials=_allow_credentials,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ─── Mount all routes ───
app.include_router(api_router)


# ─── Root / Health ───


@app.get("/")
async def root():
    return {"message": "Nora API is running", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    from datetime import timezone

    now = datetime.now(timezone.utc).replace(tzinfo=None)
    return {"status": "healthy", "timestamp": now.isoformat()}


# ─── Startup ───


@app.on_event("startup")
def startup():
    Base.metadata.create_all(bind=engine)
    # ─── Migrations for existing databases ───
    db = SessionLocal()
    try:
        db.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS refresh_token_family VARCHAR(36)"
        ))
        db.commit()
    except Exception:
        pass  # Column already exists or dialect doesn't support IF NOT EXISTS
    try:
        db.execute(text(
            "ALTER TABLE accountability_locks DROP CONSTRAINT IF EXISTS accountability_locks_user_id_key"
        ))
        db.commit()
    except Exception:
        pass  # Constraint doesn't exist or dialect doesn't support DROP CONSTRAINT IF EXISTS
    try:
        db.execute(text("ALTER TABLE users ADD COLUMN age_group VARCHAR(20)"))
        db.commit()
    except Exception:
        pass  # Column already exists
    try:
        # H1: admin role for privileged writes (content creation)
        db.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE"))
        db.commit()
    except Exception:
        pass  # Column already exists
    seed_content(db)
    db.close()


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
