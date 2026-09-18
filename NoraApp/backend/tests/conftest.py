import os
import sys

# Set test environment BEFORE importing main
os.environ["SECRET_KEY"] = "test-secret-key-not-for-production"
os.environ["DATABASE_URL"] = "sqlite:///./test_nora.db"

# Add parent dir so `from main import app` works
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import pytest
from fastapi.testclient import TestClient
from main import app, Base, engine, SessionLocal

@pytest.fixture(autouse=True)
def setup_db():
    """Create fresh tables for each test, drop after."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)

@pytest.fixture
def client():
    return TestClient(app)

@pytest.fixture
def registered_user(client):
    """Register a user and return the auth data."""
    resp = client.post("/auth/register", json={
        "email": "test@example.com",
        "name": "Test User",
        "password": "securepass123",
    })
    assert resp.status_code in (200, 201)
    return resp.json()

@pytest.fixture
def auth_headers(registered_user):
    """Return Authorization headers for an authenticated request."""
    token = registered_user["token"]
    return {"Authorization": f"Bearer {token}"}
