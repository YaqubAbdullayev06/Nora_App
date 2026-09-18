"""Tests for habits CRUD and stats."""


class TestHabits:
    def test_create_habit(self, client, auth_headers):
        resp = client.post("/habits", json={
            "name": "Read 30 minutes",
            "category": "learning",
            "screen_time_minutes": 30,
            "target_per_day": 1,
        }, headers=auth_headers)
        assert resp.status_code in (200, 201)
        data = resp.json()
        assert data["success"] is True
        assert "habit_id" in data

    def test_list_habits(self, client, auth_headers):
        client.post("/habits", json={
            "name": "Exercise",
            "category": "health",
        }, headers=auth_headers)
        resp = client.get("/habits", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["success"] is True
        habits = data["habits"]
        assert len(habits) >= 1
        assert any(h["name"] == "Exercise" for h in habits)

    def test_complete_habit(self, client, auth_headers):
        create = client.post("/habits", json={
            "name": "Meditate",
            "category": "wellness",
        }, headers=auth_headers)
        habit_id = create.json()["habit_id"]
        resp = client.post("/habits/complete", json={
            "habit_id": habit_id,
            "duration_minutes": 10,
        }, headers=auth_headers)
        assert resp.status_code == 200

    def test_habit_stats(self, client, auth_headers):
        resp = client.get("/habits/stats", headers=auth_headers)
        assert resp.status_code == 200
        assert "total_habits" in resp.json()

    def test_habits_require_auth(self, client):
        resp = client.get("/habits")
        assert resp.status_code == 401
