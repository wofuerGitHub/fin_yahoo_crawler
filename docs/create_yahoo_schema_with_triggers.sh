#!/usr/bin/env bash
# Create the Yahoo schema in the existing MySQL Docker container on host port 3311.
# Installs 10 requested tables + 5 trigger dependencies + all 16 triggers.
# Trigger SQL logic preserved from fmp.sql, with `fmp` SQL schema references changed to `yahoo`.
# Does not import data or stored procedures; MySQL 8.0.x is required.
# All table/trigger definitions are embedded from fmp.sql; fmp.sql is NOT needed to run.
# Existing table contents are preserved. Existing triggers with the 16 known names are replaced.
# Source: fmp.sql (dump made against MySQL 8.0.35).
set -euo pipefail

CONTAINER="${MYSQL_CONTAINER:-yahoo_db}"
HOST_PORT="${MYSQL_PORT:-3311}"
DB_USER="${MYSQL_USER:-root}"

if ! command -v docker >/dev/null 2>&1; then
  echo 'ERROR: Docker CLI not found.' >&2
  exit 1
fi

if [[ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || true)" != 'true' ]]; then
  echo "ERROR: Docker container '$CONTAINER' is not running." >&2
  exit 1
fi

PORT_BINDINGS="$(docker port "$CONTAINER" 3306/tcp 2>/dev/null || true)"
if ! printf '%s\n' "$PORT_BINDINGS" | grep -Eq ":${HOST_PORT}\$"; then
  echo "ERROR: '$CONTAINER' is not published on host port $HOST_PORT." >&2
  echo "Bindings: ${PORT_BINDINGS:-none}" >&2
  exit 1
fi

if [[ -z "${MYSQL_PWD:-}" ]]; then
  read -r -s -p "MySQL password for '$DB_USER': " MYSQL_PWD
  echo
fi
export MYSQL_PWD
trap 'unset MYSQL_PWD' EXIT

printf 'Connecting to container=%s, host port=%s, database=yahoo\n' "$CONTAINER" "$HOST_PORT"
printf 'Creating missing tables; reinstalling 16 triggers (no table data deleted).\n'

# Avoid using the password on the command line. Connect inside the Docker container.
RESULT="$(docker exec -i -e MYSQL_PWD "$CONTAINER" \
  mysql --user="$DB_USER" --default-character-set=utf8mb4 \
    --batch --skip-column-names <<'YAHOO_SQL'
CREATE DATABASE IF NOT EXISTS `yahoo`
  DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE `yahoo`;

-- Table: _reference_fx
CREATE TABLE IF NOT EXISTS `_reference_fx` (
  `symbol` varchar(255) NOT NULL,
  `currency` varchar(3) NOT NULL DEFAULT 'EUR',
  `active` tinyint NOT NULL DEFAULT '1',
  `longTimeSerie` tinyint NOT NULL DEFAULT '1',
  `stream` tinyint NOT NULL DEFAULT '1',
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`symbol`),
  UNIQUE KEY `symbol_UNIQUE` (`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: _reference_map
CREATE TABLE IF NOT EXISTS `_reference_map` (
  `symbol` varchar(255) NOT NULL,
  `symbol_fundamental` varchar(255) DEFAULT NULL,
  `isin` varchar(12) DEFAULT NULL,
  `currency` varchar(3) NOT NULL,
  `companyName` varchar(255) DEFAULT NULL,
  `industry` varchar(255) DEFAULT NULL,
  `sector` varchar(255) DEFAULT NULL,
  `country` varchar(255) DEFAULT NULL,
  `active` tinyint NOT NULL DEFAULT '1',
  `longTimeSerie` tinyint NOT NULL DEFAULT '1',
  `stream` tinyint NOT NULL DEFAULT '1',
  `comment` text,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`symbol`),
  UNIQUE KEY `symbol_UNIQUE` (`symbol`),
  UNIQUE KEY `isin_UNIQUE` (`isin`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='reference for all the time-series quotes and fundamentals to be queried and merged\n\nsymbol -> ts\nsymbol_fundamental -> fundamental\nactive -> if ts should be queried\nlongTimeSerie -> if ts should get 30y data\nstream -> if ts should get streamed';

-- Table: raw_assetslist
CREATE TABLE IF NOT EXISTS `raw_assetslist` (
  `symbol` varchar(255) NOT NULL,
  `name` mediumtext,
  `price` double DEFAULT NULL,
  `exchange` mediumtext,
  `exchangeShortName` mediumtext,
  `type` mediumtext,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`symbol`),
  UNIQUE KEY `symbol_UNIQUE` (`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: raw_companykeystats
CREATE TABLE IF NOT EXISTS `raw_companykeystats` (
  `symbol` varchar(255) NOT NULL,
  `price` double DEFAULT NULL,
  `beta` double DEFAULT NULL,
  `volAvg` bigint DEFAULT NULL,
  `mktCap` bigint DEFAULT NULL,
  `lastDiv` double DEFAULT NULL,
  `range` mediumtext,
  `changes` double DEFAULT NULL,
  `companyName` mediumtext,
  `currency` mediumtext,
  `cik` mediumtext,
  `isin` mediumtext,
  `cusip` mediumtext,
  `exchange` mediumtext,
  `exchangeShortName` mediumtext,
  `industry` mediumtext,
  `website` mediumtext,
  `description` mediumtext,
  `ceo` mediumtext,
  `sector` mediumtext,
  `country` mediumtext,
  `fullTimeEmployees` mediumtext,
  `phone` mediumtext,
  `address` mediumtext,
  `city` mediumtext,
  `state` mediumtext,
  `zip` mediumtext,
  `dcfDiff` mediumtext,
  `dcf` double DEFAULT NULL,
  `image` mediumtext,
  `ipoDate` mediumtext,
  `defaultImage` tinyint(1) DEFAULT NULL,
  `isEtf` tinyint(1) DEFAULT NULL,
  `isActivelyTrading` tinyint(1) DEFAULT NULL,
  `isAdr` tinyint(1) DEFAULT NULL,
  `isFund` tinyint(1) DEFAULT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`symbol`),
  UNIQUE KEY `symbol_UNIQUE` (`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: raw_fun_income
CREATE TABLE IF NOT EXISTS `raw_fun_income` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `reportedCurrency` varchar(3) NOT NULL,
  `cik` text,
  `fillingDate` text,
  `acceptedDate` text,
  `calendarYear` text,
  `period` text,
  `revenue` bigint DEFAULT NULL,
  `costOfRevenue` bigint DEFAULT NULL,
  `grossProfit` bigint DEFAULT NULL,
  `grossProfitRatio` double DEFAULT NULL,
  `researchAndDevelopmentExpenses` bigint DEFAULT NULL,
  `generalAndAdministrativeExpenses` double DEFAULT NULL,
  `sellingAndMarketingExpenses` double DEFAULT NULL,
  `sellingGeneralAndAdministrativeExpenses` bigint DEFAULT NULL,
  `otherExpenses` double DEFAULT NULL,
  `operatingExpenses` bigint DEFAULT NULL,
  `costAndExpenses` bigint DEFAULT NULL,
  `interestIncome` bigint DEFAULT NULL,
  `interestExpense` double DEFAULT NULL,
  `depreciationAndAmortization` bigint DEFAULT NULL,
  `ebitda` bigint DEFAULT NULL,
  `ebitdaratio` double DEFAULT NULL,
  `operatingIncome` bigint DEFAULT NULL,
  `operatingIncomeRatio` double DEFAULT NULL,
  `totalOtherIncomeExpensesNet` bigint DEFAULT NULL,
  `incomeBeforeTax` bigint DEFAULT NULL,
  `incomeBeforeTaxRatio` double DEFAULT NULL,
  `incomeTaxExpense` bigint DEFAULT NULL,
  `netIncome` bigint DEFAULT NULL,
  `netIncomeRatio` double DEFAULT NULL,
  `eps` double DEFAULT NULL,
  `epsdiluted` double DEFAULT NULL,
  `weightedAverageShsOut` bigint DEFAULT NULL,
  `weightedAverageShsOutDil` bigint DEFAULT NULL,
  `link` text,
  `finalLink` text,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`,`reportedCurrency`),
  UNIQUE KEY `UNIQUE` (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: raw_fun_cashflow
CREATE TABLE IF NOT EXISTS `raw_fun_cashflow` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `reportedCurrency` varchar(3) NOT NULL,
  `cik` text,
  `fillingDate` text,
  `acceptedDate` text,
  `calendarYear` text,
  `period` text,
  `netIncome` bigint DEFAULT NULL,
  `depreciationAndAmortization` bigint DEFAULT NULL,
  `deferredIncomeTax` bigint DEFAULT NULL,
  `stockBasedCompensation` bigint DEFAULT NULL,
  `changeInWorkingCapital` bigint DEFAULT NULL,
  `accountsReceivables` bigint DEFAULT NULL,
  `inventory` bigint DEFAULT NULL,
  `accountsPayables` bigint DEFAULT NULL,
  `otherWorkingCapital` bigint DEFAULT NULL,
  `otherNonCashItems` double DEFAULT NULL,
  `netCashProvidedByOperatingActivities` bigint DEFAULT NULL,
  `investmentsInPropertyPlantAndEquipment` bigint DEFAULT NULL,
  `acquisitionsNet` bigint DEFAULT NULL,
  `purchasesOfInvestments` bigint DEFAULT NULL,
  `salesMaturitiesOfInvestments` bigint DEFAULT NULL,
  `otherInvestingActivites` bigint DEFAULT NULL,
  `netCashUsedForInvestingActivites` bigint DEFAULT NULL,
  `debtRepayment` double DEFAULT NULL,
  `commonStockIssued` bigint DEFAULT NULL,
  `commonStockRepurchased` double DEFAULT NULL,
  `dividendsPaid` bigint DEFAULT NULL,
  `otherFinancingActivites` bigint DEFAULT NULL,
  `netCashUsedProvidedByFinancingActivities` bigint DEFAULT NULL,
  `effectOfForexChangesOnCash` double DEFAULT NULL,
  `netChangeInCash` bigint DEFAULT NULL,
  `cashAtEndOfPeriod` bigint DEFAULT NULL,
  `cashAtBeginningOfPeriod` bigint DEFAULT NULL,
  `operatingCashFlow` bigint DEFAULT NULL,
  `capitalExpenditure` bigint DEFAULT NULL,
  `freeCashFlow` bigint DEFAULT NULL,
  `link` text,
  `finalLink` text,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`,`reportedCurrency`),
  UNIQUE KEY `UNIQUE` (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: raw_fun_balance
CREATE TABLE IF NOT EXISTS `raw_fun_balance` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `reportedCurrency` varchar(3) NOT NULL,
  `cik` text,
  `fillingDate` text,
  `acceptedDate` text,
  `calendarYear` text,
  `period` text,
  `cashAndCashEquivalents` bigint DEFAULT NULL,
  `shortTermInvestments` bigint DEFAULT NULL,
  `cashAndShortTermInvestments` bigint DEFAULT NULL,
  `netReceivables` bigint DEFAULT NULL,
  `inventory` bigint DEFAULT NULL,
  `otherCurrentAssets` bigint DEFAULT NULL,
  `totalCurrentAssets` bigint DEFAULT NULL,
  `propertyPlantEquipmentNet` bigint DEFAULT NULL,
  `goodwill` double DEFAULT NULL,
  `intangibleAssets` double DEFAULT NULL,
  `goodwillAndIntangibleAssets` double DEFAULT NULL,
  `longTermInvestments` bigint DEFAULT NULL,
  `taxAssets` double DEFAULT NULL,
  `otherNonCurrentAssets` bigint DEFAULT NULL,
  `totalNonCurrentAssets` bigint DEFAULT NULL,
  `otherAssets` double DEFAULT NULL,
  `totalAssets` bigint DEFAULT NULL,
  `accountPayables` bigint DEFAULT NULL,
  `shortTermDebt` double DEFAULT NULL,
  `taxPayables` double DEFAULT NULL,
  `deferredRevenue` bigint DEFAULT NULL,
  `otherCurrentLiabilities` bigint DEFAULT NULL,
  `totalCurrentLiabilities` bigint DEFAULT NULL,
  `longTermDebt` double DEFAULT NULL,
  `deferredRevenueNonCurrent` double DEFAULT NULL,
  `deferredTaxLiabilitiesNonCurrent` double DEFAULT NULL,
  `otherNonCurrentLiabilities` bigint DEFAULT NULL,
  `totalNonCurrentLiabilities` bigint DEFAULT NULL,
  `otherLiabilities` double DEFAULT NULL,
  `capitalLeaseObligations` double DEFAULT NULL,
  `totalLiabilities` bigint DEFAULT NULL,
  `preferredStock` double DEFAULT NULL,
  `commonStock` bigint DEFAULT NULL,
  `retainedEarnings` bigint DEFAULT NULL,
  `accumulatedOtherComprehensiveIncomeLoss` bigint DEFAULT NULL,
  `othertotalStockholdersEquity` double DEFAULT NULL,
  `totalStockholdersEquity` bigint DEFAULT NULL,
  `totalLiabilitiesAndStockholdersEquity` bigint DEFAULT NULL,
  `minorityInterest` bigint DEFAULT NULL,
  `totalEquity` bigint DEFAULT NULL,
  `totalLiabilitiesAndTotalEquity` bigint DEFAULT NULL,
  `totalInvestments` bigint DEFAULT NULL,
  `totalDebt` double DEFAULT NULL,
  `netDebt` bigint DEFAULT NULL,
  `link` text,
  `finalLink` text,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`,`reportedCurrency`),
  UNIQUE KEY `UNIQUE` (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: raw_ts_fx
CREATE TABLE IF NOT EXISTS `raw_ts_fx` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `open` double DEFAULT NULL,
  `high` double DEFAULT NULL,
  `low` double DEFAULT NULL,
  `close` double NOT NULL,
  `currency` varchar(3) NOT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`),
  UNIQUE KEY `UNIQUE` (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='FX: raw data (in original currency) from yahoo\\\\n--> triggers update of eur_ts_fx';

-- Table: raw_ts_quote
CREATE TABLE IF NOT EXISTS `raw_ts_quote` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `open` double DEFAULT NULL,
  `high` double DEFAULT NULL,
  `low` double DEFAULT NULL,
  `close` double NOT NULL,
  `currency` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`),
  UNIQUE KEY `UNIQUE` (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='QUOTE: raw data (in original currency) from yahoo\\\\n--> triggers update of eur_ts_quote';

-- Table: raw_ts_quote_eps
CREATE TABLE IF NOT EXISTS `raw_ts_quote_eps` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `open` double DEFAULT NULL,
  `high` double DEFAULT NULL,
  `low` double DEFAULT NULL,
  `close` double NOT NULL,
  `eps` double DEFAULT NULL,
  `per` double GENERATED ALWAYS AS (if((`currency` = cast(_utf8mb4'GBp' as char charset binary)),if((`eps` <> 0),(`close` / (`eps` * 100)),NULL),if((`eps` <> 0),(`close` / `eps`),NULL))) STORED COMMENT '\nper (price-earning-ratio) is calculated and stored on the fly based on eps (earning-per-share) and close (price) [16.05.24]\nspecial treat of GBP and GBp for PER is encoded [16.05.24]',
  `currency` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`),
  UNIQUE KEY `UNIQUE` (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='QUOTE: raw data (in original currency) from yahoo\\n--> triggers update of eur_ts_quote';

-- Table: raw_fun
CREATE TABLE IF NOT EXISTS `raw_fun` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `currency` varchar(3) NOT NULL,
  `calendarYear` varchar(4) NOT NULL,
  `period` varchar(2) NOT NULL,
  `is_revenue` bigint DEFAULT NULL,
  `is_grossProfit` bigint DEFAULT NULL,
  `is_grossProfitRatio` double DEFAULT NULL,
  `is_researchAndDevelopmentExpenses` bigint DEFAULT NULL,
  `is_interestExpense` double DEFAULT NULL,
  `is_operatingIncome` bigint DEFAULT NULL,
  `is_netIncome` bigint DEFAULT NULL,
  `is_weightedAverageShsOut` bigint DEFAULT NULL,
  `cs_dividendsPaid` bigint DEFAULT NULL,
  `cs_operatingCashFlow` bigint DEFAULT NULL,
  `bs_totalStockholdersEquity` bigint DEFAULT NULL,
  `bs_preferredStock` bigint DEFAULT NULL,
  `is_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `cs_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `bs_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `grossProfitRatio` double GENERATED ALWAYS AS (if(((`is_revenue` is not null) and (`is_revenue` <> 0)),(`is_grossProfit` / `is_revenue`),NULL)) STORED,
  `researchAndDevelopmentRatio` double GENERATED ALWAYS AS (if(((`is_grossProfit` is not null) and (`is_grossProfit` <> 0)),(`is_researchAndDevelopmentExpenses` / `is_grossProfit`),NULL)) STORED,
  `interestExpenseRatio` double GENERATED ALWAYS AS (if(((`is_operatingIncome` is not null) and (`is_operatingIncome` <> 0)),(`is_interestExpense` / `is_operatingIncome`),NULL)) STORED,
  `interestRisk` tinyint GENERATED ALWAYS AS (if((`is_interestExpense` > `is_operatingIncome`),1,0)) STORED,
  `eps` double GENERATED ALWAYS AS (if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)) STORED COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)\n',
  `dps` double GENERATED ALWAYS AS (if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-(`cs_dividendsPaid`) / `is_weightedAverageShsOut`),NULL)) STORED COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\\n\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\\n\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\\n\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)',
  `cps` double GENERATED ALWAYS AS (if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)) STORED COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\\\\n\\n\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\\\\n\\n\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\\\\n\\n\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)',
  `bps` double GENERATED ALWAYS AS (if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity` - `bs_preferredStock`) / `is_weightedAverageShsOut`),NULL)) STORED COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\\\\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\\\\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\\\\n\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)',
  PRIMARY KEY (`date`,`symbol`,`currency`,`calendarYear`,`period`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: eur_fun
CREATE TABLE IF NOT EXISTS `eur_fun` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `calendarYear` text NOT NULL,
  `period` text NOT NULL,
  `grossProfitRatio` double DEFAULT NULL,
  `researchAndDevelopmentRatio` double DEFAULT NULL,
  `interestExpenseRatio` double DEFAULT NULL,
  `interestRisk` tinyint DEFAULT NULL,
  `eps` double DEFAULT NULL COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)\n',
  `dps` double DEFAULT NULL COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\\n\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\\n\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\\n\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)',
  `cps` double DEFAULT NULL COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\\\\n\\n\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\\\\n\\n\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\\\\n\\n\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)',
  `bps` double DEFAULT NULL COMMENT 'eps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`is_netIncome` / `is_weightedAverageShsOut`),NULL)\\\\ndps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(-`cs_dividendsPaid` / `is_weightedAverageShsOut`),NULL)\\\\ncps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),(`cs_operatingCashFlow` / `is_weightedAverageShsOut`),NULL)\\\\n\nbps: if(((`is_weightedAverageShsOut` is not null) and (`is_weightedAverageShsOut` >= 1)),((`bs_totalStockholdersEquity`-bs_preferredStock) / `is_weightedAverageShsOut`),NULL)',
  `currency` varchar(3) DEFAULT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `manual` text,
  PRIMARY KEY (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: eur_companykeystats
CREATE TABLE IF NOT EXISTS `eur_companykeystats` (
  `symbol` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `price` double DEFAULT NULL,
  `mktCap` double DEFAULT NULL,
  `lastDiv` double DEFAULT NULL,
  `min` double DEFAULT NULL,
  `max` double DEFAULT NULL,
  `range` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci GENERATED ALWAYS AS (concat(format(`min`,3),_utf8mb4'-',format(`max`,3))) STORED,
  `companyName` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `currency` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `isin` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `exchange` mediumtext,
  `exchangeShortName` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `industry` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `website` mediumtext,
  `description` mediumtext,
  `ceo` mediumtext,
  `sector` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `country` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci,
  `fullTimeEmployees` mediumtext,
  `phone` mediumtext,
  `address` mediumtext,
  `city` mediumtext,
  `state` mediumtext,
  `zip` mediumtext,
  `image` mediumtext,
  `ipoDate` mediumtext,
  `defaultImage` tinyint(1) DEFAULT NULL,
  `isEtf` tinyint(1) DEFAULT NULL,
  `isActivelyTrading` tinyint(1) DEFAULT NULL,
  `isAdr` tinyint(1) DEFAULT NULL,
  `isFund` tinyint(1) DEFAULT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`symbol`),
  UNIQUE KEY `symbol_UNIQUE` (`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: eur_ts_fx
CREATE TABLE IF NOT EXISTS `eur_ts_fx` (
  `date` date NOT NULL,
  `symbol` varchar(255) NOT NULL,
  `open` double DEFAULT NULL,
  `high` double DEFAULT NULL,
  `low` double DEFAULT NULL,
  `close` double NOT NULL,
  `currency` varchar(3) NOT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='FX: data (in EUR) from raw_ts_fx';

-- Table: eur_ts_quote
CREATE TABLE IF NOT EXISTS `eur_ts_quote` (
  `date` date NOT NULL,
  `symbol` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `open` double DEFAULT NULL,
  `high` double DEFAULT NULL,
  `low` double DEFAULT NULL,
  `close` double NOT NULL,
  `eps` double GENERATED ALWAYS AS (if((`per` is not null),(`close` / `per`),NULL)) STORED,
  `per` double DEFAULT NULL,
  `currency` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`date`,`symbol`),
  KEY `ix_symbol_date` (`symbol`,`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='QUOTE: data (in EUR) from raw_ts_quote and eur_ts_fx';

-- Trigger: raw_companykeystats_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_companykeystats_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_companykeystats_AFTER_INSERT` AFTER INSERT ON `raw_companykeystats` FOR EACH ROW BEGIN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			END IF;
		END IF;
        /*
        BLOCK BEGIN
        */
		SET @min_range = IF(SUBSTRING_INDEX(new.`range`,'-', 1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', 1), NULL);
		SET @max_range = IF(SUBSTRING_INDEX(new.`range`,'-', -1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', -1), NULL);
        SET @mktCap = new.`mktCap`/1000000000;
    	
		IF @fx IS NOT NULL THEN
			INSERT INTO `yahoo`.`eur_companykeystats` (`symbol`, `price`, `mktCap`, `min`, `max`, `lastDiv`, `companyName`, `currency`, `isin`,
            `exchange`, `exchangeShortName`, `industry`, `website`, `description`, `ceo`, `sector`, `country`, `fullTimeEmployees`, `phone`, `address`, `city`, `state`, `zip`, `image`, `ipoDate`, `defaultImage`, `isEtf`, `isActivelyTrading`, `isAdr`, `isFund`,
            `updated`)
			VALUES (new.`symbol`, new.`price`/@fx, @mktCap/@fx, @min_range/@fx, @max_range/@fx, new.`lastDiv`/@fx, new.`companyName`, 'EUR', new.`isin`, 
            new.`exchange`, new.`exchangeShortName`, new.`industry`, new.`website`, new.`description`, new.`ceo`, new.`sector`, new.`country`, new.`fullTimeEmployees`, new.`phone`, new.`address`, new.`city`, new.`state`, new.`zip`, new.`image`, new.`ipoDate`, new.`defaultImage`, new.`isEtf`, new.`isActivelyTrading`, new.`isAdr`, new.`isFund`,
            new.`updated`)
			ON DUPLICATE KEY UPDATE `price` = new.`price`/@fx, `mktCap` = @mktCap/@fx, `min` = @min_range/@fx, `max` = @max_range/@fx, `lastDiv` = new.`lastDiv`/@fx, `companyName` = new.`companyName`, `currency` = 'EUR', `isin` = new.`isin`, 
            `exchange` = new.`exchange`, `exchangeShortName` = new.`exchangeShortName`, `industry` = new.`industry`, `website` = new.`website`, `description` = new.`description`, `ceo` = new.`ceo`, 
            `sector` = new.`sector`, `country` = new.`country`, `fullTimeEmployees` = new.`fullTimeEmployees`, `phone` = new.`phone`, `address` = new.`address`, `city` = new.`city`, `state` = new.`state`, 
            `zip` = new.`zip`, `image` = new.`image`, `ipoDate` = new.`ipoDate`, `defaultImage` = new.`defaultImage`, `isEtf` = new.`isEtf`, `isActivelyTrading` = new.`isActivelyTrading`, 
            `isAdr` = new.`isAdr`, `isFund` = new.`isFund`, `updated` = new.`updated`;
		END IF; 
        /*
        BLOCK END
        */
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_companykeystats_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_companykeystats_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_companykeystats_AFTER_UPDATE` AFTER UPDATE ON `raw_companykeystats` FOR EACH ROW BEGIN
    IF (OLD.`updated` <> NEW.`updated`) THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			END IF;
		END IF;
        /*
        BLOCK BEGIN
        */
		SET @min_range = IF(SUBSTRING_INDEX(new.`range`,'-', 1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', 1), NULL);
		SET @max_range = IF(SUBSTRING_INDEX(new.`range`,'-', -1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', -1), NULL);
        SET @mktCap = new.`mktCap`/1000000000;
    	
		IF @fx IS NOT NULL THEN
			INSERT INTO `yahoo`.`eur_companykeystats` (`symbol`, `price`, `mktCap`, `min`, `max`, `lastDiv`, `companyName`, `currency`, `isin`,
            `exchange`, `exchangeShortName`, `industry`, `website`, `description`, `ceo`, `sector`, `country`, `fullTimeEmployees`, `phone`, `address`, `city`, `state`, `zip`, `image`, `ipoDate`, `defaultImage`, `isEtf`, `isActivelyTrading`, `isAdr`, `isFund`,
            `updated`)
			VALUES (new.`symbol`, new.`price`/@fx, @mktCap/@fx, @min_range/@fx, @max_range/@fx, new.`lastDiv`/@fx, new.`companyName`, 'EUR', new.`isin`, 
            new.`exchange`, new.`exchangeShortName`, new.`industry`, new.`website`, new.`description`, new.`ceo`, new.`sector`, new.`country`, new.`fullTimeEmployees`, new.`phone`, new.`address`, new.`city`, new.`state`, new.`zip`, new.`image`, new.`ipoDate`, new.`defaultImage`, new.`isEtf`, new.`isActivelyTrading`, new.`isAdr`, new.`isFund`,
            new.`updated`)
			ON DUPLICATE KEY UPDATE `price` = new.`price`/@fx, `mktCap` = @mktCap/@fx, `min` = @min_range/@fx, `max` = @max_range/@fx, `lastDiv` = new.`lastDiv`/@fx, `companyName` = new.`companyName`, `currency` = 'EUR', `isin` = new.`isin`, 
            `exchange` = new.`exchange`, `exchangeShortName` = new.`exchangeShortName`, `industry` = new.`industry`, `website` = new.`website`, `description` = new.`description`, `ceo` = new.`ceo`, 
            `sector` = new.`sector`, `country` = new.`country`, `fullTimeEmployees` = new.`fullTimeEmployees`, `phone` = new.`phone`, `address` = new.`address`, `city` = new.`city`, `state` = new.`state`, 
            `zip` = new.`zip`, `image` = new.`image`, `ipoDate` = new.`ipoDate`, `defaultImage` = new.`defaultImage`, `isEtf` = new.`isEtf`, `isActivelyTrading` = new.`isActivelyTrading`, 
            `isAdr` = new.`isAdr`, `isFund` = new.`isFund`, `updated` = new.`updated`;
		END IF; 
        /*
        BLOCK END
        */   
    END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_fun_AFTER_INSERT` AFTER INSERT ON `raw_fun` FOR EACH ROW BEGIN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
		IF @fx IS NOT NULL THEN
			INSERT INTO `yahoo`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `eps`, `dps`, `cps`, `bps`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`eps`/@fx, new.`dps`/@fx, new.`cps`/@fx, new.`bps`/@fx, 'EUR', GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`,  `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `eps` = new.`eps`/@fx, `dps` = new.`dps`/@fx, `cps` = new.`cps`/@fx, `bps` = new.`bps`/@fx, `currency` = 'EUR', `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);
		ELSE
			INSERT INTO `yahoo`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`currency`, GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`is_grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`, `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `currency` = new.`currency`, `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);        
		END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_fun_AFTER_UPDATE` AFTER UPDATE ON `raw_fun` FOR EACH ROW BEGIN
    IF (OLD.`is_updated` <> NEW.`is_updated`) OR (OLD.`cs_updated` <> NEW.`cs_updated`) OR (OLD.`bs_updated` <> NEW.`bs_updated`) THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
		IF @fx IS NOT NULL THEN
			INSERT INTO `yahoo`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `eps`, `dps`, `cps`, `bps`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`eps`/@fx, new.`dps`/@fx, new.`cps`/@fx, new.`bps`/@fx, 'EUR', GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`,  `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `eps` = new.`eps`/@fx, `dps` = new.`dps`/@fx, `cps` = new.`cps`/@fx, `bps` = new.`bps`/@fx, `currency` = 'EUR', `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);
		ELSE
			INSERT INTO `yahoo`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`currency`, GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`is_grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`, `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `currency` = new.`currency`, `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);        
		END IF; 
    END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_balance_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_balance_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_fun_balance_AFTER_INSERT` AFTER INSERT ON `raw_fun_balance` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `bs_totalStockholdersEquity`, `bs_preferredStock`, `bs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`totalStockholdersEquity`, new.`preferredStock`, new.`updated`)
	ON DUPLICATE KEY UPDATE `bs_totalStockholdersEquity` = new.`totalStockholdersEquity`, `bs_preferredStock` = new.`preferredStock`, `bs_updated` =  new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_balance_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_balance_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_fun_balance_AFTER_UPDATE` AFTER UPDATE ON `raw_fun_balance` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `bs_totalStockholdersEquity`, `bs_preferredStock`, `bs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`totalStockholdersEquity`, new.`preferredStock`, new.`updated`)
	ON DUPLICATE KEY UPDATE `bs_totalStockholdersEquity` = new.`totalStockholdersEquity`, `bs_preferredStock` = new.`preferredStock`, `bs_updated` =  new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_cashflow_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_cashflow_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_fun_cashflow_AFTER_INSERT` AFTER INSERT ON `raw_fun_cashflow` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `cs_dividendsPaid`, `cs_operatingCashFlow`, `cs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`dividendsPaid`, new.`operatingCashFlow`, new.`updated`)
	ON DUPLICATE KEY UPDATE `cs_dividendsPaid` = new.`dividendsPaid`, `cs_operatingCashFlow` = new.`operatingCashFlow`, `cs_updated` =  new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_cashflow_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_cashflow_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_fun_cashflow_AFTER_UPDATE` AFTER UPDATE ON `raw_fun_cashflow` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `cs_dividendsPaid`, `cs_operatingCashFlow`, `cs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`dividendsPaid`, new.`operatingCashFlow`, new.`updated`)
	ON DUPLICATE KEY UPDATE `cs_dividendsPaid` = new.`dividendsPaid`, `cs_operatingCashFlow` = new.`operatingCashFlow`, `cs_updated` =  new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_income_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_income_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_fun_income_AFTER_INSERT` AFTER INSERT ON `raw_fun_income` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `is_revenue`, `is_grossProfit`, `is_grossProfitRatio`, `is_researchAndDevelopmentExpenses`,`is_interestExpense`,`is_operatingIncome`,`is_netIncome`, `is_weightedAverageShsOut`, `is_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`revenue`, new.`grossProfit`, new.`grossProfitRatio`, new.`researchAndDevelopmentExpenses`,new.`interestExpense`,new.`operatingIncome`, new.`netIncome`, new.`weightedAverageShsOut`, new.`updated`)
	ON DUPLICATE KEY UPDATE `is_revenue` = new.`revenue`, `is_grossProfit` = new.`grossProfit`, `is_grossProfitRatio` = new.`grossProfitRatio`, `is_researchAndDevelopmentExpenses` = new.`researchAndDevelopmentExpenses`,`is_interestExpense`= new.`interestExpense`,`is_operatingIncome`= new.`operatingIncome`, `is_netIncome` = new.`netIncome`, `is_weightedAverageShsOut` = new.`weightedAverageShsOut`, `is_updated` =  new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_fun_income_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_fun_income_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_fun_income_AFTER_UPDATE` AFTER UPDATE ON `raw_fun_income` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `is_revenue`, `is_grossProfit`, `is_grossProfitRatio`, `is_researchAndDevelopmentExpenses`,`is_interestExpense`,`is_operatingIncome`,`is_netIncome`, `is_weightedAverageShsOut`, `is_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`revenue`, new.`grossProfit`, new.`grossProfitRatio`, new.`researchAndDevelopmentExpenses`,new.`interestExpense`,new.`operatingIncome`, new.`netIncome`, new.`weightedAverageShsOut`, new.`updated`)
	ON DUPLICATE KEY UPDATE `is_revenue` = new.`revenue`, `is_grossProfit` = new.`grossProfit`, `is_grossProfitRatio` = new.`grossProfitRatio`, `is_researchAndDevelopmentExpenses` = new.`researchAndDevelopmentExpenses`,`is_interestExpense`= new.`interestExpense`,`is_operatingIncome`= new.`operatingIncome`, `is_netIncome` = new.`netIncome`, `is_weightedAverageShsOut` = new.`weightedAverageShsOut`, `is_updated` =  new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_ts_fx_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_ts_fx_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_ts_fx_AFTER_INSERT` AFTER INSERT ON `raw_ts_fx` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`, new.`high`, new.`low`, new.`close`, new.`currency`, new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`, `high` = new.`high`, `low` = new.`low`, `close` = new.`close`, `currency` = new.`currency`, `updated` = new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_ts_fx_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_ts_fx_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_ts_fx_AFTER_UPDATE` AFTER UPDATE ON `raw_ts_fx` FOR EACH ROW BEGIN
	INSERT INTO `yahoo`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`, new.`high`, new.`low`, new.`close`, new.`currency`, new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`, `high` = new.`high`, `low` = new.`low`, `close` = new.`close`, `currency` = new.`currency`, `updated` = new.`updated`;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_ts_quote_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_ts_quote_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_ts_quote_AFTER_INSERT` AFTER INSERT ON `raw_ts_quote` FOR EACH ROW BEGIN
	IF new.`currency` = 'EUR' THEN
		SET @fx = 1;
	ELSE
		IF new.`currency` = BINARY 'GBp' THEN
			SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		ELSEIF new.`currency` <> BINARY 'GBp' THEN 
			SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		END IF;
	END IF;
	IF @fx IS NOT NULL THEN
		INSERT INTO `yahoo`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
		VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, 'EUR', new.`updated`)
		ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `updated` = new.`updated`;
    END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_ts_quote_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_ts_quote_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_ts_quote_AFTER_UPDATE` AFTER UPDATE ON `raw_ts_quote` FOR EACH ROW BEGIN
    IF OLD.`updated` <> NEW.`updated` THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
        IF @fx IS NOT NULL THEN
			INSERT INTO `yahoo`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, 'EUR', new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `updated` = new.`updated`;
        END IF;
    END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_ts_quote_eps_AFTER_INSERT
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_ts_quote_eps_AFTER_INSERT`;
DELIMITER $$
CREATE TRIGGER `raw_ts_quote_eps_AFTER_INSERT` AFTER INSERT ON `raw_ts_quote_eps` FOR EACH ROW BEGIN
	IF new.`currency` = 'EUR' THEN
		SET @fx = 1;
	ELSE
		IF new.`currency` = BINARY 'GBp' THEN
			SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		ELSEIF new.`currency` <> BINARY 'GBp' THEN 
			SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		END IF;
	END IF;
	IF @fx IS NOT NULL THEN
		INSERT INTO `yahoo`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `per`, `currency`, `updated`)
		VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, new.`per`, 'EUR', new.`updated`)
		ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `per` = new.`per`, `updated` = new.`updated`;
    END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Trigger: raw_ts_quote_eps_AFTER_UPDATE
-- Preserve the SQL mode from the original MySQL dump.
SET @yahoo_previous_sql_mode = @@SESSION.sql_mode;
SET SESSION sql_mode = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DROP TRIGGER IF EXISTS `raw_ts_quote_eps_AFTER_UPDATE`;
DELIMITER $$
CREATE TRIGGER `raw_ts_quote_eps_AFTER_UPDATE` AFTER UPDATE ON `raw_ts_quote_eps` FOR EACH ROW BEGIN
    IF OLD.`updated` <> NEW.`updated` THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `yahoo`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
		IF @fx IS NOT NULL THEN
			INSERT INTO `yahoo`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `per`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, new.`per`, 'EUR', new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `per` = new.`per`, `updated` = new.`updated`;
		END IF;        
    END IF;
END$$
DELIMITER ;
SET SESSION sql_mode = @yahoo_previous_sql_mode;

-- Confirm required tables and triggers are present in the intended schema.
SELECT
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_SCHEMA='yahoo' AND TABLE_TYPE='BASE TABLE'
   AND TABLE_NAME IN ('_reference_fx', '_reference_map', 'raw_assetslist', 'raw_companykeystats', 'raw_fun_income', 'raw_fun_cashflow', 'raw_fun_balance', 'raw_ts_fx', 'raw_ts_quote', 'raw_ts_quote_eps', 'raw_fun', 'eur_fun', 'eur_companykeystats', 'eur_ts_fx', 'eur_ts_quote')),
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS
   WHERE TRIGGER_SCHEMA='yahoo'
   AND TRIGGER_NAME IN ('raw_companykeystats_AFTER_INSERT', 'raw_companykeystats_AFTER_UPDATE', 'raw_fun_AFTER_INSERT', 'raw_fun_AFTER_UPDATE', 'raw_fun_balance_AFTER_INSERT', 'raw_fun_balance_AFTER_UPDATE', 'raw_fun_cashflow_AFTER_INSERT', 'raw_fun_cashflow_AFTER_UPDATE', 'raw_fun_income_AFTER_INSERT', 'raw_fun_income_AFTER_UPDATE', 'raw_ts_fx_AFTER_INSERT', 'raw_ts_fx_AFTER_UPDATE', 'raw_ts_quote_AFTER_INSERT', 'raw_ts_quote_AFTER_UPDATE', 'raw_ts_quote_eps_AFTER_INSERT', 'raw_ts_quote_eps_AFTER_UPDATE')),
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS
   WHERE TRIGGER_SCHEMA='yahoo' AND ACTION_STATEMENT LIKE '%fmp%');
YAHOO_SQL
)"

read -r TABLE_COUNT TRIGGER_COUNT OLD_REF_COUNT <<< "$RESULT"
if [[ "$TABLE_COUNT" != '15' || "$TRIGGER_COUNT" != '16' || "$OLD_REF_COUNT" != '0' ]]; then
  echo "ERROR: Validation failed. Found ${TABLE_COUNT:-?}/15 tables, ${TRIGGER_COUNT:-?}/16 triggers, ${OLD_REF_COUNT:-?} old FMP references." >&2
  exit 1
fi

echo 'SUCCESS: yahoo schema has 15 required tables and 16 adapted triggers.'
echo "Inspect: docker exec -it $CONTAINER mysql -u $DB_USER -p -e 'SHOW TRIGGERS FROM yahoo;'"
