"""Tests for auth routes: register, login, token refresh, logout."""


class TestRegister:
    def test_register_success(self, client):
        resp = client.post("/auth/register", json={
            "email": "new@example.com",
            "name": "New User",
            "password": "pass123",
        })
        assert resp.status_code in (200, 201)
        data = resp.json()
        assert "token" in data
        assert "refresh_token" in data
        assert data["user"]["email"] == "new@example.com"

    def test_register_duplicate_email(self, client, registered_user):
        resp = client.post("/auth/register", json={
            "email": "test@example.com",
            "name": "Duplicate",
            "password": "pass123",
        })
        assert resp.status_code == 400

    def test_register_missing_fields(self, client):
        resp = client.post("/auth/register", json={"email": "x@x.com"})
        assert resp.status_code in (400, 422)


class TestLogin:
    def test_login_success(self, client, registered_user):
        resp = client.post("/auth/login", json={
            "email": "test@example.com",
            "password": "securepass123",
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "token" in data
        assert "refresh_token" in data

    def test_login_wrong_password(self, client, registered_user):
        resp = client.post("/auth/login", json={
            "email": "test@example.com",
            "password": "wrongpassword",
        })
        assert resp.status_code == 401

    def test_login_nonexistent_user(self, client):
        resp = client.post("/auth/login", json={
            "email": "nobody@example.com",
            "password": "pass",
        })
        assert resp.status_code == 401


class TestTokenRefresh:
    def test_refresh_success(self, client, registered_user):
        refresh = registered_user["refresh_token"]
        resp = client.post("/auth/refresh", json={
            "refresh_token": refresh,
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "token" in data
        assert "refresh_token" in data
        # New refresh token should differ from old (rotation)
        assert data["refresh_token"] != refresh

    def test_refresh_rejects_access_token(self, client, registered_user):
        access = registered_user["token"]
        resp = client.post("/auth/refresh", json={
            "refresh_token": access,
        })
        assert resp.status_code == 401

    def test_refresh_rejects_reuse(self, client, registered_user):
        """Using an old refresh token after rotation should fail."""
        refresh = registered_user["refresh_token"]
        # First refresh — rotates the token
        client.post("/auth/refresh", json={"refresh_token": refresh})
        # Second refresh with the OLD token — should be rejected
        resp = client.post("/auth/refresh", json={"refresh_token": refresh})
        assert resp.status_code == 401


class TestAccessControl:
    def test_access_token_rejected_as_refresh(self, client, registered_user):
        """Access tokens must NOT work on refresh endpoint."""
        access = registered_user["token"]
        resp = client.post("/auth/refresh", json={"refresh_token": access})
        assert resp.status_code == 401

    def test_protected_route_requires_auth(self, client):
        resp = client.get("/auth/me")
        assert resp.status_code == 401

    def test_get_me_with_valid_token(self, client, auth_headers):
        resp = client.get("/auth/me", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json()["email"] == "test@example.com"
