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
from sqlalchemy import inspect, text

# ─── Load .env BEFORE importing AI modules (they read env vars at import time) ───
load_dotenv()

from core.database import Base, SessionLocal, engine
from routes import api_router

# ─── Seed Data ───

from models.orm import ContentModel


def seed_content(db):
    """Populate the content library if empty.

    Never lets a seeding failure abort application startup: a poisoned
    transaction here previously crashed boot with InFailedSqlTransaction.
    """
    try:
        _seed_content_inner(db)
    except Exception as exc:
        db.rollback()
        print(f"[startup] seed_content skipped: {exc}")


def _seed_content_inner(db):
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
    allow_origins=CORS_ORIGINS if CORS_ORIGINS else ["*"],
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
    # RENDER_GIT_COMMIT is set by Render for every deploy: knowing which
    # commit is actually live ends the "is prod running my fix?" guessing.
    # `db` is a real SELECT so a broken database shows up here instead of as
    # an opaque deploy failure. Always HTTP 200: a non-2xx would itself fail
    # Render's health check and hide the reason.
    return {
        "status": "healthy",
        "timestamp": now.isoformat(),
        "commit": os.environ.get("RENDER_GIT_COMMIT") or "unknown",
        "db": _probe_db(),
    }


def _first_line(exc: Exception, limit: int = 300) -> str:
    """One usable line from an exception (SQLAlchemy messages are multiline)."""
    return ((str(exc).splitlines() or [""])[0])[:limit]


def _probe_db() -> str:
    """Live connectivity check: 'ok' or '<ExceptionType>: <message>'."""
    try:
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        return "ok"
    except Exception as exc:
        return f"{exc.__class__.__name__}: {_first_line(exc)}"


# ─── Startup ───


def _run_migration(db, sql: str) -> None:
    """Run one migration statement in its own transaction.

    On failure we MUST rollback: PostgreSQL aborts the whole transaction on
    error, and leaving it open made every later statement (including
    seed_content's count) fail with InFailedSqlTransaction, crashing startup.
    """
    try:
        db.execute(text(sql))
        db.commit()
    except Exception as exc:
        db.rollback()
        print(f"[startup] migration skipped ({exc.__class__.__name__}): {sql}")


def _add_column_if_missing(db, table: str, column: str, ddl: str) -> None:
    """Dialect-portable ADD COLUMN (works on PostgreSQL and SQLite).

    Uses the inspector instead of `ADD COLUMN IF NOT EXISTS` (Postgres-only),
    so no statement ever fails and the transaction is never aborted.
    """
    try:
        existing = {c["name"] for c in inspect(engine).get_columns(table)}
        if column not in existing:
            db.execute(text(f"ALTER TABLE {table} ADD COLUMN {column} {ddl}"))
            db.commit()
    except Exception as exc:
        db.rollback()
        print(f"[startup] column add skipped ({exc.__class__.__name__}): {table}.{column}")


@app.on_event("startup")
def startup():
    # create_all creates missing tables (incl. agent_state); it does NOT
    # alter existing tables, so existing-database columns are added below.
    #
    # Schema work must never kill the boot: when startup raises, Render marks
    # the deploy Failed and keeps serving the PREVIOUS build — so the real
    # error is only visible inside the failed deploy's own logs, while the
    # Logs tab keeps streaming the old build's output. Log it, keep going,
    # and let /health's `db` field report the state.
    try:
        Base.metadata.create_all(bind=engine)
    except Exception as exc:
        print(f"[startup] create_all failed ({exc.__class__.__name__}): {_first_line(exc)}")
    db = SessionLocal()
    try:
        _add_column_if_missing(db, "users", "refresh_token_family", "VARCHAR(36)")
        _add_column_if_missing(db, "users", "age_group", "VARCHAR(20)")
        # H1: admin role for privileged writes (content creation)
        _add_column_if_missing(db, "users", "is_admin", "BOOLEAN NOT NULL DEFAULT FALSE")
        # M28: content cover image
        _add_column_if_missing(db, "content", "image_url", "VARCHAR(500)")
        if engine.dialect.name == "postgresql":
            # PostgreSQL-only syntax; drop unique constraint on user_id
            _run_migration(
                db,
                "ALTER TABLE accountability_locks DROP CONSTRAINT IF EXISTS accountability_locks_user_id_key",
            )
        seed_content(db)
    finally:
        db.close()
    print(f"[startup] ready commit={os.environ.get('RENDER_GIT_COMMIT') or 'unknown'}")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
