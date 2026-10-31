CREATE DATABASE  IF NOT EXISTS `fmp` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `fmp`;
-- MySQL dump 10.13  Distrib 8.0.42, for macos15 (arm64)
--
-- Host: localhost    Database: fmp
-- ------------------------------------------------------
-- Server version	8.0.35

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `_function_log`
--

DROP TABLE IF EXISTS `_function_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_function_log` (
  `function` varchar(255) NOT NULL,
  `last_execution_time` datetime NOT NULL,
  PRIMARY KEY (`function`),
  UNIQUE KEY `function_UNIQUE` (`function`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='document the last execution of stored procedures';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `_reference_fx`
--

DROP TABLE IF EXISTS `_reference_fx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_reference_fx` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `_reference_map`
--

DROP TABLE IF EXISTS `_reference_map`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_reference_map` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `eur_companykeystats`
--

DROP TABLE IF EXISTS `eur_companykeystats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eur_companykeystats` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `eur_fun`
--

DROP TABLE IF EXISTS `eur_fun`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eur_fun` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `eur_ts_fx`
--

DROP TABLE IF EXISTS `eur_ts_fx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eur_ts_fx` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `eur_ts_quote`
--

DROP TABLE IF EXISTS `eur_ts_quote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eur_ts_quote` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `find_missing_fx`
--

DROP TABLE IF EXISTS `find_missing_fx`;
/*!50001 DROP VIEW IF EXISTS `find_missing_fx`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `find_missing_fx` AS SELECT 
 1 AS `date`,
 1 AS `currency`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `fundamental_advanced`
--

DROP TABLE IF EXISTS `fundamental_advanced`;
/*!50001 DROP VIEW IF EXISTS `fundamental_advanced`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `fundamental_advanced` AS SELECT 
 1 AS `date`,
 1 AS `symbol`,
 1 AS `calendarYear`,
 1 AS `period`,
 1 AS `grossProfitRatio`,
 1 AS `researchAndDevelopmentRatio`,
 1 AS `interestExpenseRatio`,
 1 AS `interestRisk`,
 1 AS `created`,
 1 AS `updated`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `fundamental_basic`
--

DROP TABLE IF EXISTS `fundamental_basic`;
/*!50001 DROP VIEW IF EXISTS `fundamental_basic`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `fundamental_basic` AS SELECT 
 1 AS `date`,
 1 AS `symbol`,
 1 AS `calendarYear`,
 1 AS `period`,
 1 AS `eps`,
 1 AS `dps`,
 1 AS `cps`,
 1 AS `bps`,
 1 AS `currency`,
 1 AS `created`,
 1 AS `updated`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `object_documentation`
--

DROP TABLE IF EXISTS `object_documentation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `object_documentation` (
  `object_schema` varchar(64) NOT NULL,
  `object_name` varchar(64) NOT NULL,
  `object_type` enum('TABLE','VIEW','PROCEDURE','FUNCTION') NOT NULL,
  `purpose` text NOT NULL,
  `grain` text,
  `source` text,
  `lifecycle` text,
  `notes` text,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`object_schema`,`object_name`,`object_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Stores business and technical documentation for database objects';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `raw_assetslist`
--

DROP TABLE IF EXISTS `raw_assetslist`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_assetslist` (
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
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `raw_companykeystats`
--

DROP TABLE IF EXISTS `raw_companykeystats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_companykeystats` (
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
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_companykeystats_AFTER_INSERT` AFTER INSERT ON `raw_companykeystats` FOR EACH ROW BEGIN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			END IF;
		END IF;
        /*
        BLOCK BEGIN
        */
		SET @min_range = IF(SUBSTRING_INDEX(new.`range`,'-', 1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', 1), NULL);
		SET @max_range = IF(SUBSTRING_INDEX(new.`range`,'-', -1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', -1), NULL);
        SET @mktCap = new.`mktCap`/1000000000;
    	
		IF @fx IS NOT NULL THEN
			INSERT INTO `fmp`.`eur_companykeystats` (`symbol`, `price`, `mktCap`, `min`, `max`, `lastDiv`, `companyName`, `currency`, `isin`,
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_companykeystats_AFTER_UPDATE` AFTER UPDATE ON `raw_companykeystats` FOR EACH ROW BEGIN
    IF (OLD.`updated` <> NEW.`updated`) THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` where `symbol` = new.`currency` order by date desc limit 1);
			END IF;
		END IF;
        /*
        BLOCK BEGIN
        */
		SET @min_range = IF(SUBSTRING_INDEX(new.`range`,'-', 1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', 1), NULL);
		SET @max_range = IF(SUBSTRING_INDEX(new.`range`,'-', -1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(new.`range`,'-', -1), NULL);
        SET @mktCap = new.`mktCap`/1000000000;
    	
		IF @fx IS NOT NULL THEN
			INSERT INTO `fmp`.`eur_companykeystats` (`symbol`, `price`, `mktCap`, `min`, `max`, `lastDiv`, `companyName`, `currency`, `isin`,
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
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_fun`
--

DROP TABLE IF EXISTS `raw_fun`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_fun` (
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
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_AFTER_INSERT` AFTER INSERT ON `raw_fun` FOR EACH ROW BEGIN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
		IF @fx IS NOT NULL THEN
			INSERT INTO `fmp`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `eps`, `dps`, `cps`, `bps`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`eps`/@fx, new.`dps`/@fx, new.`cps`/@fx, new.`bps`/@fx, 'EUR', GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`,  `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `eps` = new.`eps`/@fx, `dps` = new.`dps`/@fx, `cps` = new.`cps`/@fx, `bps` = new.`bps`/@fx, `currency` = 'EUR', `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);
		ELSE
			INSERT INTO `fmp`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`currency`, GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`is_grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`, `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `currency` = new.`currency`, `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);        
		END IF; 
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_AFTER_UPDATE` AFTER UPDATE ON `raw_fun` FOR EACH ROW BEGIN
    IF (OLD.`is_updated` <> NEW.`is_updated`) OR (OLD.`cs_updated` <> NEW.`cs_updated`) OR (OLD.`bs_updated` <> NEW.`bs_updated`) THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
		IF @fx IS NOT NULL THEN
			INSERT INTO `fmp`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `eps`, `dps`, `cps`, `bps`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`eps`/@fx, new.`dps`/@fx, new.`cps`/@fx, new.`bps`/@fx, 'EUR', GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`,  `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `eps` = new.`eps`/@fx, `dps` = new.`dps`/@fx, `cps` = new.`cps`/@fx, `bps` = new.`bps`/@fx, `currency` = 'EUR', `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);
		ELSE
			INSERT INTO `fmp`.`eur_fun` (`date`, `symbol`, `calendarYear`, `period`, `grossProfitRatio`, `researchAndDevelopmentRatio`, `interestExpenseRatio`, `interestRisk`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`, new.`calendarYear`, new.`period`, new.`grossProfitRatio`, new.`researchAndDevelopmentRatio`, new.`interestExpenseRatio`, new.`interestRisk`, new.`currency`, GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`))
			ON DUPLICATE KEY UPDATE `calendarYear` = new.`calendarYear`, `period` = new.`period`, `grossProfitRatio` = new.`is_grossProfitRatio`, `researchAndDevelopmentRatio` = new.`researchAndDevelopmentRatio`, `interestExpenseRatio` = new.`interestExpenseRatio`, `interestRisk` = new.`interestRisk`, `currency` = new.`currency`, `updated` = GREATEST(new.`is_updated`, new.`cs_updated`, new.`bs_updated`);        
		END IF; 
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_fun_balance`
--

DROP TABLE IF EXISTS `raw_fun_balance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_fun_balance` (
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
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_balance_AFTER_INSERT` AFTER INSERT ON `raw_fun_balance` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `bs_totalStockholdersEquity`, `bs_preferredStock`, `bs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`totalStockholdersEquity`, new.`preferredStock`, new.`updated`)
	ON DUPLICATE KEY UPDATE `bs_totalStockholdersEquity` = new.`totalStockholdersEquity`, `bs_preferredStock` = new.`preferredStock`, `bs_updated` =  new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_balance_AFTER_UPDATE` AFTER UPDATE ON `raw_fun_balance` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `bs_totalStockholdersEquity`, `bs_preferredStock`, `bs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`totalStockholdersEquity`, new.`preferredStock`, new.`updated`)
	ON DUPLICATE KEY UPDATE `bs_totalStockholdersEquity` = new.`totalStockholdersEquity`, `bs_preferredStock` = new.`preferredStock`, `bs_updated` =  new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_fun_cashflow`
--

DROP TABLE IF EXISTS `raw_fun_cashflow`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_fun_cashflow` (
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
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_cashflow_AFTER_INSERT` AFTER INSERT ON `raw_fun_cashflow` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `cs_dividendsPaid`, `cs_operatingCashFlow`, `cs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`dividendsPaid`, new.`operatingCashFlow`, new.`updated`)
	ON DUPLICATE KEY UPDATE `cs_dividendsPaid` = new.`dividendsPaid`, `cs_operatingCashFlow` = new.`operatingCashFlow`, `cs_updated` =  new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_cashflow_AFTER_UPDATE` AFTER UPDATE ON `raw_fun_cashflow` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `cs_dividendsPaid`, `cs_operatingCashFlow`, `cs_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`dividendsPaid`, new.`operatingCashFlow`, new.`updated`)
	ON DUPLICATE KEY UPDATE `cs_dividendsPaid` = new.`dividendsPaid`, `cs_operatingCashFlow` = new.`operatingCashFlow`, `cs_updated` =  new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_fun_income`
--

DROP TABLE IF EXISTS `raw_fun_income`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_fun_income` (
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
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_income_AFTER_INSERT` AFTER INSERT ON `raw_fun_income` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `is_revenue`, `is_grossProfit`, `is_grossProfitRatio`, `is_researchAndDevelopmentExpenses`,`is_interestExpense`,`is_operatingIncome`,`is_netIncome`, `is_weightedAverageShsOut`, `is_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`revenue`, new.`grossProfit`, new.`grossProfitRatio`, new.`researchAndDevelopmentExpenses`,new.`interestExpense`,new.`operatingIncome`, new.`netIncome`, new.`weightedAverageShsOut`, new.`updated`)
	ON DUPLICATE KEY UPDATE `is_revenue` = new.`revenue`, `is_grossProfit` = new.`grossProfit`, `is_grossProfitRatio` = new.`grossProfitRatio`, `is_researchAndDevelopmentExpenses` = new.`researchAndDevelopmentExpenses`,`is_interestExpense`= new.`interestExpense`,`is_operatingIncome`= new.`operatingIncome`, `is_netIncome` = new.`netIncome`, `is_weightedAverageShsOut` = new.`weightedAverageShsOut`, `is_updated` =  new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_fun_income_AFTER_UPDATE` AFTER UPDATE ON `raw_fun_income` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`raw_fun` (`date`, `symbol`, `currency`, `calendarYear`, `period`, `is_revenue`, `is_grossProfit`, `is_grossProfitRatio`, `is_researchAndDevelopmentExpenses`,`is_interestExpense`,`is_operatingIncome`,`is_netIncome`, `is_weightedAverageShsOut`, `is_updated`)
	VALUES (new.`date`, new.`symbol`, new.`reportedCurrency`, new.`calendarYear`, new.`period`, new.`revenue`, new.`grossProfit`, new.`grossProfitRatio`, new.`researchAndDevelopmentExpenses`,new.`interestExpense`,new.`operatingIncome`, new.`netIncome`, new.`weightedAverageShsOut`, new.`updated`)
	ON DUPLICATE KEY UPDATE `is_revenue` = new.`revenue`, `is_grossProfit` = new.`grossProfit`, `is_grossProfitRatio` = new.`grossProfitRatio`, `is_researchAndDevelopmentExpenses` = new.`researchAndDevelopmentExpenses`,`is_interestExpense`= new.`interestExpense`,`is_operatingIncome`= new.`operatingIncome`, `is_netIncome` = new.`netIncome`, `is_weightedAverageShsOut` = new.`weightedAverageShsOut`, `is_updated` =  new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_ts_fx`
--

DROP TABLE IF EXISTS `raw_ts_fx`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_ts_fx` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='FX: raw data (in original currency) from fmp\\\\n--> triggers update of eur_ts_fx';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `raw_ts_fx_AFTER_INSERT` AFTER INSERT ON `raw_ts_fx` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`, new.`high`, new.`low`, new.`close`, new.`currency`, new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`, `high` = new.`high`, `low` = new.`low`, `close` = new.`close`, `currency` = new.`currency`, `updated` = new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `raw_ts_fx_AFTER_UPDATE` AFTER UPDATE ON `raw_ts_fx` FOR EACH ROW BEGIN
	INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`, new.`high`, new.`low`, new.`close`, new.`currency`, new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`, `high` = new.`high`, `low` = new.`low`, `close` = new.`close`, `currency` = new.`currency`, `updated` = new.`updated`;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_ts_quote`
--

DROP TABLE IF EXISTS `raw_ts_quote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_ts_quote` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='QUOTE: raw data (in original currency) from fmp\\\\n--> triggers update of eur_ts_quote';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `raw_ts_quote_AFTER_INSERT` AFTER INSERT ON `raw_ts_quote` FOR EACH ROW BEGIN
	IF new.`currency` = 'EUR' THEN
		SET @fx = 1;
	ELSE
		IF new.`currency` = BINARY 'GBp' THEN
			SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		ELSEIF new.`currency` <> BINARY 'GBp' THEN 
			SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		END IF;
	END IF;
	IF @fx IS NOT NULL THEN
		INSERT INTO `fmp`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
		VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, 'EUR', new.`updated`)
		ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `updated` = new.`updated`;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `raw_ts_quote_AFTER_UPDATE` AFTER UPDATE ON `raw_ts_quote` FOR EACH ROW BEGIN
    IF OLD.`updated` <> NEW.`updated` THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
        IF @fx IS NOT NULL THEN
			INSERT INTO `fmp`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, 'EUR', new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `updated` = new.`updated`;
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `raw_ts_quote_eps`
--

DROP TABLE IF EXISTS `raw_ts_quote_eps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `raw_ts_quote_eps` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='QUOTE: raw data (in original currency) from fmp\\n--> triggers update of eur_ts_quote';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_ts_quote_eps_AFTER_INSERT` AFTER INSERT ON `raw_ts_quote_eps` FOR EACH ROW BEGIN
	IF new.`currency` = 'EUR' THEN
		SET @fx = 1;
	ELSE
		IF new.`currency` = BINARY 'GBp' THEN
			SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		ELSEIF new.`currency` <> BINARY 'GBp' THEN 
			SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
		END IF;
	END IF;
	IF @fx IS NOT NULL THEN
		INSERT INTO `fmp`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `per`, `currency`, `updated`)
		VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, new.`per`, 'EUR', new.`updated`)
		ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `per` = new.`per`, `updated` = new.`updated`;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,NO_AUTO_VALUE_ON_ZERO,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`%`*/ /*!50003 TRIGGER `raw_ts_quote_eps_AFTER_UPDATE` AFTER UPDATE ON `raw_ts_quote_eps` FOR EACH ROW BEGIN
    IF OLD.`updated` <> NEW.`updated` THEN
		IF new.`currency` = 'EUR' THEN
			SET @fx = 1;
		ELSE
			IF new.`currency` = BINARY 'GBp' THEN
				SET @fx = (SELECT `close`*100 FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			ELSEIF new.`currency` <> BINARY 'GBp' THEN 
				SET @fx = (SELECT `close` FROM `fmp`.`eur_ts_fx` WHERE `symbol` = new.`currency` AND `date` = new.`date`);
			END IF;
		END IF;
		IF @fx IS NOT NULL THEN
			INSERT INTO `fmp`.`eur_ts_quote` (`date`, `symbol`, `open`, `high`, `low`, `close`, `per`, `currency`, `updated`)
			VALUES (new.`date`, new.`symbol`,  new.`open`/@fx, new.`high`/@fx, new.`low`/@fx, new.`close`/@fx, new.`per`, 'EUR', new.`updated`)
			ON DUPLICATE KEY UPDATE `open`= new.`open`/@fx, `high` = new.`high`/@fx, `low` = new.`low`/@fx, `close` = new.`close`/@fx, `per` = new.`per`, `updated` = new.`updated`;
		END IF;        
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Dumping events for database 'fmp'
--

--
-- Dumping routines for database 'fmp'
--
/*!50003 DROP PROCEDURE IF EXISTS `create_eur_ts_fx` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `create_eur_ts_fx`()
BEGIN
/*
Create the eur_ts_fx table and interpolate up to 3 dates

Created: 2024-08-03 
Runtime: 12s

1. create empty table that is a copy of original
2. shift by a day and fill missing data with data of prev. day (5-times)
3. delete the future predicted elements
*/
DROP TABLE IF EXISTS `fmp`.`eur_ts_fx`;
CREATE TABLE `fmp`.`eur_ts_fx` (
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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='FX: data (in EUR) from raw_ts_fx'
SELECT * FROM `fmp`.`raw_ts_fx`;

INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`)
SELECT DATE_ADD(a.date, INTERVAL 1 DAY) as `date`, a.symbol, a.open, a.high, a.low, a.close, a.currency from `fmp`.`eur_ts_fx` a
LEFT JOIN `fmp`.`eur_ts_fx` b
on a.date = DATE_SUB(b.date, INTERVAL 1 DAY) and a.symbol = b.symbol
where b.symbol IS NULL;

INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`)
SELECT DATE_ADD(a.date, INTERVAL 1 DAY) as `date`, a.symbol, a.open, a.high, a.low, a.close, a.currency from `fmp`.`eur_ts_fx` a
LEFT JOIN `fmp`.`eur_ts_fx` b
on a.date = DATE_SUB(b.date, INTERVAL 1 DAY) and a.symbol = b.symbol
where b.symbol IS NULL;

INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`)
SELECT DATE_ADD(a.date, INTERVAL 1 DAY) as `date`, a.symbol, a.open, a.high, a.low, a.close, a.currency from `fmp`.`eur_ts_fx` a
LEFT JOIN `fmp`.`eur_ts_fx` b
on a.date = DATE_SUB(b.date, INTERVAL 1 DAY) and a.symbol = b.symbol
where b.symbol IS NULL;

INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`)
SELECT DATE_ADD(a.date, INTERVAL 1 DAY) as `date`, a.symbol, a.open, a.high, a.low, a.close, a.currency from `fmp`.`eur_ts_fx` a
LEFT JOIN `fmp`.`eur_ts_fx` b
on a.date = DATE_SUB(b.date, INTERVAL 1 DAY) and a.symbol = b.symbol
where b.symbol IS NULL;

INSERT INTO `fmp`.`eur_ts_fx` (`date`, `symbol`, `open`, `high`, `low`, `close`, `currency`)
SELECT DATE_ADD(a.date, INTERVAL 1 DAY) as `date`, a.symbol, a.open, a.high, a.low, a.close, a.currency from `fmp`.`eur_ts_fx` a
LEFT JOIN `fmp`.`eur_ts_fx` b
on a.date = DATE_SUB(b.date, INTERVAL 1 DAY) and a.symbol = b.symbol
where b.symbol IS NULL;

DELETE FROM fmp.eur_ts_fx WHERE `date` > CURRENT_DATE();
  
INSERT INTO fmp._function_log (`function`, `last_execution_time`)
VALUES ('create_eur_ts_fx', now())
ON DUPLICATE KEY UPDATE `last_execution_time` = now();
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `eur_ts_fx_analyze_occasionally` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `eur_ts_fx_analyze_occasionally`()
BEGIN
	/*
	calculate the coverage of the time period based on raw_ts_fx
	--> estimate the coverage of FX
    21.03.2024
	*/
	SELECT `symbol`, 
			count(*) as `count`, 
			min(`date`) as `min_date`, 
			max(`date`) as `max_date`, 
			datediff(max(`date`),min(`date`))+1 as `days`,
			count(*)/(datediff(max(`date`),min(`date`))+1) as `coverage` FROM fmp.eur_ts_fx group by `symbol` order by `symbol` asc;

	INSERT INTO fmp._function_log (`function`, `last_execution_time`)
	VALUES ('eur_ts_fx_analyze_occasionally', now())
	ON DUPLICATE KEY UPDATE `last_execution_time` = now();  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `find_dataset` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `find_dataset`(IN item varchar(255))
BEGIN
	/*
	find symbol based on symbol, isin, company name or fragments of it [2024-09-11]
	*/

	SET @searchItem = concat('%',item,'%');
	
    /* search in raw_companykeystats for symbol, isin, company name or fragments of it and write in tmp_companykeystats with braking up range in min and max */
	DROP TABLE IF EXISTS fmp.tmp_companykeystats;
	CREATE TABLE fmp.tmp_companykeystats SELECT *, 
		IF(SUBSTRING_INDEX(`range`,'-', 1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(`range`,'-', 1), NULL) as `min`,
    	IF(SUBSTRING_INDEX(`range`,'-', -1) REGEXP '^[0-9\.]+$', SUBSTRING_INDEX(`range`,'-', -1), NULL) as `max`
        FROM fmp.raw_companykeystats WHERE companyName LIKE @searchItem OR isin LIKE @searchItem OR symbol LIKE @searchitem;
    
    /* DEBUG SELECT * FROM fmp.tmp_companykeystats; */
    
    /* gather the fx_rates */
    DROP TABLE IF EXISTS fmp.tmp_fx;
    CREATE TABLE fmp.tmp_fx	SELECT IF(b.`symbol` = BINARY 'GBP',  b.`close`*100, b.`close`) as `fx`, c.`symbol` FROM (
		SELECT `symbol`, max(`date`) as `date` FROM fmp.eur_ts_fx group by `symbol`) a
        LEFT JOIN fmp.eur_ts_fx b
        ON a.`symbol` = b.`symbol` AND a.`date` = b.`date`
        RIGHT JOIN fmp.tmp_companykeystats c
        ON a.`symbol` = c.`currency`;
    
    /* DEBUG SELECT * FROM fmp.tmp_fx; */
    
    /* gather the fundamentals */
    DROP TABLE IF EXISTS fmp.tmp_fun;
    CREATE TABLE fmp.tmp_fun SELECT c.`symbol`, group_concat(c.`calendarYear` order by c.`calendarYear` desc) as `year`, 
		group_concat(FORMAT(c.`eps`,1) order by c.`calendarYear` desc) as `eps`, 
        group_concat(FORMAT(c.`dps`,1) order by c.`calendarYear` desc) as `dps`,
		group_concat(FORMAT(c.`bps`,1) order by c.`calendarYear` desc) as `bps` FROM (SELECT a.`symbol`, b.`calendarYear`, b.`eps`, b.`dps`, b.`bps` FROM fmp.tmp_companykeystats a LEFT JOIN fmp.eur_fun b ON a.`symbol` = b.`symbol`) c
		group by c.`symbol`;

    /* DEBUG SELECT * FROM fmp.tmp_fun; */
    
    /* merge and display */
    SELECT a.`symbol`, format(a.`price`/b.`fx`,3) as `price`, format(a.`min`/b.`fx`,3) as `min`, format(a.`max`/b.`fx`,3) as `max`, format(a.`lastDiv`/b.`fx`,3) as `lastDiv`,
		format(a.`mktCap`/1000000000/b.`fx`,3) as `mktCap`, a.`companyName`, a.`isActivelyTrading`, a.`isAdr`, a.`currency`, a.`isin`, a.`exchangeShortName`, a.`industry`, a.`sector`, a.`country`, a.`updated`,
		c.`year`, c.`eps`, c.`dps`, c.`bps` FROM fmp.tmp_companykeystats a
		LEFT JOIN fmp.tmp_fx b ON a.`symbol` = b.`symbol`
		LEFT JOIN fmp.tmp_fun c ON a.`symbol` = c.`symbol`;
    
    /* cleaning */
	DROP TABLE IF EXISTS fmp.tmp_companykeystats;
    DROP TABLE IF EXISTS fmp.tmp_fx;
    DROP TABLE IF EXISTS fmp.tmp_fun;
    
	INSERT INTO fmp._function_log (`function`, `last_execution_time`)
	VALUES ('find_dataset', now())
	ON DUPLICATE KEY UPDATE `last_execution_time` = now();
        
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `raw_ts_fx_analyze_occasionally` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `raw_ts_fx_analyze_occasionally`()
BEGIN
	/*
	calculate the coverage of the time period based on raw_ts_fx
	--> estimate the coverage of FX
    21.03.2024
	*/
	SELECT `symbol`, 
			count(*) as `count`, 
			min(`date`) as `min_date`, 
			max(`date`) as `max_date`, 
			datediff(max(`date`),min(`date`))+1 as `days`, 
			count(*)/(datediff(max(`date`),min(`date`))+1) as `coverage` FROM fmp.raw_ts_fx group by `symbol` order by `symbol` asc;

	INSERT INTO fmp._function_log (`function`, `last_execution_time`)
	VALUES ('raw_ts_fx_analyze_occasionally', now())
	ON DUPLICATE KEY UPDATE `last_execution_time` = now();  
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `stock_split_check` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `stock_split_check`(
    IN p_symbol          VARCHAR(255),
    IN p_date_after      DATE,
    IN p_announced_split DECIMAL(18,6)
)
BEGIN
    DECLARE v_date_before DATE;
    DECLARE v_close_before DOUBLE;
    DECLARE v_close_after  DOUBLE;
    DECLARE v_calculated_split DECIMAL(18,6);
    DECLARE v_difference DECIMAL(18,6);

    /*
      Validate parameters.
      Example: p_announced_split = 10 means a 10-for-1 split.
    */
    IF p_symbol IS NULL OR TRIM(p_symbol) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A symbol must be supplied.';
    END IF;

    IF p_date_after IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The first date after the split must be supplied.';
    END IF;

    IF p_announced_split IS NULL OR p_announced_split <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'The split factor must be greater than zero.';
    END IF;

    /*
      Get the closing price on the first trading date after the split.
    */
    SELECT q.close
      INTO v_close_after
    FROM eur_ts_quote AS q
    WHERE q.symbol = p_symbol
      AND q.date = p_date_after
    LIMIT 1;

    IF v_close_after IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'No closing price was found for the symbol on the date after the split.';
    END IF;

    /*
      Find the latest available trading date before the supplied date.
    */
    SELECT MAX(q.date)
      INTO v_date_before
    FROM eur_ts_quote AS q
    WHERE q.symbol = p_symbol
      AND q.date < p_date_after;

    IF v_date_before IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'No closing price was found before the supplied split date.';
    END IF;

    /*
      Retrieve the closing price on the last trading date before the split.
    */
    SELECT q.close
      INTO v_close_before
    FROM eur_ts_quote AS q
    WHERE q.symbol = p_symbol
      AND q.date = v_date_before
    LIMIT 1;

    IF v_close_before IS NULL OR v_close_before = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'The closing price before the split is missing or zero.';
    END IF;

    IF v_close_after = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'The closing price after the split cannot be zero.';
    END IF;

    /*
      Example:
          close before = 1,000
          close after  =   100
          calculated split = 1,000 / 100 = 10
    */
    SET v_calculated_split =
        ROUND(v_close_before / v_close_after, 6);

    SET v_difference =
        ROUND(v_calculated_split - p_announced_split, 6);

    SELECT
        p_symbol AS symbol,
        v_date_before AS date_before_split,
        v_close_before AS close_before_split,
        p_date_after AS date_after_split,
        v_close_after AS close_after_split,
        p_announced_split AS announced_split_ratio,
        v_calculated_split AS calculated_split_ratio,
        v_difference AS ratio_difference,
        ROUND(
            ABS(v_calculated_split - p_announced_split)
            / p_announced_split * 100,
            4
        ) AS difference_percent,
        CASE
            WHEN ABS(v_calculated_split - p_announced_split)
                 / p_announced_split <= 0.03
            THEN 'CONSISTENT'
            ELSE 'REVIEW'
        END AS split_check;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `stock_split_execute` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `stock_split_execute`(
    IN p_symbol     VARCHAR(255),
    IN p_date_after DATE,
    IN p_split_rate DECIMAL(18,6),
    IN p_execute    VARCHAR(10)
)
BEGIN
    IF UPPER(TRIM(p_execute)) <> 'NOW' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Execution cancelled. Pass ''NOW'' as the last parameter to execute.';
    END IF;

    START TRANSACTION;

    UPDATE eur_ts_quote
    SET
        open    = open  / p_split_rate,
        high    = high  / p_split_rate,
        low     = low   / p_split_rate,
        close   = close / p_split_rate,
        updated = CURRENT_TIMESTAMP
    WHERE symbol = p_symbol
      AND date < p_date_after;

    SELECT
        ROW_COUNT() AS rows_updated,
        p_symbol AS symbol,
        p_split_rate AS split_rate,
        p_date_after AS first_post_split_date;

    COMMIT;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `update_raw_companykeystats_with_new_raw_assetslist_items` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_raw_companykeystats_with_new_raw_assetslist_items`()
BEGIN
	/*
	update raw_companykeystats with new symbols from raw_assetslist
	*/
	INSERT INTO fmp.raw_companykeystats (symbol) SELECT a.symbol FROM fmp.raw_assetslist a
	LEFT JOIN fmp.raw_companykeystats b
	ON a.symbol = b.symbol
	WHERE b.symbol IS NULL;
    
	INSERT INTO fmp._function_log (`function`, `last_execution_time`)
	VALUES ('update_raw_companykeystats_with_new_raw_assetslist_items', now())
	ON DUPLICATE KEY UPDATE `last_execution_time` = now();
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `update_reference_map_with_companykeystats` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `update_reference_map_with_companykeystats`()
BEGIN
	/*
	update _reference_map with companykeystats [2025-02-23]
	*/
	UPDATE fmp._reference_map a
	INNER JOIN fmp.raw_companykeystats b ON (a.symbol = b.symbol)
	SET a.companyName = b.companyName
	WHERE a.companyName IS NULL;
    
	UPDATE fmp._reference_map a
	INNER JOIN fmp.raw_companykeystats b ON (a.symbol = b.symbol)
	SET a.industry = b.industry
	WHERE a.industry IS NULL;
    
	UPDATE fmp._reference_map a
	INNER JOIN fmp.raw_companykeystats b ON (a.symbol = b.symbol)
	SET a.sector = b.sector
	WHERE a.sector IS NULL;
    
	UPDATE fmp._reference_map a
	INNER JOIN fmp.raw_companykeystats b ON (a.symbol = b.symbol)
	SET a.country = b.country
	WHERE a.country IS NULL;
    
	INSERT INTO fmp._function_log (`function`, `last_execution_time`)
	VALUES ('update_reference_map_with_companykeystats', now())
	ON DUPLICATE KEY UPDATE `last_execution_time` = now();
    
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `_reference_map_copy` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`%` PROCEDURE `_reference_map_copy`()
BEGIN
	create table fmp._reference_map_copy like fmp._reference_map;
    insert into fmp._reference_map_copy select * from fmp._reference_map;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `find_missing_fx`
--

/*!50001 DROP VIEW IF EXISTS `find_missing_fx`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `find_missing_fx` AS select `a`.`date` AS `date`,`a`.`currency` AS `currency` from (`raw_fun` `a` left join `eur_ts_fx` `b` on(((`a`.`currency` = `b`.`symbol`) and (`a`.`date` = `b`.`date`)))) where ((`b`.`close` is null) and (`a`.`currency` <> 'EUR')) group by `a`.`date`,`a`.`currency` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fundamental_advanced`
--

/*!50001 DROP VIEW IF EXISTS `fundamental_advanced`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`fmp`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `fundamental_advanced` AS select `eur_fun`.`date` AS `date`,`eur_fun`.`symbol` AS `symbol`,`eur_fun`.`calendarYear` AS `calendarYear`,`eur_fun`.`period` AS `period`,`eur_fun`.`grossProfitRatio` AS `grossProfitRatio`,`eur_fun`.`researchAndDevelopmentRatio` AS `researchAndDevelopmentRatio`,`eur_fun`.`interestExpenseRatio` AS `interestExpenseRatio`,`eur_fun`.`interestRisk` AS `interestRisk`,`eur_fun`.`created` AS `created`,`eur_fun`.`updated` AS `updated` from `eur_fun` where ((`eur_fun`.`eps` is not null) or (`eur_fun`.`dps` is not null) or (`eur_fun`.`cps` is not null) or (`eur_fun`.`bps` is not null)) order by `eur_fun`.`date` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `fundamental_basic`
--

/*!50001 DROP VIEW IF EXISTS `fundamental_basic`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`fmp`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `fundamental_basic` AS select `eur_fun`.`date` AS `date`,`eur_fun`.`symbol` AS `symbol`,`eur_fun`.`calendarYear` AS `calendarYear`,`eur_fun`.`period` AS `period`,`eur_fun`.`eps` AS `eps`,`eur_fun`.`dps` AS `dps`,`eur_fun`.`cps` AS `cps`,`eur_fun`.`bps` AS `bps`,`eur_fun`.`currency` AS `currency`,`eur_fun`.`created` AS `created`,`eur_fun`.`updated` AS `updated` from `eur_fun` where ((`eur_fun`.`eps` is not null) or (`eur_fun`.`dps` is not null) or (`eur_fun`.`cps` is not null) or (`eur_fun`.`bps` is not null)) order by `eur_fun`.`date` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-31  7:19:08
