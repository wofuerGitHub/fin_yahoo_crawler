"""Explicit Yahoo source-label to raw-table field mappings."""

from __future__ import annotations

import math
from datetime import date, datetime
from numbers import Number
from typing import Any, Callable
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

import pandas as pd


STATEMENT_LABELS = {
    "income": {
        "total revenue": "revenue",
        "operating revenue": "revenue",
        "gross profit": "grossProfit",
        "research and development": "researchAndDevelopmentExpenses",
        "research development": "researchAndDevelopmentExpenses",
        "operating income": "operatingIncome",
        "net income": "netIncome",
        "basic average shares": "weightedAverageShsOut",
        "diluted average shares": "weightedAverageShsOutDil",
        "interest expense non operating": "interestExpense",
        "income tax expense": "incomeTaxExpense",
    },
    "balance": {
        "total assets": "totalAssets",
        "total liabilities net minority interest": "totalLiabilities",
        "stockholders equity": "totalStockholdersEquity",
        "total stockholders equity": "totalStockholdersEquity",
        "preferred stock": "preferredStock",
        "cash cash equivalents and short term investments": "cashAndShortTermInvestments",
        "long term debt": "longTermDebt",
        "current debt": "shortTermDebt",
        "accounts receivable": "netReceivables",
        "inventory": "inventory",
    },
    "cashflow": {
        "operating cash flow": "operatingCashFlow",
        "cash flow from continuing operating activities": "operatingCashFlow",
        "capital expenditure": "capitalExpenditure",
        "free cash flow": "freeCashFlow",
        "cash dividends paid": "dividendsPaid",
        "common stock dividend paid": "dividendsPaid",
        "stock based compensation": "stockBasedCompensation",
        "investing cash flow": "netCashUsedForInvestingActivites",
        "financing cash flow": "netCashUsedProvidedByFinancingActivities",
    },
}

PROFILE_FIELDS = {
    "longName": "companyName",
    "shortName": "companyName",
    "sector": "sector",
    "industry": "industry",
    "country": "country",
    "website": "website",
    "currency": "currency",
    "financialCurrency": "reportedCurrency",
    "marketCap": "marketCap",
    "enterpriseValue": "enterpriseValue",
    "sharesOutstanding": "sharesOutstanding",
    "trailingPE": "priceEarningsRatio",
    "priceToBook": "priceToBookRatio",
    "trailingEps": "eps",
    "dividendRate": "dividendRate",
    "beta": "beta",
}


def clean_value(value: Any) -> Any:
    if value is None or value is pd.NA or value is pd.NaT:
        return None
    if isinstance(value, (pd.Timestamp, datetime, date)):
        return value.date() if isinstance(value, (pd.Timestamp, datetime)) else value
    if isinstance(value, Number):
        if isinstance(value, float) and not math.isfinite(value):
            return None
        return value.item() if hasattr(value, "item") else value
    if hasattr(value, "to_pydatetime"):
        return value.to_pydatetime()
    try:
        if pd.isna(value):
            return None
    except (TypeError, ValueError):
        pass
    return value


def statement_records(frame: pd.DataFrame, kind: str, symbol: str, currency: str | None = None) -> list[dict[str, Any]]:
    if kind not in STATEMENT_LABELS:
        raise ValueError(f"Unsupported statement kind: {kind}")
    if frame is None or frame.empty:
        return []
    labels = STATEMENT_LABELS[kind]
    records: list[dict[str, Any]] = []
    for period_end in frame.columns:
        record: dict[str, Any] = {
            "symbol": symbol,
            "date": clean_value(period_end),
            "period": "FY",
            "reportedCurrency": currency,
        }
        for source_label, value in frame[period_end].items():
            normalized = " ".join(str(source_label).replace("_", " ").lower().split())
            destination = labels.get(normalized)
            if destination:
                record[destination] = clean_value(value)
        record = {key: value for key, value in record.items() if value is not None}
        if record.get("date") is not None:
            records.append(record)
    return records


def profile_record(symbol: str, info: dict[str, Any]) -> dict[str, Any]:
    record: dict[str, Any] = {"symbol": symbol}
    for source, destination in PROFILE_FIELDS.items():
        if source in info:
            record[destination] = clean_value(info[source])
    return record


def live_close_from_info(info: dict[str, Any]) -> tuple[date, float] | None:
    """Return (session date, price) from a Yahoo quote, only once the market is closed."""
    if info.get("marketState") != "CLOSED":
        return None
    price = clean_value(info.get("regularMarketPrice"))
    timestamp = clean_value(info.get("regularMarketTime"))
    timezone_name = info.get("exchangeTimezoneName")
    if price is None or timestamp is None or not timezone_name or price <= 0:
        return None
    try:
        session = datetime.fromtimestamp(timestamp, ZoneInfo(timezone_name)).date()
    except (ValueError, OverflowError, OSError, ZoneInfoNotFoundError):
        return None
    return session, float(price)


def history_records(
    frame: pd.DataFrame,
    symbol: str,
    currency: str | None = None,
    fx_currency: str | None = None,
    live_close: Callable[[], tuple[date, float] | None] | None = None,
) -> list[dict[str, Any]]:
    """Map a Yahoo history frame to raw rows, skipping rows without a close.

    If the newest row has no close, ``live_close`` is consulted lazily; its price is used
    only when its session date equals that row's date.
    """
    if frame is None or frame.empty:
        return []
    if isinstance(frame.columns, pd.MultiIndex):
        if symbol in frame.columns.get_level_values(-1):
            frame = frame.xs(symbol, axis=1, level=-1)
        elif len(frame.columns.get_level_values(-1).unique()) == 1:
            frame.columns = frame.columns.get_level_values(0)
        else:
            raise ValueError("Unexpected multi-symbol Yahoo history response")

    field_map = {
        "open": "open",
        "high": "high",
        "low": "low",
        "close": "close",
        "adj close": "adjClose",
        "volume": "volume",
        "dividends": "dividend",
        "stock splits": "stockSplit",
    }
    output = []
    last_position = len(frame) - 1
    for position, (observation_time, values) in enumerate(frame.iterrows()):
        record: dict[str, Any] = {"symbol": fx_currency or symbol, "date": clean_value(observation_time)}
        if fx_currency:
            record["currency"] = "EUR"
        elif currency:
            record["currency"] = currency
        for source, value in values.items():
            destination = field_map.get(" ".join(str(source).lower().split()))
            if destination:
                record[destination] = clean_value(value)
        record = {key: value for key, value in record.items() if value is not None}
        if record.get("close") is None and live_close is not None and position == last_position:
            live = live_close()
            if live is not None and live[0] == record.get("date"):
                record["close"] = live[1]
        if record.get("close") is not None:
            output.append(record)
    return output