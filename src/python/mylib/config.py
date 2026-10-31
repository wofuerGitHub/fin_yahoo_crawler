"""Loading and validation for the FMP-compatible Yahoo configuration."""

from __future__ import annotations

import json
import os
import re
from pathlib import Path
from typing import Any


_ENV_PATTERN = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")
_IDENTIFIER_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _expand_environment(value: Any) -> Any:
    if isinstance(value, dict):
        return {key: _expand_environment(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_expand_environment(item) for item in value]
    if isinstance(value, str):
        def replace(match: re.Match[str]) -> str:
            name = match.group(1)
            if name not in os.environ:
                raise ValueError(f"Required environment variable {name} is not set")
            return os.environ[name]

        return _ENV_PATTERN.sub(replace, value)
    return value


def validate_identifier(value: str) -> str:
    if not isinstance(value, str) or not _IDENTIFIER_PATTERN.fullmatch(value):
        raise ValueError(f"Unsafe SQL identifier: {value!r}")
    return value


def load_config(path: str | Path = "config.json") -> dict[str, Any]:
    config_path = Path(path).expanduser().resolve()
    with config_path.open("r", encoding="utf-8") as source:
        document = _expand_environment(json.load(source))

    if not isinstance(document, dict) or not isinstance(document.get("yahoo"), dict):
        raise ValueError("Configuration must have a top-level 'yahoo' object")
    config = document["yahoo"]
    for section in ("database", "connection", "file", "control"):
        if not isinstance(config.get(section), dict):
            raise ValueError(f"Configuration section 'yahoo.{section}' is required")

    database = config["database"]
    for key in ("host", "port", "schema", "user", "password", "tables"):
        if key not in database:
            raise ValueError(f"Configuration value 'yahoo.database.{key}' is required")
    if not isinstance(database["tables"], dict):
        raise ValueError("'yahoo.database.tables' must be an object")
    for kind in ("income", "balance", "cashflow"):
        database["tables"].setdefault(f"{kind}_2", f"raw_fun_{kind}_2")
    for key, table in database["tables"].items():
        database["tables"][key] = validate_identifier(table)
    for key in ("reference_fx", "reference_map", "symbolslist", "companykeystats", "income", "cashflow", "balance", "fx", "quote", "quote_eps"):
        if key not in database["tables"]:
            raise ValueError(f"Table mapping 'yahoo.database.tables.{key}' is required")

    connection = config["connection"]
    connection.setdefault("speed", 10)
    connection.setdefault("timeout_seconds", 20)
    connection.setdefault("max_attempts", 3)
    connection.setdefault("cooldown_seconds_on_rate_limit", 300)
    if float(connection["speed"]) <= 0:
        raise ValueError("'yahoo.connection.speed' must be greater than zero")
    if int(connection["max_attempts"]) < 1:
        raise ValueError("'yahoo.connection.max_attempts' must be at least one")

    controls = config["control"]
    controls.setdefault("update_companykeystats_delay", 0.0)
    controls.setdefault("update_statement_delay", 0.0)
    controls.setdefault("update_statement_all", False)
    controls.setdefault("update_stream_delay", 3600.0)
    controls.setdefault("update_symbolslist_delay", 43200.0)
    controls.setdefault("update_timeserie_delay", 10800.0)
    controls.setdefault("history_overlap_days", 30)
    controls.setdefault("statement_frequency", "annual")
    if controls["statement_frequency"] != "annual":
        raise ValueError("Only annual statements are supported until destination keys are reviewed")

    config["debug"] = bool(config.get("debug", False))
    config["_config_dir"] = str(config_path.parent)
    return config


def resolve_path(config: dict[str, Any], value: str) -> Path:
    candidate = Path(value).expanduser()
    if not candidate.is_absolute():
        candidate = Path(config["_config_dir"]) / candidate
    return candidate.resolve()
