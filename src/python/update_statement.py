"""Fetch annual raw income, balance-sheet, or cash-flow statements."""

from mylib.yahoo_mapping import statement_records
from mylib.worker_common import fetch, run_worker, select_fundamental_symbols


TABLES = {"income": "income", "cashflow": "cashflow", "balance": "balance"}


def update(config, logger, throttle, service, database, worker_args):
    if len(worker_args) != 1 or worker_args[0] not in TABLES:
        raise ValueError("Usage: update_statement.py income|cashflow|balance [--once] [--config PATH]")
    kind = worker_args[0]
    references = database.rows("reference_map")
    update_all = bool(config["control"]["update_statement_all"])
    universe = database.rows("symbolslist") if update_all else references
    symbols = select_fundamental_symbols(universe, update_all)
    profiles = {str(row.get("symbol")): row for row in database.rows("companykeystats") if row.get("symbol")}
    for symbol in symbols:
        try:
            result = fetch(lambda: service.statement(symbol, kind), config, logger, throttle)
            if result.status != "success":
                logger.info("No %s statement data for %s (%s)", kind, symbol, result.status)
                continue
            currency = profiles.get(symbol, {}).get("reportedCurrency")
            records = statement_records(result.data, kind, symbol, currency)
            logger.info("%s %s: stored %s raw annual rows", kind, symbol, database.upsert(TABLES[kind], records))
        except Exception:
            logger.exception("%s statement update failed for %s", kind, symbol)


if __name__ == "__main__":
    run_worker(update, "update_statement_delay")