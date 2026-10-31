import logging
import os
import uuid
from datetime import date
from decimal import Decimal

import pandas as pd
import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url

import update_statement_2 as worker
from mylib.yahoo_db import Database
from mylib.yahoo_service import FetchResult


def test_unpivots_every_metric_and_period_without_renaming():
    frame = pd.DataFrame({
        pd.Timestamp("2025-12-31"): [123, 0, -2.125, float("nan"), float("inf"), 1.123456],
        pd.Timestamp("2024-12-31"): [100, 42, -5, None, float("-inf"), 0.5],
    }, index=["TotalRevenue", "OperatingRevenue", "Unmapped Field_ABC", "Missing", "NonFinite", "BasicEPS"])

    records = worker.statement_records(frame, "ABC", "annual", "EUR")
    assert len(records) == frame.size
    rows = {(row["report_date"], row["metric"]): row for row in records}
    current = {metric: rows[(date(2025, 12, 31), metric)]["value"] for metric in frame.index}
    assert current == {
        "TotalRevenue": Decimal("123"), "OperatingRevenue": Decimal("0"),
        "Unmapped Field_ABC": Decimal("-2.125"), "Missing": None, "NonFinite": None,
        "BasicEPS": Decimal("1.123456"),
    }
    assert rows[(date(2024, 12, 31), "TotalRevenue")]["value"] == Decimal("100")
    assert all(row["symbol"] == "ABC" and row["period_type"] == "annual" and row["currency"] == "EUR"
               for row in records)


@pytest.mark.parametrize("frame", [None, pd.DataFrame()])
def test_empty_statement_has_no_rows(frame):
    assert worker.statement_records(frame, "ABC", "quarterly") == []


@pytest.mark.parametrize("metric,period_end", [("X" * 129, pd.Timestamp("2025-12-31")),
                                              ("Metric", pd.NaT), ("Metric", "not-a-date")])
def test_rejects_unstorable_labels_and_dates(metric, period_end):
    with pytest.raises(ValueError):
        worker.statement_records(pd.DataFrame({period_end: {metric: 1}}), "ABC", "annual")


class FakeDatabase:
    def __init__(self, profiles=(), missing_profiles=False):
        self.profiles = profiles
        self.missing_profiles = missing_profiles
        self.upserts = []
        self.reads = []

    def rows(self, name):
        self.reads.append(name)
        if name == "reference_map":
            return [{"symbol": "ABC", "symbol_fundamental": "FUND"},
                    {"symbol": "OTHER", "symbol_fundamental": "FUND"}]
        if name == "symbolslist":
            return [{"symbol": "ALL"}]
        if self.missing_profiles:
            raise RuntimeError("Profile table missing")
        return self.profiles

    def upsert(self, name, records):
        self.upserts.append((name, records))
        return len(records)


class FakeService:
    def __init__(self, info=None, results=None):
        self.info = info
        self.results = results or {}
        self.calls = []
        self.profile_calls = []

    def raw_statement(self, symbol, kind, period_type):
        self.calls.append((symbol, kind, period_type))
        result = self.results.get((kind, period_type))
        if isinstance(result, Exception):
            raise result
        return result or FetchResult("success", pd.DataFrame({pd.Timestamp("2025-12-31"): {"NewYahooMetric": 5}}))

    def profile(self, symbol):
        self.profile_calls.append(symbol)
        return FetchResult("success", self.info) if self.info else FetchResult("no_data")


def run_update(monkeypatch, database, service, args=(), update_all=False):
    monkeypatch.setattr(worker, "fetch", lambda operation, *unused: operation())
    worker.update({"control": {"update_statement_all": update_all}}, logging.getLogger("test"),
                  None, service, database, list(args))


def test_default_fetches_all_statements_and_both_periods_with_deduplicated_symbols(monkeypatch):
    database = FakeDatabase()
    service = FakeService({"financialCurrency": "EUR", "currency": "USD"})
    run_update(monkeypatch, database, service)

    assert set(service.calls) == {("FUND", kind, period) for kind in worker.TABLES for period in worker.PERIODS}
    assert len(service.calls) == len(database.upserts) == 6
    assert service.profile_calls == ["FUND"]
    assert {name for name, _ in database.upserts} == {"income_2", "balance_2", "cashflow_2"}
    assert all(rows[0]["metric"] == "NewYahooMetric" and rows[0]["currency"] == "EUR"
               for _, rows in database.upserts)


def test_can_limit_kind_and_period_and_prefer_existing_reporting_currency(monkeypatch):
    database = FakeDatabase([{"symbol": "FUND", "reportedCurrency": "GBP"}])
    service = FakeService({"financialCurrency": "EUR"})
    run_update(monkeypatch, database, service, ["income", "--period-type", "annual"])
    assert service.calls == [("FUND", "income", "annual")]
    assert service.profile_calls == []
    assert database.upserts[0][1][0]["currency"] == "GBP"


