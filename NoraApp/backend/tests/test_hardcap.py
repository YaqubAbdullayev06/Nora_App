"""Tests for daily hard cap routes (H9: today_usage_minutes wiring)."""


class TestHardCapSetup:
    def test_setup_creates_cap(self, client, auth_headers):
        resp = client.post("/hardcap/setup", json={
            "cap_minutes": 120,
            "soft_warning_percent": 80,
            "hard_warning_percent": 90,
            "require_pin_to_override": False,
        }, headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["cap"]["is_active"] is True
        assert data["cap"]["cap_minutes"] == 120
        # H9: usage must be an int (previously always None)
        assert data["cap"]["today_usage_minutes"] == 0

    def test_setup_updates_existing_cap(self, client, auth_headers):
        client.post("/hardcap/setup", json={"cap_minutes": 90}, headers=auth_headers)
        resp = client.post("/hardcap/setup", json={"cap_minutes": 150}, headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["cap"]["cap_minutes"] == 150

        status = client.get("/hardcap/status", headers=auth_headers).json()
        assert status["cap_minutes"] == 150
        assert status["is_active"] is True

    def test_setup_invalid_cap_minutes(self, client, auth_headers):
        resp = client.post("/hardcap/setup", json={"cap_minutes": 10}, headers=auth_headers)
        assert resp.status_code == 422

    def test_setup_requires_auth(self, client):
        resp = client.post("/hardcap/setup", json={"cap_minutes": 120})
        assert resp.status_code == 401


class TestHardCapStatus:
    def test_status_without_cap(self, client, auth_headers):
        resp = client.get("/hardcap/status", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_active"] is False
        assert data["cap_minutes"] is None
        # H9: usage is an int even with no cap
        assert data["today_usage_minutes"] == 0

    def test_status_with_cap(self, client, auth_headers):
        client.post("/hardcap/setup", json={"cap_minutes": 60}, headers=auth_headers)
        resp = client.get("/hardcap/status", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_active"] is True
        assert data["cap_minutes"] == 60
        assert isinstance(data["today_usage_minutes"], int)

    def test_status_requires_auth(self, client):
        resp = client.get("/hardcap/status")
        assert resp.status_code == 401


class TestHardCapDeactivate:
    def test_deactivate(self, client, auth_headers):
        client.post("/hardcap/setup", json={"cap_minutes": 120}, headers=auth_headers)
        resp = client.post("/hardcap/deactivate", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["deactivated"] is True

        status = client.get("/hardcap/status", headers=auth_headers).json()
        assert status["is_active"] is False

    def test_deactivate_without_cap(self, client, auth_headers):
        resp = client.post("/hardcap/deactivate", headers=auth_headers)
        assert resp.status_code == 404

    def test_deactivate_requires_auth(self, client):
        resp = client.post("/hardcap/deactivate")
        assert resp.status_code == 401
