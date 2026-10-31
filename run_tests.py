import json
import os
import re
import shlex
import sys
from pathlib import Path

import pytest
from sqlalchemy.engine import URL, make_url


ROOT = Path(__file__).resolve().parent


def load_local_environment() -> None:
    env_file = ROOT / ".env"
    if not env_file.is_file():
        raise ValueError("Create a local .env file from .env.example before running tests")

    for line_number, line in enumerate(env_file.read_text().splitlines(), start=1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("export "):
            stripped = stripped[len("export ") :]
        name, separator, value = stripped.partition("=")
        if not separator or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            raise ValueError(f"Invalid .env assignment on line {line_number}")
        try:
            parts = shlex.split(value, comments=True)
        except ValueError as error:
            raise ValueError(f"Invalid .env value on line {line_number}") from error
        if len(parts) > 1:
            raise ValueError(f"Quote .env values containing whitespace (line {line_number})")
        os.environ.setdefault(name, parts[0] if parts else "")


def configure_test_database() -> None:
    test_url = os.environ.get("MYSQL_TEST_URL", "")
    if not test_url or "REPLACE_WITH_" in test_url:
        password = os.environ.get("MYSQL_PASSWORD", "")
        if not password or "REPLACE_WITH_" in password:
            raise ValueError("Set MYSQL_PASSWORD in .env before running the database integration test")

        config = json.loads((ROOT / "config.json").read_text())
        database = config["yahoo"]["database"]
        schema = os.environ.get("MYSQL_TEST_SCHEMA", "test_yahoo")
        test_url = URL.create(
            "mysql+mysqlconnector",
            username=database["user"],
            password=password,
            host=database["host"],
            port=int(database["port"]),
            database=schema,
        ).render_as_string(hide_password=False)

    url = make_url(test_url)
    if not url.database or not url.database.startswith("test_"):
        raise ValueError("MYSQL_TEST_URL must target a dedicated schema whose name begins with 'test_'")
    os.environ["MYSQL_TEST_URL"] = test_url


def main() -> int:
    try:
        load_local_environment()
        configure_test_database()
    except (OSError, KeyError, TypeError, ValueError) as error:
        print(f"Test setup failed: {error}", file=sys.stderr)
        return 2

    return int(pytest.main(sys.argv[1:]))


if __name__ == "__main__":
    raise SystemExit(main())
