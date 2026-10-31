# FIN Yahoo Crawler

> **Status: initial implementation.** The repository contains FMP-compatible
> worker entry points and offline tests. Validate the target MySQL schema and
> run the opt-in integration test before connecting this crawler to production.

FIN Yahoo Crawler retrieves available market and company data from Yahoo Finance
through [`yfinance`](https://github.com/ranaroussi/yfinance), maps provider
fields to configured raw MySQL tables, and preserves the FMP crawler's
configuration and table naming conventions where the deployed schema supports
them. Yahoo coverage and response behavior vary by instrument; this is not a
guaranteed replacement for every FMP field or feed.

## Scope and data ownership

The crawler is a raw-data ingester. It may parse dates, map labels, cast values,
replace `NaN` with SQL `NULL`, and retain source currencies and units. It does
not convert currencies, compute per-share measures or ratios, or write SQL-owned
derived datasets.

| Responsibility | Owner |
|---|---|
| Yahoo requests, pacing, retries, source-field mapping | Python crawler |
| Raw table inserts/upserts and reference-table reads | Python crawler |
| Currency conversion, EPS/DPS/CPS/BPS calculations, ratios, aggregations | Existing MySQL logic |
| `raw_fun`, `eur_*`, analytical views and downstream models | Existing MySQL logic |

The crawler never writes `raw_fun`, `eur_fun`, `eur_ts_quote`, or other derived
datasets. It does not install or modify tables, triggers, routines, events, or
views. Do not duplicate database calculations in Python to work around SQL
behavior.

## Architecture and data contract

```text
_reference_map / _reference_fx
              |
              v
     FMP-style worker scripts
              |
   shared file-backed throttle
              |
        yfinance / Yahoo
              |
     field mapping and checks
              |
      configured raw_* tables
              |
 existing MySQL-derived datasets
```

All table names are read from `yahoo.database.tables`. Defaults preserve the
FMP raw table contract:

| Config key | Default table | Contents |
|---|---|---|
| `reference_map` | `_reference_map` | Equity selectors and worker flags |
| `reference_fx` | `_reference_fx` | FX currency selectors and worker flags |
| `symbolslist` | `raw_assetslist` | Instruments copied from the maintained reference universe |
| `companykeystats` | `raw_companykeystats` | Available Yahoo profile fields |
| `income` | `raw_fun_income` | Annual income-statement source values |
| `cashflow` | `raw_fun_cashflow` | Annual cash-flow source values |
| `balance` | `raw_fun_balance` | Annual balance-sheet source values |
| `quote` | `raw_ts_quote` | Daily equity history |
| `fx` | `raw_ts_fx` | Raw Yahoo FX observations |
| `quote_eps` | `raw_ts_quote_eps` | Periodic quote snapshot and source EPS when available |

The MySQL writer reflects the configured tables at runtime, filters mapped
records to columns that actually exist, and requires a primary or unique key
that can identify each upsert. Updates do not replace existing values with
`NULL`. Missing tables, unusable keys, and incompatible required columns fail
with an error; the application does not guess the schema or make migrations.

### Yahoo source mapping

- **Profiles:** `Ticker.get_info()` maps available fields such as name, sector,
  industry, trading currency, financial currency, market capitalization, shares,
  trailing EPS, P/E, P/B, dividend rate, and beta. Only configured destination
  columns are written. Profile refresh skips rows whose `updated` value is
  less than one day old when that column exists.
- **Statements:** annual income, balance-sheet, and cash-flow frames are mapped
  using explicit source-label mappings. Examples include `Total Revenue` to
  `revenue`, `Net Income` to `netIncome`, `Total Assets` to `totalAssets`, and
  `Operating Cash Flow` to `operatingCashFlow`. Period dates are source period
  ends, and the mapper labels these annual records `FY`. `reportedCurrency` is
  taken from the profile table when available; the crawler does not infer it
  from the instrument's trading currency. Quarterly ingestion is disabled
  until the destination uniqueness contract is reviewed.
- **Equity history:** daily `Open`, `High`, `Low`, `Close`, `Adj Close`,
  `Volume`, `Dividends`, and `Stock Splits` are mapped when present. History is
  requested with `auto_adjust=False`; prices remain in source trading units.
- **FX:** `_reference_fx.symbol=USD` maps to Yahoo `EURUSD=X`. The source close
  is stored as `raw_ts_fx.close`, with `symbol=USD` and `currency=EUR`. This is
  an identifier/field mapping only; no price or financial value is converted
  in Python. Verify the pair direction against the target SQL contract before
  deployment.
- **Quote polling:** `stream=true` rows are polled using recent daily history;
  source EPS is stored only when available and supported by the destination
  schema. This is periodic polling, not an exchange-grade real-time feed.

Unknown or unavailable source fields are not synthesized. Numeric zero and
negative values are preserved; non-finite values become SQL `NULL`. An empty
or failed response does not overwrite existing raw values. Unsupported fields
can be omitted when the destination schema does not contain their mapped
columns.

Yahoo does not provide a verified complete stock/ETF listing equivalent to the
FMP list endpoint. `update_symbolslist` copies the maintained `_reference_map`
universe; it does not discover all Yahoo-listed instruments.

## Configuration

[`config.json`](config.json) retains the FMP organization under top-level
`yahoo`: `database`, `connection`, `file`, `control`, and `debug`. The database
table names, host, port, schema, and account are deployment examples; verify
and change them for the target installation. `api_key`, `global`, and `jobs[]`
are not used.

| Setting | Meaning |
|---|---|
| `database.host`, `port`, `schema`, `user`, `password` | MySQL connection |
| `database.tables.*` | Allowlisted logical table names used by workers |
| `connection.speed` | Application-level provider operations per minute |
| `connection.timeout_seconds` | Timeout passed to supported history calls |
| `connection.max_attempts` | Maximum attempts for a provider operation |
| `connection.cooldown_seconds_on_rate_limit` | Shared cooldown after a detected 429/rate-limit response |
| `file.log`, `file.debug` | Operational and optional debug log paths |
| `file.speed_control` | Shared JSON throttle state; its `.lock` sibling is created automatically |
| `control.update_*_delay` | Worker sleep after each completed run |
| `control.update_statement_all` | Use `raw_assetslist` instead of mapped fundamental symbols |
| `control.history_overlap_days` | Rolling history overlap after initial backfill; default 30 |
| `control.statement_frequency` | Must remain `annual` until database period keys are reviewed |
| `debug` | Enables the separate debug log |

`MYSQL_PASSWORD` is expanded by the application from the `${MYSQL_PASSWORD}`
value in the JSON file. It must be set in the process environment; credentials
are not stored in source control or included in log messages. Table identifiers
are validated before SQL use; data values are bound parameters.

## Workers and selection

Install Python 3.11 or newer and the pinned dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
$env:MYSQL_PASSWORD = "your-database-password"
```

On macOS/Linux, activate with `source .venv/bin/activate`. Set database
connection values and table mappings in `config.json` before running a worker.
Each worker repeats after its configured post-run delay; `--once` runs it one
time. `--config PATH` selects another config file.

```text
python src/python/update_symbolslist.py [--once] [--config PATH]
python src/python/update_companykeystats.py [--once] [--config PATH]
python src/python/update_statement.py income [--once] [--config PATH]
python src/python/update_statement.py cashflow [--once] [--config PATH]
python src/python/update_statement.py balance [--once] [--config PATH]
python src/python/update_timeserie.py [--once] [--config PATH]
python src/python/update_stream.py [--once] [--config PATH]
```

Reference-table behavior follows the FMP conventions:

- `_reference_map.symbol` selects equity history and quote polling.
- `_reference_map.symbol_fundamental` selects statement symbols when
  `update_statement_all=false`; it falls back to `symbol` when empty.
- `update_statement_all=true` selects symbols from the configured asset-list
  table.
- `_reference_map.currency` is the instrument's trading currency, not proof of
  its statement reporting currency.
- `_reference_map.longTimeSerie=true` requests maximum available daily history.
  The flag is cleared only after a non-empty write succeeds. Later runs fetch
  the configured rolling overlap and rely on idempotent upserts.
- `_reference_map.stream=true` enables periodic equity quote polling.
- `_reference_fx.symbol` is the currency code used to construct `EUR{code}=X`;
  `longTimeSerie` and `stream` control FX history and polling respectively.

The application does not have a new job-run/status table. Failed work remains
eligible for a later run; backfill flags are not cleared after empty provider
responses or failed writes.

## Request pacing and retries

All workers on one host use the configured throttle state and lock file. Under
an exclusive cross-process lock, each operation reserves a unique slot at
`max(now, next_allowed_at, cooldown_until) + 60 / speed`; the lock is released
before waiting or contacting Yahoo. State writes use a temporary file and an
atomic replace. Missing or malformed state recovers with a warning and a safe
default.

Retryable provider failures are retried up to `max_attempts` with bounded
exponential backoff. Detected HTTP 429/rate-limit failures publish the shared
cooldown so other local workers also pause. `connection.speed` controls
high-level crawler operations, not Yahoo's internal HTTP requests: one
`yfinance` call may issue multiple requests, so this is not a provider quota
guarantee. File locks on network filesystems or between separate hosts are not
guaranteed; multi-host deployment needs a tested centralized reservation
mechanism.

## Database checks before deployment

Inspect the actual target database before ingestion. Confirm:

1. The configured raw and reference tables, columns, required fields, unique
   keys, generated columns, triggers, routines, and scheduled events exist.
2. Statement keys distinguish the intended annual periods and currencies.
   Do not enable quarterly ingestion until its uniqueness and downstream use
   have been reviewed.
3. `raw_ts_fx` expects the observed Yahoo pair direction and the same `symbol`,
   `currency`, date, and rate conventions used by the downstream SQL. The
   intended `EURXXX` quote is units of `XXX` per EUR, but must be verified.
4. Existing SQL correctly handles FX date matching, missing rates, revisions,
   late-arriving history, pence/pounds, and downstream recalculation.
5. The destination columns and unique keys match the source mappings and
   support idempotent upserts without replacing good values with unavailable
   data.

Archived database examples are not proof of the deployed schema's correctness
or completeness. Do not install legacy triggers or point an unverified
configuration at production tables. Schema migrations and downstream SQL fixes
are separate database deployment tasks.

## Tests and deployment

Run offline fixture tests with:

```powershell
python -m pytest
```

The tests cover config/environment handling, source mappings, worker selection,
throttle concurrency/recovery, and retry/cooldown behavior. An opt-in MySQL
integration test creates and removes a uniquely named fixture table. Set
`MYSQL_TEST_URL` only to a dedicated test database whose schema name starts
with `test_`; it refuses other schema names. Live Yahoo smoke tests are
separate and cannot prove universal field completeness or safe request quotas.

Docker Compose runs one worker per container invocation. Set `MYSQL_PASSWORD`
in the environment and run, for example:

```text
docker compose run --rm yahoo-worker python src/python/update_timeserie.py --once
```

Replace the script path for another worker. The Compose service mounts
`./runtime` for shared throttle state and `./logs` for logs. Keep these paths
shared among workers on the same host. `init.sh` is a workspace setup script,
not a crawler installer or launcher.

## Known limitations and non-goals

- Yahoo fields, history depth, revisions, availability, symbol coverage, and
  rate-limit behavior vary. No complete FMP/Yahoo parity is claimed.
- A complete Yahoo stock/ETF universe, five years of statements, and
  guaranteed real-time quotes are not promised.
- The implementation does not calculate EUR values, EPS/DPS/CPS/BPS, P/E,
  P/B, ratios, signals, DCF models, or synthetic history.
- Quarterly statements, a competing schema, schema migrations, a generic job
  framework, multi-host file locking, and a second Python financial engine are
  outside the current implementation.
- Validate applicable Yahoo Finance terms and access rights before use or
  redistribution. This project is not investment advice and provides no
  trading signals.


## License

This project is licensed under the [MIT License](LICENSE).