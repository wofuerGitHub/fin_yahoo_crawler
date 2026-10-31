import json

import pytest

from mylib.config import load_config, validate_identifier


def _document(password="${MYSQL_PASSWORD}"):
    names = ("reference_fx", "reference_map", "symbolslist", "companykeystats", "income", "cashflow", "balance", "fx", "quote", "quote_eps")
    return {"yahoo": {
        "database": {"host": "localhost", "port": "3306", "schema": "fmp", "user": "crawler", "password": password, "tables": {name: name for name in names}},
        "connection": {"speed": 10}, "file": {"log": "run.log", "debug": "debug.log", "speed_control": "speed.json"},
        "control": {}, "debug": False,
    }}


def test_loads_fmp_style_config_and_expands_secret(tmp_path, monkeypatch):
    monkeypatch.setenv("MYSQL_PASSWORD", "fixture-secret")
    path = tmp_path / "config.json"
    path.write_text(json.dumps(_document()), encoding="utf-8")

    config = load_config(path)

    assert config["database"]["password"] == "fixture-secret"
    assert config["control"]["history_overlap_days"] == 30
    assert config["control"]["statement_frequency"] == "annual"


def test_missing_secret_fails_closed(tmp_path, monkeypatch):
    monkeypatch.delenv("MYSQL_PASSWORD", raising=False)
    path = tmp_path / "config.json"
    path.write_text(json.dumps(_document()), encoding="utf-8")

    with pytest.raises(ValueError, match="MYSQL_PASSWORD"):
        load_config(path)


def test_identifier_rejects_sql_fragments():
    with pytest.raises(ValueError, match="Unsafe SQL identifier"):
        validate_identifier("quotes; DROP TABLE quotes")