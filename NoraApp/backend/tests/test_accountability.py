"""Tests for accountability lock routes (PIN setup, verify, unlink)."""


class TestAccountabilitySetup:
    def test_setup_lock(self, client, auth_headers):
        resp = client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        assert data["lock"]["is_active"] is True
        assert data["lock"]["guardian_name"] == "Parent"

    def test_setup_invalid_pin(self, client, auth_headers):
        resp = client.post("/accountability/setup", json={
            "pin": "12",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        assert resp.status_code == 422

    def test_replace_active_lock_requires_current_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/setup", json={
            "pin": "5678",
            "guardian_name": "Guardian",
        }, headers=auth_headers)
        assert resp.status_code == 400

    def test_replace_active_lock_wrong_current_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/setup", json={
            "pin": "5678",
            "guardian_name": "Guardian",
            "current_pin": "0000",
        }, headers=auth_headers)
        assert resp.status_code == 401

    def test_replace_active_lock_with_current_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/setup", json={
            "pin": "5678",
            "guardian_name": "Guardian",
            "current_pin": "1234",
        }, headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["lock"]["guardian_name"] == "Guardian"

        # New PIN works
        verify = client.post("/accountability/verify", json={"pin": "5678"}, headers=auth_headers)
        assert verify.status_code == 200

    def test_setup_requires_auth(self, client):
        resp = client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        })
        assert resp.status_code == 401


class TestAccountabilityVerify:
    def test_verify_correct_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/verify", json={"pin": "1234"}, headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["verified"] is True

    def test_verify_wrong_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/verify", json={"pin": "9999"}, headers=auth_headers)
        assert resp.status_code == 401

    def test_verify_without_lock(self, client, auth_headers):
        resp = client.post("/accountability/verify", json={"pin": "1234"}, headers=auth_headers)
        assert resp.status_code == 404

    def test_verify_requires_auth(self, client):
        resp = client.post("/accountability/verify", json={"pin": "1234"})
        assert resp.status_code == 401


class TestAccountabilityStatus:
    def test_status_without_lock(self, client, auth_headers):
        resp = client.get("/accountability/status", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["is_active"] is False

    def test_status_with_lock(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.get("/accountability/status", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["is_active"] is True
        assert data["guardian_name"] == "Parent"
        assert data["is_expired"] is False

    def test_status_requires_auth(self, client):
        resp = client.get("/accountability/status")
        assert resp.status_code == 401


class TestAccountabilityUnlink:
    def test_unlink_correct_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/unlink", json={"pin": "1234"}, headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["unlinked"] is True

        status = client.get("/accountability/status", headers=auth_headers).json()
        assert status["is_active"] is False

    def test_unlink_wrong_pin(self, client, auth_headers):
        client.post("/accountability/setup", json={
            "pin": "1234",
            "guardian_name": "Parent",
        }, headers=auth_headers)
        resp = client.post("/accountability/unlink", json={"pin": "9999"}, headers=auth_headers)
        assert resp.status_code == 401

        # Lock still active
        status = client.get("/accountability/status", headers=auth_headers).json()
        assert status["is_active"] is True

    def test_unlink_without_lock(self, client, auth_headers):
        resp = client.post("/accountability/unlink", json={"pin": "1234"}, headers=auth_headers)
        assert resp.status_code == 404

    def test_unlink_requires_auth(self, client):
        resp = client.post("/accountability/unlink", json={"pin": "1234"})
        assert resp.status_code == 401
