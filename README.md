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

The Yahoo crawler workers are raw-data ingesters. The separate, opt-in
`fundamental_worker.py` ETL described below derives configured metrics locally. It may parse dates, map labels, cast values,
replace `NaN` with SQL `NULL`, and retain source currencies and units. It does
not convert currencies, compute per-share measures or ratios, or write SQL-owned
derived datasets.

| Responsibility | Owner |
|---|---|
| Yahoo requests, pacing, retries, source-field mapping | Python crawler |
| Raw table inserts/upserts and reference-table reads | Python crawler |
| Currency conversion, EPS/DPS/CPS/BPS calculations, ratios, aggregations | Existing MySQL logic |
| `raw_fun`, `eur_*`, analytical views and downstream models | Existing MySQL logic |

The Yahoo ingestion workers never write `raw_fun`, `eur_fun`, `eur_ts_quote`, or other derived
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
| `income_2` | `raw_fun_income_2` | Annual/quarterly income metrics, one metric per row |
| `cashflow_2` | `raw_fun_cashflow_2` | Annual/quarterly cash-flow metrics, one metric per row |
| `balance_2` | `raw_fun_balance_2` | Annual/quarterly balance-sheet metrics, one metric per row |
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
  ends, and the legacy mapper labels these annual records `FY`. `reportedCurrency` is
  taken from the profile table when available, otherwise from Yahoo's
  `financialCurrency`; the crawler does not infer it
  from the instrument's trading currency. `calendarYear` is the year of the
  period-end date (required by the `raw_fun` triggers). Quarterly ingestion into
  these legacy wide tables is disabled until their uniqueness contract is reviewed.
  The separate `update_statement_2.py` worker described below stores all available
  source metrics in the prepared row-per-metric tables, including quarterly data.
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

### Full statements: one metric per row

`update_statement_2.py` writes to the three prepared `_2` tables. By default it
fetches income, balance, and cash-flow statements for **both annual and quarterly**
periods, across all history returned by the pinned `yfinance` version. It uses
the same symbol selection, shared throttle, retries, logging, database settings,
and `update_statement_delay` as the original worker.

```text
python src/python/update_statement_2.py --once
python src/python/update_statement_2.py income --period-type annual --once
python src/python/update_statement_2.py balance --period-type quarterly --once
python src/python/update_statement_2.py cashflow --once --config config/config.local.json
```

The optional positional argument is `income`, `balance`, `cashflow`, or `all`
(default). `--period-type` accepts `annual`, `quarterly`, or `all` (default).
Keep the legacy `control.statement_frequency` setting at `annual`; this new
worker's period selection is independent because its destination keys explicitly
distinguish periods. Without `--once`, it repeats after `update_statement_delay`;
set a suitable nonzero delay for continuous use.

Each statement cell produces a row containing `symbol`, `period_type`,
`report_date`, `metric`, `value`, `currency`, and `fetched_at`. Yahoo's raw metric
names are returned using `pretty=False` and stored unchanged (for example,
`TotalRevenue`, `BasicEPS`, or `OperatingCashFlow`), with no field whitelist or
mapping to FMP names. Newly returned metrics are included automatically.
The worker preserves zero and negative values and writes unavailable/non-finite
values as SQL `NULL`. MySQL's `DECIMAL(30,6)` defines the stored numeric precision.
The reporting currency comes from `companykeystats.reportedCurrency`, falling
back to Yahoo's `financialCurrency`; if unavailable, it remains `NULL` without
discarding statement values. Currency is statement metadata, not an assertion
that every metric (such as share counts) is a monetary amount.

The `income_2`, `balance_2`, and `cashflow_2` table mappings are configurable under
`yahoo.database.tables` and default to `raw_fun_income_2`, `raw_fun_balance_2`,
and `raw_fun_cashflow_2` when absent in older configs. These tables must already
exist with the prepared schema: an auto-increment `id`, the columns above, and a
unique key on `(symbol, period_type, report_date, metric)`. Repeated runs update
the existing metric row and refresh `fetched_at`; unavailable values never
replace existing non-NULL observations. No metrics are deleted, and the worker
does not create or modify tables or write to the legacy wide statement tables.

Only history and metrics actually exposed by `yfinance` can be ingested; this
does not recover unavailable Yahoo history. Trailing/TTM data is excluded because
the prepared `period_type` enum only supports annual and quarterly observations.

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
2. Legacy statement keys distinguish the intended annual periods and currencies.
   Do not enable quarterly ingestion into the legacy wide tables until their
   uniqueness and downstream use have been reviewed. The `_2` tables distinguish
   annual and quarterly observations using `period_type` in their unique keys.
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

Run the complete test suite, including the isolated MySQL integration test,
with:

```powershell
python run_tests.py
```

Create `.env` from `.env.example` and set `MYSQL_PASSWORD` first. The runner
loads that local file, builds `MYSQL_TEST_URL` using the host, port, and username
from `config.json`, and defaults to the `test_yahoo` schema. Set
`MYSQL_TEST_SCHEMA` to a different dedicated test schema if needed; the runner
and integration test both reject schema names that do not start with `test_`.
The integration test creates and removes a uniquely named fixture table.