def test_missing_profile_table_or_currency_does_not_discard_metrics(monkeypatch):
    database = FakeDatabase(missing_profiles=True)
    service = FakeService({"currency": "USD"})
    run_update(monkeypatch, database, service, ["balance", "--period-type", "quarterly"], update_all=True)
    assert service.calls == [("ALL", "balance", "quarterly")]
    assert database.upserts[0][1][0]["currency"] is None
    assert "reference_map" not in database.reads


def test_failed_or_empty_statement_does_not_block_other_kinds_or_periods(monkeypatch):
    database = FakeDatabase()
    service = FakeService(results={
        ("income", "annual"): RuntimeError("provider unavailable"),
        ("balance", "quarterly"): FetchResult("no_data"),
        ("cashflow", "annual"): FetchResult("permanent_error"),
    })
    run_update(monkeypatch, database, service)
    assert len(service.calls) == 6
    assert {(name, rows[0]["period_type"]) for name, rows in database.upserts} == {
        ("income_2", "quarterly"), ("balance_2", "annual"), ("cashflow_2", "quarterly"),
    }


def test_cli_passes_common_and_statement_options_to_runner(monkeypatch):
    calls = []
    monkeypatch.setattr(worker, "run_worker", lambda *args: calls.append(args))
    worker.main(["cashflow", "--period-type", "quarterly", "--once", "--config", "local.json"])
    assert calls == [(worker.update, "update_statement_delay",
                      ["cashflow", "--period-type", "quarterly", "--config", "local.json", "--once"])]


def test_mysql_metric_tables_upsert_all_fields_and_keep_periods_distinct():
    test_url = os.environ.get("MYSQL_TEST_URL")
    if not test_url:
        pytest.skip("Set MYSQL_TEST_URL to enable the isolated MySQL integration test")
    url = make_url(test_url)
    if not url.database or not url.database.startswith("test_"):
        pytest.fail("MYSQL_TEST_URL must target a dedicated schema whose name begins with 'test_'")
    tables = {name: "crawler_metric_" + uuid.uuid4().hex[:12] for name in worker.TABLES.values()}
    engine = create_engine(url)
    created = []
    database = Database({"database": {
        "host": url.host, "port": url.port or 3306, "schema": url.database,
        "user": url.username, "password": url.password, "tables": tables,
    }})
    try:
        # Match the supplied _2 table schema; never run the dump's DROP statements.
        with engine.begin() as connection:
            for table in tables.values():
                connection.execute(text(f"""CREATE TABLE `{table}` (
                    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
                    symbol VARCHAR(32) NOT NULL,
                    period_type ENUM('annual','quarterly') NOT NULL,
                    report_date DATE NOT NULL,
                    metric VARCHAR(128) NOT NULL,
                    value DECIMAL(30,6) DEFAULT NULL,
                    currency VARCHAR(10) DEFAULT NULL,
                    fetched_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE KEY uq_metric (symbol, period_type, report_date, metric),
                    KEY idx_symbol_date (symbol, report_date)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci"""))
                created.append(table)
        frame = pd.DataFrame({pd.Timestamp("2025-12-31"): {
            "UnmappedMetric": 12.125, "NegativeMetric": -3, "ZeroMetric": 0, "AbsentMetric": None,
        }})
        for logical in tables:
            for period in worker.PERIODS:
                database.upsert(logical, worker.statement_records(frame, "ABC", period, "EUR"))
            with engine.begin() as connection:
                connection.execute(text(f"UPDATE `{tables[logical]}` SET fetched_at = '2000-01-01 00:00:00'"))
            revised = pd.DataFrame({pd.Timestamp("2025-12-31"): {
                "UnmappedMetric": None, "NegativeMetric": -5, "NewMetric": 9,
            }})
            database.upsert(logical, worker.statement_records(revised, "ABC", "annual"))
            rows = {(r["period_type"], r["metric"]): r for r in database.rows(logical)}
            assert len(rows) == 9  # four per period, plus the new annual metric
            assert rows[("annual", "UnmappedMetric")]["value"] == Decimal("12.125000")
            assert rows[("annual", "NegativeMetric")]["value"] == Decimal("-5.000000")
            assert rows[("quarterly", "NegativeMetric")]["value"] == Decimal("-3.000000")
            assert rows[("annual", "ZeroMetric")]["value"] == Decimal("0.000000")
            assert rows[("annual", "AbsentMetric")]["value"] is None
            assert rows[("annual", "UnmappedMetric")]["currency"] == "EUR"
            assert rows[("annual", "UnmappedMetric")]["fetched_at"].year > 2000
    finally:
        database.close()
        with engine.begin() as connection:
            for table in created:
                connection.execute(text(f"DROP TABLE `{table}`"))
        engine.dispose()
