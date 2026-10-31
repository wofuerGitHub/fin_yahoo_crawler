import os
from pprint import pprint

import pandas as pd
import pytest

from mylib.yahoo_service import YahooService


def test_history_requests_unadjusted_daily_data(monkeypatch):
    observed = {}

    class FakeTicker:
        def history(self, **kwargs):
            observed.update(kwargs)
            return pd.DataFrame({"Close": [10.0]})

    monkeypatch.setattr("mylib.yahoo_service.yf.Ticker", lambda symbol: FakeTicker())
    result = YahooService(timeout_seconds=7).history("ABC")

    assert result.status == "success"
    assert observed["period"] == "max"
    assert observed["auto_adjust"] is False
    assert observed["timeout"] == 7


def test_empty_provider_result_is_not_success(monkeypatch):
    class FakeTicker:
        def history(self, **kwargs):
            return pd.DataFrame()

    monkeypatch.setattr("mylib.yahoo_service.yf.Ticker", lambda symbol: FakeTicker())

    assert YahooService().history("MISSING").status == "no_data"


@pytest.mark.parametrize("kind,method", [("income", "get_income_stmt"),
                                        ("balance", "get_balance_sheet"), ("cashflow", "get_cash_flow")])
@pytest.mark.parametrize("period_type,freq", [("annual", "yearly"), ("quarterly", "quarterly")])
def test_raw_statements_request_original_names_and_selected_period(monkeypatch, kind, method, period_type, freq):
    observed = {}
    frame = pd.DataFrame({pd.Timestamp("2025-12-31"): {"TotalRevenue": 5}})

    def statement(**kwargs):
        observed.update(kwargs)
        return frame

    ticker = type("FakeTicker", (), {})()
    setattr(ticker, method, statement)
    monkeypatch.setattr("mylib.yahoo_service.yf.Ticker", lambda symbol: ticker)

    result = YahooService().raw_statement("ABC", kind, period_type)
    assert result.status == "success"
    assert result.data is frame
    assert observed == {"freq": freq, "pretty": False}


@pytest.mark.parametrize("error,status", [(RuntimeError("HTTP 429"), "retryable_error"),
                                        (ValueError("invalid response"), "permanent_error")])
def test_raw_statement_errors_use_shared_retry_classification(monkeypatch, error, status):
    class FakeTicker:
        def get_income_stmt(self, **kwargs):
            raise error

    monkeypatch.setattr("mylib.yahoo_service.yf.Ticker", lambda symbol: FakeTicker())
    result = YahooService().raw_statement("ABC", "income", "annual")
    assert result.status == status
    assert result.error is error


@pytest.mark.skipif(
    os.environ.get("RUN_YAHOO_INTEGRATION") != "1",
    reason="Set RUN_YAHOO_INTEGRATION=1 to fetch live Yahoo Finance data",
)
def test_apple_fundamentals_prints_profile():
    result = YahooService().profile("AAPL")

    assert result.status == "success", result.error
    assert isinstance(result.data, dict)
    pprint(result.data, sort_dicts=True)
