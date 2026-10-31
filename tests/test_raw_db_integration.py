import os
import uuid

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

from mylib.yahoo_db import Database


def test_mysql_raw_upsert_and_preserve_existing_values():
    test_url = os.environ.get("MYSQL_TEST_URL")
    if not test_url:
        pytest.skip("Set MYSQL_TEST_URL to enable the isolated MySQL integration test")
    url = make_url(test_url)
    if not url.database or not url.database.startswith("test_"):
        pytest.fail("MYSQL_TEST_URL must target a dedicated schema whose name begins with 'test_'")

    table_name = "crawler_test_" + uuid.uuid4().hex[:12]
    setup_engine = create_engine(url)
    try:
        with setup_engine.begin() as connection:
            connection.execute(text(f"CREATE TABLE `{table_name}` (symbol VARCHAR(32) PRIMARY KEY, close DOUBLE NULL)"))
        config = {
            "database": {
                "host": url.host,
                "port": str(url.port or 3306),
                "schema": url.database,
                "user": url.username,
                "password": url.password,
                "tables": {"quote": table_name},
            }
        }
        database = Database(config)
        try:
            database.upsert("quote", [{"symbol": "FIXTURE", "close": 12.5}])
            database.upsert("quote", [{"symbol": "FIXTURE", "close": None}])
            rows = database.rows("quote")
            assert rows == [{"symbol": "FIXTURE", "close": 12.5}]
        finally:
            database.close()
    finally:
        with setup_engine.begin() as connection:
            connection.execute(text(f"DROP TABLE IF EXISTS `{table_name}`"))
        setup_engine.dispose()