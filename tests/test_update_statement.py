import logging
from types import SimpleNamespace

import pandas as pd

import update_statement
from mylib.yahoo_service import FetchResult


class FakeDatabase:
    def __init__(self, profiles):
        self.profiles = profiles
        self.upserts = []

    def rows(self, name):
        if name == "reference_map":
            return [{"symbol": "ABC"}]
        return self.profiles

    def upsert(self, name, records):
        self.upserts.append((name, records))
        return len(records)


class FakeService:
    def __init__(self, info):
        self.info = info

    def statement(self, symbol, kind):
        return FetchResult("success", pd.DataFrame({pd.Timestamp("2024-12-31"): {"Total Revenue": 5}}))

    def profile(self, symbol):
        return FetchResult("success", self.info) if self.info else FetchResult("no_data")


def _run(monkeypatch, profiles, info):
    monkeypatch.setattr(update_statement, "fetch", lambda operation, *args: operation())
    database = FakeDatabase(profiles)
    config = {"control": {"update_statement_all": False}}
    update_statement.update(config, logging.getLogger("t"), None, FakeService(info), database, ["income"])
    return database.upserts


def test_reported_currency_falls_back_to_yahoo_financial_currency(monkeypatch):
    upserts = _run(monkeypatch, [], {"financialCurrency": "EUR", "currency": "USD"})

    assert upserts[0][1][0]["reportedCurrency"] == "EUR"


def test_profile_table_currency_is_preferred(monkeypatch):
    upserts = _run(monkeypatch, [{"symbol": "ABC", "reportedCurrency": "GBP"}], {"financialCurrency": "EUR"})

    assert upserts[0][1][0]["reportedCurrency"] == "GBP"


def test_statement_skipped_without_reported_currency(monkeypatch):
    assert _run(monkeypatch, [], {"currency": "USD"}) == []
