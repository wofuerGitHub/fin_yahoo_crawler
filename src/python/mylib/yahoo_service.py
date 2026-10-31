"""Thin yfinance adapter. Importing this module performs no network calls."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import pandas as pd
import yfinance as yf


@dataclass
class FetchResult:
    status: str
    data: Any = None
    error: Exception | None = None


class YahooService:
    def __init__(self, timeout_seconds: int = 20):
        self.timeout_seconds = timeout_seconds

    @staticmethod
    def _result(data: Any) -> FetchResult:
        if data is None or (isinstance(data, (pd.DataFrame, dict)) and len(data) == 0):
            return FetchResult("no_data", data)
        return FetchResult("success", data)

    def profile(self, symbol: str) -> FetchResult:
        try:
            ticker = yf.Ticker(symbol)
            return self._result(ticker.get_info())
        except Exception as error:
            return FetchResult("retryable_error" if self.is_retryable(error) else "permanent_error", error=error)

    def statement(self, symbol: str, kind: str) -> FetchResult:
        attributes = {"income": "income_stmt", "balance": "balance_sheet", "cashflow": "cashflow"}
        if kind not in attributes:
            raise ValueError(f"Unsupported statement kind: {kind}")
        try:
            ticker = yf.Ticker(symbol)
            return self._result(getattr(ticker, attributes[kind]))
        except Exception as error:
            return FetchResult("retryable_error" if self.is_retryable(error) else "permanent_error", error=error)

    def history(self, symbol: str, start: str | None = None, end: str | None = None) -> FetchResult:
        try:
            ticker = yf.Ticker(symbol)
            options = {"interval": "1d", "auto_adjust": False, "actions": True, "timeout": self.timeout_seconds, "raise_errors": True}
            if start is None and end is None:
                options["period"] = "max"
            else:
                options["start"] = start
                options["end"] = end
            return self._result(ticker.history(**options))
        except Exception as error:
            return FetchResult("retryable_error" if self.is_retryable(error) else "permanent_error", error=error)

    def recent_history(self, symbol: str) -> FetchResult:
        try:
            ticker = yf.Ticker(symbol)
            history = self._result(ticker.history(period="5d", interval="1d", auto_adjust=False, actions=False, timeout=self.timeout_seconds, raise_errors=True))
        except Exception as error:
            return FetchResult("retryable_error" if self.is_retryable(error) else "permanent_error", error=error)
        return history

    @staticmethod
    def is_retryable(error: Exception) -> bool:
        message = str(error).lower()
        status_code = getattr(error, "status_code", None) or getattr(getattr(error, "response", None), "status_code", None)
        return status_code == 429 or any(token in message for token in ("429", "rate limit", "too many requests", "timed out", "timeout", "temporarily unavailable", "connection"))