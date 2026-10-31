"""Small operational logger shared by all workers."""

from __future__ import annotations

import logging
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Any

from mylib.config import resolve_path


def create_logger(config: dict[str, Any], name: str = "yahoo_crawler") -> logging.Logger:
    logger = logging.getLogger(name)
    if logger.handlers:
        return logger
    logger.setLevel(logging.DEBUG)
    formatter = logging.Formatter("%(asctime)s %(levelname)s %(name)s: %(message)s")
    log_path = resolve_path(config, config["file"]["log"])
    Path(log_path).parent.mkdir(parents=True, exist_ok=True)
    file_handler = RotatingFileHandler(log_path, maxBytes=5_000_000, backupCount=3, encoding="utf-8")
    file_handler.setFormatter(formatter)
    file_handler.setLevel(logging.INFO)
    logger.addHandler(file_handler)
    console = logging.StreamHandler()
    console.setFormatter(formatter)
    console.setLevel(logging.INFO)
    logger.addHandler(console)
    if config.get("debug"):
        debug_path = resolve_path(config, config["file"]["debug"])
        Path(debug_path).parent.mkdir(parents=True, exist_ok=True)
        debug_handler = RotatingFileHandler(debug_path, maxBytes=5_000_000, backupCount=2, encoding="utf-8")
        debug_handler.setFormatter(formatter)
        debug_handler.setLevel(logging.DEBUG)
        logger.addHandler(debug_handler)
    return logger