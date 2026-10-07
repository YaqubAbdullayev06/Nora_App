"""Startup / health diagnostics for Render deploys.

Background: three consecutive deploys (6375109, bfbfa5e, 46f8745) were marked
Failed while Render kept serving the previous build — so the Logs tab kept
streaming the OLD build's traceback and the real reason was only reachable
inside each failed deploy. `create_all` was also the one statement in
`startup()` that was not wrapped, i.e. the last thing that could still kill
the boot.

These tests pin the two fixes:
  * startup() survives a failing `create_all` (boot never dies silently),
  * /health reports which commit is live and whether the DB is reachable,
    always as HTTP 200 so it cannot fail a health check itself.
"""

from unittest.mock import MagicMock

import main


def test_startup_survives_create_all_failure(monkeypatch):
    """create_all was the ONLY unwrapped statement in startup(); if it
    raises, Render marks the deploy Failed and keeps serving the old build,
    which hides the real error behind that build's logs."""
    db = MagicMock()
    db.query.return_value.count.return_value = 3
    monkeypatch.setattr(main, "SessionLocal", lambda: db)

    def _boom(**_kwargs):
        raise RuntimeError("permission denied for schema public")

    monkeypatch.setattr(main.Base.metadata, "create_all", _boom)

    main.startup()  # must not raise

    db.close.assert_called_once()


def test_health_reports_live_commit_and_db_ok(client, monkeypatch):
    monkeypatch.setenv("RENDER_GIT_COMMIT", "abc1234")

    resp = client.get("/health")

    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "healthy"
    assert data["commit"] == "abc1234"
    assert data["db"] == "ok"


def test_health_commit_falls_back_to_unknown(client, monkeypatch):
    monkeypatch.delenv("RENDER_GIT_COMMIT", raising=False)

    data = client.get("/health").json()

    assert data["commit"] == "unknown"


def test_health_still_returns_200_when_db_is_broken(client, monkeypatch):
    """A non-2xx /health would itself fail Render's health check, so the DB
    error has to travel in the body instead."""

    class BrokenEngine:
        def connect(self):
            raise RuntimeError("connection refused")

    monkeypatch.setattr(main, "engine", BrokenEngine())

    resp = client.get("/health")

    assert resp.status_code == 200
    assert resp.json()["db"].startswith("RuntimeError:")
