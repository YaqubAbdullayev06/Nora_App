"""Tests for focus sessions and focus score."""


class TestSessions:
    def test_create_session(self, client, auth_headers):
        resp = client.post("/sessions/", json={
            "duration_minutes": 25,
            "session_type": "pomodoro",
            "notes": "Test session",
        }, headers=auth_headers)
        assert resp.status_code == 201
        data = resp.json()
        assert data["duration_minutes"] == 25
        assert data["completed"] is False

    def test_create_session_requires_auth(self, client):
        resp = client.post("/sessions/", json={
            "duration_minutes": 25,
            "session_type": "pomodoro",
        })
        assert resp.status_code == 401

    def test_list_sessions(self, client, auth_headers):
        # Create a session first
        client.post("/sessions/", json={
            "duration_minutes": 25,
            "session_type": "pomodoro",
        }, headers=auth_headers)
        resp = client.get("/sessions/", headers=auth_headers)
        assert resp.status_code == 200
        sessions = resp.json()
        assert len(sessions) >= 1

    def test_complete_session(self, client, auth_headers):
        create = client.post("/sessions/", json={
            "duration_minutes": 25,
            "session_type": "pomodoro",
        }, headers=auth_headers)
        session_id = create.json()["id"]
        resp = client.put(f"/sessions/{session_id}/complete", headers=auth_headers)
        assert resp.status_code == 200
        assert "points_earned" in resp.json()

    def test_user_isolation(self, client, auth_headers):
        """User A's sessions should not appear in User B's list."""
        # Create session as user A
        client.post("/sessions/", json={
            "duration_minutes": 25,
            "session_type": "pomodoro",
        }, headers=auth_headers)

        # Register user B
        reg = client.post("/auth/register", json={
            "email": "other@example.com",
            "name": "Other",
            "password": "pass123",
        })
        headers_b = {"Authorization": f"Bearer {reg.json()['token']}"}

        # User B should see no sessions
        resp = client.get("/sessions/", headers=headers_b)
        assert resp.status_code == 200
        assert len(resp.json()) == 0


class TestFocusScore:
    def test_focus_score_empty(self, client, auth_headers):
        resp = client.get("/focus-score/", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["total_points"] == 0
        assert data["sessions_completed"] == 0

    def test_focus_score_after_session(self, client, auth_headers):
        # Create and complete a session
        create = client.post("/sessions/", json={
            "duration_minutes": 25,
            "session_type": "pomodoro",
        }, headers=auth_headers)
        session_id = create.json()["id"]
        client.put(f"/sessions/{session_id}/complete", headers=auth_headers)

        resp = client.get("/focus-score/", headers=auth_headers)
        data = resp.json()
        assert data["sessions_completed"] == 1
        assert data["total_focus_minutes"] == 25
        assert data["total_points"] > 0