The suite also covers config/environment handling, source mappings, worker
selection, throttle concurrency/recovery, and retry/cooldown behavior. Live
Yahoo smoke tests remain opt-in with `RUN_YAHOO_INTEGRATION=1` and are not
required for the test suite.

Docker Compose runs one worker per container invocation. Set `MYSQL_PASSWORD`
in the environment and run, for example:

```text
docker compose run --rm yahoo-worker python src/python/update_timeserie.py --once
```

Replace the script path for another worker. The Compose service mounts
`./runtime` for shared throttle state and `./logs` for logs. Keep these paths
shared among workers on the same host. `init.sh` is a workspace setup script,
not a crawler installer or launcher.

## Configurable fundamental ETL

`fundamental_worker.py` reads `income_2`, `balance_2`, and `cashflow_2` and
writes one wide row per `(symbol, period_type, report_date, currency)` to the configured
`database.tables.fun` (default `raw_fun_2`). It makes no Yahoo requests and does
not use reference-table selectors. Each run recomputes all groups present in
any source table. Source rows are currently read into memory.

```text
python src/python/fundamental_worker.py --once --config config.json
```

Without `--once`, it repeats after `control.fundamental_delay` (default 3600
seconds). A failed one-shot run exits with an error. Tables must already exist;
the worker never creates or migrates a schema.

Define formulas under `yahoo.fundamental.transformations`:

```json
{
  "fundamental.grossProfitRatio": "income.GrossProfit / income.TotalRevenue",
  "fundamental.cps": "cashflow.OperatingCashFlow / income.DilutedAverageShares",
  "fundamental.complex": "(abs(income.GrossProfit))^2"
}
```

The optional `fundamental.` output prefix is removed to obtain the column name.
`coalesce(a, b, ...)` returns the first non-NULL result, evaluating arguments
from left to right. Zero and negative values are valid results. Missing metrics,
non-finite values, and undefined arithmetic (such as division by zero) allow the
next fallback; all-NULL arguments produce NULL. At least two arguments are required.
For example, `coalesce(income.DilutedAverageShares, income.BasicAverageShares)`
uses basic shares only when diluted shares are unavailable in the same group.

Source namespaces are `income`, `balance`, and `cashflow`; metric names are
case sensitive. Expressions support numeric constants, parentheses, unary signs,
`+`, `-`, `*`, `/`, `^` (or `**`) and `abs()` / `coalesce(a, b, ...)`. Powers bind before unary signs;
exponents are limited to magnitude 100. Arbitrary Python execution and references
to other output formulas are rejected. Decimal arithmetic uses 38-digit precision;
the destination column controls stored precision.

Currency is always copied to the output `currency` column. Missing or blank source
currencies fail the run; the destination currency column must be NOT NULL.
Inputs are matched only within the exact four-part group. Missing or non-finite
inputs, division by zero, and invalid numeric results produce SQL `NULL`.
Unlike raw ingestion, this ETL **overwrites old calculated values with NULL**
when they can no longer be calculated. Duplicate source metrics within one group
fail the run. Rows absent from all source tables are not deleted from `fun`.

For the supplied example configuration, an illustrative destination schema is:

```sql
CREATE TABLE raw_fun_2 (
  symbol VARCHAR(32) NOT NULL,
  period_type ENUM('annual','quarterly') NOT NULL,
  report_date DATE NOT NULL,
  currency VARCHAR(10) NOT NULL,
  grossProfitRatio DECIMAL(30,6) NULL,
  cps DECIMAL(30,6) NULL,
  complex DECIMAL(65,6) NULL,
  PRIMARY KEY (symbol, period_type, report_date, currency)
);
```

Create or review this table separately before running the worker. Every configured
output column must exist. A unique key on exactly the four grouping columns is
required; other unique keys must not allow distinct groups to collide. An optional
auto-increment primary-key ID is supported. Use case-sensitive symbol collation
if your universe distinguishes symbol casing. All output writes in a run use
one transaction; no currency conversions are performed. Keep source currencies
and units compatible when defining cross-statement calculations.

## Known limitations and non-goals

- Yahoo fields, history depth, revisions, availability, symbol coverage, and
  rate-limit behavior vary. No complete FMP/Yahoo parity is claimed.
- A complete Yahoo stock/ETF universe, five years of statements, and
  guaranteed real-time quotes are not promised.
- The Yahoo ingestion workers do not calculate EUR values, EPS/DPS/CPS/BPS, P/E,
  P/B, ratios, signals, DCF models, or synthetic history.
- Quarterly statements in the legacy wide tables, schema migrations, a generic job
  framework, multi-host file locking, and a second Python financial engine are
  outside the current implementation.
- Validate applicable Yahoo Finance terms and access rights before use or
  redistribution. This project is not investment advice and provides no
  trading signals.


## License

This project is licensed under the [MIT License](LICENSE).
