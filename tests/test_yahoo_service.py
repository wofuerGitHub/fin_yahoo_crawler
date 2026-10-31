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


@pytest.mark.skipif(
    os.environ.get("RUN_YAHOO_INTEGRATION") != "1",
    reason="Set RUN_YAHOO_INTEGRATION=1 to fetch live Yahoo Finance data",
)
def test_apple_fundamentals_prints_profile():
    result = YahooService().profile("AAPL")

    assert result.status == "success", result.error
    assert isinstance(result.data, dict)
    pprint(result.data, sort_dicts=True)