"""Poll reference rows marked for quote/FX updates; this is not a live feed."""

from mylib.yahoo_mapping import clean_value, history_records
from mylib.worker_common import fetch, live_close_provider, run_worker


def update(config, logger, throttle, service, database, worker_args):
    for row in database.rows("reference_map"):
        symbol = row.get("symbol")
        if not symbol or not row.get("stream"):
            continue
        try:
            history_result = fetch(lambda: service.recent_history(str(symbol)), config, logger, throttle)
            if history_result.status != "success":
                logger.info("No quote snapshot for %s (%s)", symbol, history_result.status)
                continue
            info_result = fetch(lambda: service.profile(str(symbol)), config, logger, throttle)
            info = info_result.data if info_result.status == "success" else None
            records = history_records(
                history_result.data,
                str(symbol),
                row.get("currency"),
                live_close=live_close_provider(str(symbol), config, logger, throttle, service, info=info or {}),
            )
            if not records:
                continue
            snapshot = records[-1]
            snapshot["eps"] = clean_value(info.get("trailingEps")) if info else None
            logger.info("Quote snapshot %s: stored %s row(s)", symbol, database.upsert("quote_eps", [snapshot]))
        except Exception:
            logger.exception("Quote polling failed for %s", symbol)

    for row in database.rows("reference_fx"):
        currency = row.get("symbol")
        if not currency or not row.get("stream"):
            continue
        yahoo_symbol = f"EUR{currency}=X"
        try:
            result = fetch(lambda: service.recent_history(yahoo_symbol), config, logger, throttle)
            if result.status != "success":
                continue
            records = history_records(result.data, yahoo_symbol, fx_currency=str(currency))
            if records:
                logger.info("FX poll %s: stored %s row(s)", currency, database.upsert("fx", records[-1:]))
        except Exception:
            logger.exception("FX polling failed for %s", yahoo_symbol)


if __name__ == "__main__":
    run_worker(update, "update_stream_delay")