"""Fetch available Yahoo company profile fields into the raw profile table."""

from datetime import date, datetime, time, timedelta, timezone

from mylib.yahoo_mapping import profile_record
from mylib.worker_common import fetch, run_worker


def update(config, logger, throttle, service, database, worker_args):
    references = database.rows("reference_map")
    existing = database.existing_symbols("companykeystats")
    cutoff = datetime.now(timezone.utc) - timedelta(days=1)
    symbols = list(dict.fromkeys(str(row["symbol"]) for row in references if row.get("symbol")))
    for symbol in symbols:
        updated = existing.get(symbol)
        if isinstance(updated, date) and not isinstance(updated, datetime):
            updated = datetime.combine(updated, time.min, tzinfo=timezone.utc)
        elif updated is not None and getattr(updated, "tzinfo", None) is None:
            updated = updated.replace(tzinfo=timezone.utc)
        if updated is not None and updated >= cutoff:
            continue
        try:
            result = fetch(lambda: service.profile(symbol), config, logger, throttle)
            if result.status != "success":
                logger.info("No Yahoo profile data for %s (%s)", symbol, result.status)
                continue
            written = database.upsert("companykeystats", [profile_record(symbol, result.data)])
            logger.info("Profile %s: %s row(s) stored", symbol, written)
        except Exception:
            logger.exception("Profile update failed for %s", symbol)


if __name__ == "__main__":
    run_worker(update, "update_companykeystats_delay")