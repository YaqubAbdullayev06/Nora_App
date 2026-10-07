"""Regression tests for the Render/PostgreSQL boot crash.

Production failed with:

    psycopg2.errors.InFailedSqlTransaction: current transaction is aborted,
    commands ignored until end of transaction block
      main.py line 37, in seed_content   -> db.query(ContentModel).count()
      main.py line 160, in startup       -> seed_content(db)

Those line numbers identify the deployed commit as 8582f91, whose startup()
ran three ALTER TABLE statements inline with `except Exception: pass`. On
PostgreSQL any failed statement aborts the *whole transaction*, and a bare
`pass` leaves it aborted, so the very next statement (seed_content's SELECT)
raises InFailedSqlTransaction, startup dies, and Render crash-loops.

HEAD fixes this by (a) never issuing a statement that can fail
(`_add_column_if_missing` checks the inspector first) and (b) rolling back on
every failure path (`_run_migration`, `seed_content`). These tests pin that
behaviour so the rollback cannot be dropped silently again.
"""

from unittest.mock import MagicMock

import pytest
from sqlalchemy import text

import main
from main import _add_column_if_missing, _run_migration, seed_content


# ─── _run_migration ───


def test_run_migration_failure_rolls_back_and_does_not_raise():
    """A failed migration must roll back — `except: pass` is what poisoned
    production's transaction."""
    db = MagicMock()
    db.execute.side_effect = RuntimeError("duplicate column")

    _run_migration(db, "ALTER TABLE users ADD COLUMN age_group VARCHAR(20)")

    db.rollback.assert_called_once()
    db.commit.assert_not_called()


def test_run_migration_success_commits_without_rollback():
    db = MagicMock()

    _run_migration(db, "ALTER TABLE t DROP CONSTRAINT IF EXISTS c")

    db.commit.assert_called_once()
    db.rollback.assert_not_called()


# ─── seed_content ───


def test_seed_failure_is_swallowed_and_rolls_back():
    """seed_content must never propagate — and must not leave an aborted
    transaction behind for whatever runs next in startup()."""
    db = MagicMock()
    db.query.return_value.count.side_effect = RuntimeError(
        "current transaction is aborted"
    )

    seed_content(db)  # must not raise

    db.rollback.assert_called_once()
    db.add_all.assert_not_called()
    db.commit.assert_not_called()


def test_seed_inserts_when_empty():
    db = MagicMock()
    db.query.return_value.count.return_value = 0

    seed_content(db)

    db.add_all.assert_called_once()
    assert len(db.add_all.call_args[0][0]) == 6
    db.commit.assert_called_once()
    db.rollback.assert_not_called()


def test_seed_is_noop_when_content_exists():
    db = MagicMock()
    db.query.return_value.count.return_value = 42

    seed_content(db)

    db.add_all.assert_not_called()
    db.commit.assert_not_called()
    db.rollback.assert_not_called()


# ─── _add_column_if_missing ───


def test_add_column_skipped_when_present(monkeypatch):
    """Existing column must not generate any DDL (the unconditional
    `ADD COLUMN age_group` in the old code was the poison statement)."""
    inspector = MagicMock()
    inspector.get_columns.return_value = [{"name": "id"}, {"name": "age_group"}]
    monkeypatch.setattr(main, "inspect", lambda _engine: inspector)

    db = MagicMock()
    _add_column_if_missing(db, "users", "age_group", "VARCHAR(20)")

    db.execute.assert_not_called()
    db.commit.assert_not_called()


def test_add_column_issued_when_absent(monkeypatch):
    inspector = MagicMock()
    inspector.get_columns.return_value = [{"name": "id"}]
    monkeypatch.setattr(main, "inspect", lambda _engine: inspector)

    db = MagicMock()
    _add_column_if_missing(db, "users", "age_group", "VARCHAR(20)")

    db.execute.assert_called_once()
    sql = str(db.execute.call_args[0][0])
    assert "ADD COLUMN age_group" in sql
    db.commit.assert_called_once()


def test_add_column_failure_rolls_back(monkeypatch):
    inspector = MagicMock()
    inspector.get_columns.return_value = [{"name": "id"}]
    monkeypatch.setattr(main, "inspect", lambda _engine: inspector)

    db = MagicMock()
    db.execute.side_effect = RuntimeError("permission denied")

    _add_column_if_missing(db, "users", "age_group", "VARCHAR(20)")

    db.rollback.assert_called_once()


# ─── startup() end-to-end ───


def test_startup_survives_poisoned_seed(monkeypatch):
    """The exact production failure: seed_content's SELECT dies with
    InFailedSqlTransaction. Boot must not raise (Render crash-looped on
    this) and the transaction must be rolled back."""
    db = MagicMock()
    db.query.return_value.count.side_effect = RuntimeError(
        "current transaction is aborted, commands ignored"
    )
    monkeypatch.setattr(main, "SessionLocal", lambda: db)

    main.startup()  # must not raise

    assert db.rollback.called, "poisoned transaction was never rolled back"
    db.close.assert_called_once()


def test_startup_survives_failing_column_migration(monkeypatch):
    """Every ADD COLUMN fails (the old unconditional
    `ALTER TABLE users ADD COLUMN age_group` on an existing column) yet
    startup still reaches seed_content and finishes."""
    inspector = MagicMock()
    inspector.get_columns.return_value = [{"name": "id"}]  # all columns "missing"
    monkeypatch.setattr(main, "inspect", lambda _engine: inspector)

    db = MagicMock()
    db.execute.side_effect = RuntimeError(
        "current transaction is aborted, commands ignored"
    )
    db.query.return_value.count.return_value = 0
    monkeypatch.setattr(main, "SessionLocal", lambda: db)

    main.startup()  # must not raise

    assert db.rollback.call_count >= 1, "failed migrations were not rolled back"
    db.query.assert_called()  # seed_content still ran afterwards
    db.commit.assert_called()  # seeding committed on the recovered session
    db.close.assert_called_once()


# ─── dialect sanity: the helpers work against a real connection ───


def test_real_session_recovers_after_failed_statement():
    """On a real engine, a failing statement followed by the rollback the
    helpers perform leaves the session usable."""
    from core.database import SessionLocal

    db = SessionLocal()
    try:
        with pytest.raises(Exception):
            db.execute(text("ALTER TABLE no_such_table_xyz ADD COLUMN a INT"))
            db.flush()
        db.rollback()  # what _run_migration / seed_content do on failure

        # Session must still be usable afterwards.
        assert db.execute(text("SELECT 1")).scalar() == 1
    finally:
        db.close()
