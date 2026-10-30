# FIN Yahoo Crawler

> **Status: design phase.** This repository currently documents a proposed
> Yahoo Finance crawler; it does not yet contain a production crawler
> implementation. The design and examples are not evidence of working or
> end-to-end tested functionality.

FIN Yahoo Crawler is planned as a Python application that retrieves raw market
and company data from Yahoo Finance through [`yfinance`](https://github.com/ranaroussi/yfinance)
and stores it in MySQL. The goal is to replace the Financial Modeling Prep
(FMP) data source while preserving the existing FMP crawler's configuration
conventions and raw-table contracts where the deployed database supports them.

## Design principles

- **Store source data, not derived financial analysis.** The crawler is
  intended to fetch and map Yahoo-reported values to raw database tables.
- **Keep financial calculations in MySQL.** Currency conversion, per-share
  metrics, ratios, and derived datasets remain the responsibility of existing
  database logic—not the Python crawler.
- **Preserve existing integration contracts.** Use an FMP-style configuration,
  reference-table-driven asset selection, and configurable table names.
  Confirm the actual database schema before relying on compatibility.
- **Pace requests safely.** The proposed workers share a persistent,
  cross-process request throttle with bounded retries and cooldown handling.
- **Represent missing data honestly.** Unavailable Yahoo fields should remain
  unavailable rather than being fabricated or silently replaced with zero.

## Planned data

The design covers:

- Company profiles and available key statistics
- Income statements, balance sheets, and cash-flow statements
- Historical daily prices in the source trading currency
- Raw foreign-exchange observations, including Yahoo currency pairs such as
  `EURUSD=X`
- Periodic quote snapshots where supported by the source

Yahoo's available fields, history, symbol coverage, and update behavior may
differ from FMP and can vary by instrument. A complete stock/ETF universe or
guaranteed real-time feed is not assumed.

## Architecture and documentation

The planned flow is:

```text
MySQL reference tables
        |
        v
Python workers --> shared request throttle --> Yahoo Finance / yfinance
        |                                      |
        +---------- map source fields <---------+
                           |
                           v
                    MySQL raw_* tables
                           |
                           v
             existing MySQL-derived datasets
```

See the [technical concept](docs/concept.md) for the proposed configuration,
worker responsibilities, raw table mappings, throttling behavior, database
boundaries, risks, and acceptance criteria. The `docs/` directory also contains
reference archives and small `yfinance` demonstrations; these are supporting
materials, not a runnable crawler.

## Current usage

There are no crawler commands or installation steps documented yet because
the application, dependency manifest, and runnable worker entry points have
not been implemented. `init.sh` is a workspace setup script, not a crawler
installer or launcher.

Before implementation or deployment, verify the target MySQL schema, unique
keys, triggers, and downstream SQL behavior. In particular, validate Yahoo
FX-pair direction and how the database expects FX rates to be stored. Do not
point an unverified ingestion process at production tables.

## Data-source and financial-use notes

This project is not investment advice and does not provide trading signals.
Yahoo Finance data can be incomplete, delayed, revised, or unavailable.
Review the applicable Yahoo Finance terms and your access rights before using
or redistributing data.

## License

This project is licensed under the [MIT License](LICENSE).