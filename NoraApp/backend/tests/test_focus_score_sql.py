"""Regression tests for GET /focus-score SQL portability.

C1: the aggregate used `CAST(completed AS INTEGER)` over a Boolean column.
SQLite and MySQL accept that, PostgreSQL does not — so the endpoint 500'd
for every user in production while the (SQLite-backed) test suite stayed green.
These tests compile the statement against every dialect we support instead of
only executing it on SQLite.
"""

from sqlalchemy import select
from sqlalchemy.dialects import mysql, postgresql, sqlite

from models.orm import SessionModel
from routes.focus import focus_score_aggregates


def _compiled_sql(dialect) -> str:
    stmt = select(*focus_score_aggregates()).where(SessionModel.user_id == 1)
    return str(stmt.compile(dialect=dialect)).upper()


def test_no_boolean_to_integer_cast_on_postgres():
    sql = _compiled_sql(postgresql.dialect())
    assert "CAST(" not in sql, "PostgreSQL rejects CAST(boolean AS INTEGER)"
    assert "CASE WHEN" in sql


def test_aggregates_compile_on_every_supported_dialect():
    for dialect in (postgresql.dialect(), mysql.dialect(), sqlite.dialect()):
        sql = _compiled_sql(dialect)
        assert "CASE WHEN" in sql, f"missing portable CASE on {dialect.name}"
        assert "CAST(" not in sql, f"illegal boolean cast on {dialect.name}"


def test_completed_only_counts_when_true():
    """Both money/minute aggregates must be guarded by a CASE, not a cast.

    Bound literals render as `?`, so assert on the CASE structure itself.
    """
    sql = _compiled_sql(sqlite.dialect())
    assert sql.count("CASE WHEN") == 2
    assert sql.count("ELSE") == 2
