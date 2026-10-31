"""Fetch unadjusted daily equity prices and raw EUR-based Yahoo FX pairs."""

from datetime import date, timedelta

from mylib.yahoo_mapping import history_records
from mylib.worker_common import fetch, run_worker


def _history_request(service, symbol, row, config, logger, throttle):
    if row.get("longTimeSerie"):
        return fetch(lambda: service.history(symbol), config, logger, throttle)
    start = (date.today() - timedelta(days=int(config["control"]["history_overlap_days"]))).isoformat()
    return fetch(lambda: service.history(symbol, start=start, end=(date.today() + timedelta(days=1)).isoformat()), config, logger, throttle)


def update(config, logger, throttle, service, database, worker_args):
    reference_rows = database.rows("reference_map")
    for row in reference_rows:
        symbol = row.get("symbol")
        if not symbol:
            continue
        try:
            result = _history_request(service, str(symbol), row, config, logger, throttle)
            if result.status != "success":
                logger.info("No price history for %s (%s); leaving backfill flag unchanged", symbol, result.status)
                continue
            records = history_records(result.data, str(symbol), row.get("currency"))
            written = database.upsert("quote", records)
            if row.get("longTimeSerie") and written:
                database.update_reference_flag("reference_map", "symbol", symbol, "longTimeSerie", False)
            logger.info("Price history %s: stored %s row(s)", symbol, written)
        except Exception:
            logger.exception("Price history update failed for %s", symbol)

    fx_rows = database.rows("reference_fx")
    for row in fx_rows:
        currency = row.get("symbol")
        if not currency:
            continue
        yahoo_symbol = f"EUR{currency}=X"
        try:
            result = _history_request(service, yahoo_symbol, row, config, logger, throttle)
            if result.status != "success":
                logger.info("No FX history for %s (%s); leaving backfill flag unchanged", yahoo_symbol, result.status)
                continue
            records = history_records(result.data, yahoo_symbol, fx_currency=str(currency))
            written = database.upsert("fx", records)
            if row.get("longTimeSerie") and written:
                database.update_reference_flag("reference_fx", "symbol", currency, "longTimeSerie", False)
            logger.info("FX %s (%s): stored %s row(s)", yahoo_symbol, currency, written)
        except Exception:
            logger.exception("FX history update failed for %s", yahoo_symbol)


if __name__ == "__main__":
    run_worker(update, "update_timeserie_delay")