"""Tests for AI auth + per-user rate limiting (C4 / require_ai_user)."""

from collections import deque

import pytest
from fastapi import HTTPException

from routes.ai import (
    _RATE_LIMIT_MAX_REQUESTS,
    _RATE_LIMIT_WINDOW_SECONDS,
    _rate_limit_buckets,
    require_ai_user,
)


class TestAIAuth:
    def test_chat_requires_auth(self, client):
        resp = client.post("/ai/chat", json={
            "message": "hello",
            "age_group": "adult",
        })
        assert resp.status_code == 401

    def test_classify_requires_auth(self, client):
        resp = client.post("/ai/classify-apps", json={
            "apps": ["com.instagram.android"],
            "age_group": "adult",
        })
        assert resp.status_code == 401

    def test_health_is_public(self, client):
        resp = client.get("/ai/health")
        assert resp.status_code == 200
        data = resp.json()
        assert "providers" in data
        assert "llm_available" in data


class TestAIRateLimit:
    def test_allows_up_to_limit(self):
        user_id = 999001
        _rate_limit_buckets.pop(user_id, None)
        user = type("U", (), {"id": user_id})()

        for _ in range(_RATE_LIMIT_MAX_REQUESTS):
            result = require_ai_user(current_user=user)
            assert result is user

        _rate_limit_buckets.pop(user_id, None)

    def test_blocks_over_limit(self):
        user_id = 999002
        _rate_limit_buckets.pop(user_id, None)
        user = type("U", (), {"id": user_id})()

        for _ in range(_RATE_LIMIT_MAX_REQUESTS):
            require_ai_user(current_user=user)

        with pytest.raises(HTTPException) as exc:
            require_ai_user(current_user=user)
        assert exc.value.status_code == 429

        _rate_limit_buckets.pop(user_id, None)

    def test_buckets_are_per_user(self):
        user_a_id, user_b_id = 999003, 999004
        _rate_limit_buckets.pop(user_a_id, None)
        _rate_limit_buckets.pop(user_b_id, None)
        user_a = type("U", (), {"id": user_a_id})()
        user_b = type("U", (), {"id": user_b_id})()

        # Exhaust user A's budget
        for _ in range(_RATE_LIMIT_MAX_REQUESTS):
            require_ai_user(current_user=user_a)

        with pytest.raises(HTTPException):
            require_ai_user(current_user=user_a)

        # User B is unaffected
        assert require_ai_user(current_user=user_b) is user_b

        _rate_limit_buckets.pop(user_a_id, None)
        _rate_limit_buckets.pop(user_b_id, None)

    def test_window_slides(self, monkeypatch):
        """Entries older than the window are evicted, allowing new requests."""
        user_id = 999005
        _rate_limit_buckets.pop(user_id, None)
        user = type("U", (), {"id": user_id})()

        for _ in range(_RATE_LIMIT_MAX_REQUESTS):
            require_ai_user(current_user=user)

        with pytest.raises(HTTPException):
            require_ai_user(current_user=user)

        # Simulate the window elapsing by rewinding all timestamps
        bucket = _rate_limit_buckets[user_id]
        _rate_limit_buckets[user_id] = deque(
            t - _RATE_LIMIT_WINDOW_SECONDS - 1 for t in bucket
        )

        # Now the limit should allow a new request again
        assert require_ai_user(current_user=user) is user

        _rate_limit_buckets.pop(user_id, None)
