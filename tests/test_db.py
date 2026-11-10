"""Smoke-Test der Datenbank. Wird übersprungen, wenn keine DB erreichbar ist (z. B. in CI)."""

import pytest
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from negative_strompreise.db import get_engine

EXPECTED_SCHEMAS = {"raw", "staging", "mart"}


@pytest.fixture(scope="module")
def engine():
    try:
        eng = get_engine(connect_args={"connect_timeout": 3})
        with eng.connect() as conn:
            conn.execute(text("SELECT 1"))
    except (KeyError, OperationalError) as exc:
        pytest.skip(f"Datenbank nicht erreichbar: {exc!r}")
    yield eng
    eng.dispose()


def test_schemas_exist(engine):
    with engine.connect() as conn:
        rows = conn.execute(text("SELECT schema_name FROM information_schema.schemata")).scalars()
        assert EXPECTED_SCHEMAS <= set(rows)


def test_raw_table_exists(engine):
    with engine.connect() as conn:
        assert conn.execute(text("SELECT to_regclass('raw.smard_observation')")).scalar()
