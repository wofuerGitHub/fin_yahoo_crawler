"""Sync the maintained reference universe into the raw asset list."""

from mylib.worker_common import run_worker


def update(config, logger, throttle, service, database, worker_args):
    references = database.rows("reference_map")
    assets = []
    for row in references:
        symbol = row.get("symbol")
        if symbol:
            assets.append({"symbol": str(symbol), "currency": row.get("currency")})
    logger.info("Syncing %s reference instruments; Yahoo does not provide a complete market universe", len(assets))
    logger.info("Upserted %s raw asset rows", database.upsert("symbolslist", assets))


if __name__ == "__main__":
    run_worker(update, "update_symbolslist_delay")