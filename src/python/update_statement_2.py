"""Store all available Yahoo statement metrics in the row-per-metric raw tables."""

from __future__ import annotations

import argparse
from datetime import date, datetime
from decimal import Decimal
from typing import Any

import pandas as pd
from sqlalchemy import func

from mylib.worker_common import fetch, run_worker, select_fundamental_symbols


TABLES = {kind: f"{kind}_2" for kind in ("income", "balance", "cashflow")}
PERIODS = ("annual", "quarterly")


def statement_records(
    frame: pd.DataFrame,
    symbol: str,
    period_type: str,
    currency: str | None = None,
) -> list[dict[str, Any]]:
    """Unpivot every cell without renaming, selecting, or deriving metrics.

    The destination DECIMAL(30,6) controls stored precision. Missing and
    non-finite observations are NULL; the shared upsert preserves existing
    non-NULL values when Yahoo subsequently omits an observation.
    """
    if period_type not in PERIODS:
        raise ValueError(f"Unsupported statement period: {period_type}")
    if frame is None or frame.empty:
        return []
    records = []
    for period_end, values in frame.items():
        if pd.isna(period_end) or not isinstance(period_end, (date, datetime, pd.Timestamp)):
            raise ValueError(f"Invalid statement report date: {period_end!r}")
        report_date = period_end.date() if isinstance(period_end, (datetime, pd.Timestamp)) else period_end
        for metric, value in values.items():
            if not isinstance(metric, str) or not metric or len(metric) > 128:
                raise ValueError(f"Statement metric does not fit VARCHAR(128): {metric!r}")
            number = None if pd.isna(value) else Decimal(str(value))
            if number is not None and not number.is_finite():
                number = None
            records.append({
                "symbol": symbol,
                "period_type": period_type,
                "report_date": report_date,
                "metric": metric,
                "value": number,
                "currency": currency,
                # Use the DB session clock, so TIMESTAMP conversion is correct
                # regardless of the server/session time zone. Refresh on upsert.
                "fetched_at": func.current_timestamp(),
            })
    return records


def argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("kind", nargs="?", choices=[*TABLES, "all"], default="all")
    parser.add_argument("--period-type", choices=[*PERIODS, "all"], default="all",
                        help="periods to fetch (default: annual and quarterly)")
    return parser


def reported_currency(symbol, profiles, config, logger, throttle, service):
    currency = profiles.get(symbol, {}).get("reportedCurrency")
    if currency:
        return currency
    try:
        info = fetch(lambda: service.profile(symbol), config, logger, throttle)
        if info.status == "success":
            currency = info.data.get("financialCurrency")
    except Exception:
        logger.exception("Reporting currency lookup failed for %s", symbol)
    if not currency:
        logger.warning("No reporting currency for %s; storing statement metrics with NULL currency", symbol)
    return currency


def update(config, logger, throttle, service, database, worker_args):
    args = argument_parser().parse_args(worker_args)
    kinds = tuple(TABLES) if args.kind == "all" else (args.kind,)
    periods = PERIODS if args.period_type == "all" else (args.period_type,)
    update_all = bool(config["control"]["update_statement_all"])
    universe = database.rows("symbolslist" if update_all else "reference_map")
    symbols = select_fundamental_symbols(universe, update_all)
    try:
        profiles = {str(row["symbol"]): row for row in database.rows("companykeystats") if row.get("symbol")}
    except Exception:
        logger.warning("Profile table unavailable; will request Yahoo reporting currencies", exc_info=True)
        profiles = {}
    for symbol in symbols:
        currency = None
        currency_loaded = False
        for kind in kinds:
            for period_type in periods:
                try:
                    result = fetch(lambda: service.raw_statement(symbol, kind, period_type), config, logger, throttle)
                    if result.status != "success":
                        logger.info("No %s %s statement data for %s (%s)", period_type, kind, symbol, result.status)
                        continue
                    if not currency_loaded:
                        currency = reported_currency(symbol, profiles, config, logger, throttle, service)
                        currency_loaded = True
                    records = statement_records(result.data, symbol, period_type, currency)
                    written = database.upsert(TABLES[kind], records)
                    logger.info("%s %s %s: stored %s metric rows", period_type, kind, symbol, written)
                except Exception:
                    logger.exception("%s %s statement update failed for %s", period_type, kind, symbol)


def main(argv: list[str] | None = None) -> None:
    parser = argument_parser()
    parser.add_argument("--config", default="config.json")
    parser.add_argument("--once", action="store_true", help="run once and exit")
    args = parser.parse_args(argv)
    worker_args = [args.kind, "--period-type", args.period_type, "--config", args.config]
    if args.once:
        worker_args.append("--once")
    run_worker(update, "update_statement_delay", worker_args)


if __name__ == "__main__":
    main()
