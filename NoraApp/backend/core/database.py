"""
Database configuration — engine, session factory, dependency injection.
"""

import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./nora.db")
# SQLite needs check_same_thread; PostgreSQL/MySQL do not
_connect_args = {"check_same_thread": False} if "sqlite" in DATABASE_URL else {}

# Connection pool config — tuned for PostgreSQL on Render
_pool_kwargs = {}
if "sqlite" not in DATABASE_URL:
    _pool_kwargs = {
        "pool_size": 10,
        "max_overflow": 20,
        "pool_timeout": 30,
        "pool_recycle": 1800,
    }

engine = create_engine(
    DATABASE_URL,
    connect_args=_connect_args,
    pool_pre_ping=True,
    **_pool_kwargs,
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    """FastAPI dependency — yields a DB session and closes it after the request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
