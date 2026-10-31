import pandas as pd

from mylib.yahoo_mapping import history_records, statement_records


def test_statement_mapping_preserves_zero_negative_and_missing_currency():
    frame = pd.DataFrame({pd.Timestamp("2024-12-31"): {"Total Revenue": 0, "Net Income": -12, "Gross Profit": float("nan")}})

    records = statement_records(frame, "income", "ABC")

    assert records == [{"symbol": "ABC", "date": pd.Timestamp("2024-12-31").date(), "period": "FY", "revenue": 0, "netIncome": -12}]


def test_price_mapping_keeps_unadjusted_and_fx_orientation():
    frame = pd.DataFrame({"Open": [2.0], "Close": [3.0], "Adj Close": [2.5], "Volume": [0]}, index=[pd.Timestamp("2024-01-02")])

    equity = history_records(frame, "ABC", currency="USD")[0]
    fx = history_records(frame, "EURUSD=X", fx_currency="USD")[0]

    assert equity["close"] == 3.0
    assert equity["adjClose"] == 2.5
    assert equity["volume"] == 0
    assert fx["symbol"] == "USD"
    assert fx["currency"] == "EUR"