import pandas as pd

from mylib.yahoo_mapping import history_records, live_close_from_info, statement_records


def test_statement_mapping_preserves_zero_negative_and_missing_currency():
    frame = pd.DataFrame({pd.Timestamp("2024-12-31"): {"Total Revenue": 0, "Net Income": -12, "Gross Profit": float("nan")}})

    records = statement_records(frame, "income", "ABC")

    assert records == [{"symbol": "ABC", "date": pd.Timestamp("2024-12-31").date(), "period": "FY", "calendarYear": "2024", "revenue": 0, "netIncome": -12}]


def test_price_mapping_keeps_unadjusted_and_fx_orientation():
    frame = pd.DataFrame({"Open": [2.0], "Close": [3.0], "Adj Close": [2.5], "Volume": [0]}, index=[pd.Timestamp("2024-01-02")])

    equity = history_records(frame, "ABC", currency="USD")[0]
    fx = history_records(frame, "EURUSD=X", fx_currency="USD")[0]

    assert equity["close"] == 3.0
    assert equity["adjClose"] == 2.5
    assert equity["volume"] == 0
    assert fx["symbol"] == "USD"
    assert fx["currency"] == "EUR"


def test_price_mapping_skips_only_rows_without_close():
    frame = pd.DataFrame(
        {"Open": [10.0, 11.0, 12.0], "Close": [10.5, float("nan"), 12.5]},
        index=pd.date_range("2024-01-02", periods=3),
    )

    records = history_records(frame, "ABC", currency="USD")

    assert [record["date"] for record in records] == [
        pd.Timestamp("2024-01-02").date(),
        pd.Timestamp("2024-01-04").date(),
    ]
    assert [record["close"] for record in records] == [10.5, 12.5]

def _frame_with_missing_latest_close():
    return pd.DataFrame(
        {"Open": [10.0, 11.0], "Close": [10.5, float("nan")]},
        index=pd.date_range("2024-01-02", periods=2),
    )


def test_missing_latest_close_uses_live_quote_for_same_session():
    live = (pd.Timestamp("2024-01-03").date(), 11.4)

    records = history_records(_frame_with_missing_latest_close(), "ABC", live_close=lambda: live)

    assert [record["close"] for record in records] == [10.5, 11.4]


def test_live_quote_ignored_for_other_session_and_older_rows():
    frame = pd.DataFrame(
        {"Open": [10.0, 11.0], "Close": [float("nan"), 11.5]},
        index=pd.date_range("2024-01-02", periods=2),
    )
    stale = (pd.Timestamp("2024-01-02").date(), 99.0)

    assert [r["close"] for r in history_records(frame, "ABC", live_close=lambda: stale)] == [11.5]
    other = (pd.Timestamp("2024-01-05").date(), 99.0)
    assert [r["close"] for r in history_records(_frame_with_missing_latest_close(), "ABC", live_close=lambda: other)] == [10.5]


def test_live_quote_not_requested_when_close_present():
    frame = pd.DataFrame({"Close": [10.5]}, index=[pd.Timestamp("2024-01-02")])

    def fail():
        raise AssertionError("live quote must not be fetched")

    assert len(history_records(frame, "ABC", live_close=fail)) == 1


def test_live_close_from_info_requires_closed_market():
    info = {"marketState": "CLOSED", "regularMarketPrice": 57.8, "regularMarketTime": 1793378163, "exchangeTimezoneName": "Europe/Berlin"}

    assert live_close_from_info(info) == (pd.Timestamp("2026-10-30").date(), 57.8)
    assert live_close_from_info({**info, "marketState": "REGULAR"}) is None
    assert live_close_from_info({**info, "regularMarketPrice": None}) is None
    assert live_close_from_info({**info, "regularMarketPrice": 0}) is None
    assert live_close_from_info({**info, "exchangeTimezoneName": "Nowhere/Land"}) is None
