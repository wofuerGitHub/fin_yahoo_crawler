"""Common CLI lifecycle and provider-call helpers for crawler workers."""

from __future__ import annotations

import argparse
import time
from typing import Any, Callable

from mylib.config import load_config, resolve_path
from mylib.write_log import create_logger
from mylib.yahoo_db import Database
from mylib.yahoo_mapping import live_close_from_info
from mylib.yahoo_service import FetchResult, YahooService
from mylib.yahoo_throttle import YahooThrottle, call_with_retry


def make_runtime(config_path: str):
    config = load_config(config_path)
    logger = create_logger(config)
    throttle = YahooThrottle(resolve_path(config, config["file"]["speed_control"]), float(config["connection"]["speed"]), logger)
    service = YahooService(int(config["connection"]["timeout_seconds"]))
    database = Database(config)
    return config, logger, throttle, service, database


def fetch(operation: Callable[[], FetchResult], config: dict[str, Any], logger, throttle: YahooThrottle) -> FetchResult:
    def checked_operation() -> FetchResult:
        result = operation()
        if result.status == "retryable_error":
            raise result.error or RuntimeError("Yahoo returned a retryable error")
        return result

    result = call_with_retry(
        checked_operation,
        throttle,
        int(config["connection"]["max_attempts"]),
        float(config["connection"]["cooldown_seconds_on_rate_limit"]),
        logger,
    )
    if result.status == "permanent_error":
        logger.warning("Yahoo returned a permanent error: %s", result.error)
    return result


def live_close_provider(symbol: str, config: dict[str, Any], logger, throttle: YahooThrottle, service: YahooService, info: dict[str, Any] | None = None):
    """Build a lazy fallback for a missing latest close; lookup failures yield no fallback."""

    def provide():
        try:
            quote = info
            if quote is None:
                result = fetch(lambda: service.profile(symbol), config, logger, throttle)
                quote = result.data if result.status == "success" else None
            live = live_close_from_info(quote) if quote else None
        except Exception:
            logger.warning("Live quote lookup failed for %s; leaving latest close missing", symbol, exc_info=True)
            return None
        if live is not None:
            logger.info("Yahoo daily close missing for %s on %s; using live quote %s as provisional close", symbol, live[0], live[1])
        return live

    return provide


def select_fundamental_symbols(reference_rows: list[dict[str, Any]], update_all: bool) -> list[str]:
    selected = []
    for row in reference_rows:
        symbol = row.get("symbol") if update_all else (row.get("symbol_fundamental") or row.get("symbol"))
        if symbol and str(symbol).strip():
            selected.append(str(symbol).strip())
    return list(dict.fromkeys(selected))


def select_flagged(rows: list[dict[str, Any]], flag: str) -> list[dict[str, Any]]:
    return [row for row in rows if bool(row.get(flag))]


def run_worker(worker: Callable, delay_key: str, argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--config", default="config.json")
    parser.add_argument("--once", action="store_true", help="run once and exit")
    args, worker_args = parser.parse_known_args(argv)
    config, logger, throttle, service, database = make_runtime(args.config)
    delay = max(0.0, float(config["control"].get(delay_key, 0.0)))
    try:
        while True:
            try:
                worker(config, logger, throttle, service, database, worker_args)
            except Exception:
                logger.exception("Worker run failed")
            if args.once:
                break
            time.sleep(delay)
    except KeyboardInterrupt:
        logger.info("Worker stopped")
    finally:
        database.close()