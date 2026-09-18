"""Tests for health check and basic routes."""


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"


def test_root(client):
    resp = client.get("/")
    assert resp.status_code == 200
