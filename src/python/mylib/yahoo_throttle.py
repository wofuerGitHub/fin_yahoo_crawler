"""Cross-process file-backed pacing and shared cooldown."""

from __future__ import annotations

import json
import logging
import os
import tempfile
import time
from pathlib import Path

from filelock import FileLock


class YahooThrottle:
    def __init__(self, state_path: str | Path, operations_per_minute: float, logger: logging.Logger):
        if operations_per_minute <= 0:
            raise ValueError("operations_per_minute must be greater than zero")
        self.state_path = Path(state_path)
        self.lock_path = self.state_path.with_suffix(self.state_path.suffix + ".lock")
        self.interval = 60.0 / operations_per_minute
        self.logger = logger

    def _read_state(self) -> dict[str, float]:
        if not self.state_path.exists():
            return {"next_allowed_at": 0.0, "cooldown_until": 0.0}
        try:
            state = json.loads(self.state_path.read_text(encoding="utf-8"))
            return {
                "next_allowed_at": max(0.0, float(state["next_allowed_at"])),
                "cooldown_until": max(0.0, float(state.get("cooldown_until", 0.0))),
            }
        except (OSError, ValueError, TypeError, KeyError, json.JSONDecodeError) as error:
            self.logger.warning("Throttle state is malformed; recovering safely: %s", error)
            return {"next_allowed_at": 0.0, "cooldown_until": 0.0}

    def _write_state(self, state: dict[str, float]) -> None:
        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        descriptor, temporary_name = tempfile.mkstemp(prefix=self.state_path.name, dir=self.state_path.parent)
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8") as target:
                json.dump(state, target)
                target.flush()
                os.fsync(target.fileno())
            os.replace(temporary_name, self.state_path)
        finally:
            if os.path.exists(temporary_name):
                os.unlink(temporary_name)

    def reserve(self) -> float:
        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        with FileLock(str(self.lock_path), timeout=60):
            now = time.time()
            state = self._read_state()
            reserved_at = max(now, state["next_allowed_at"], state["cooldown_until"]) + self.interval
            state["next_allowed_at"] = reserved_at
            self._write_state(state)
        delay = max(0.0, reserved_at - time.time())
        if delay:
            time.sleep(delay)
        return reserved_at

    def cooldown(self, seconds: float) -> None:
        if seconds <= 0:
            return
        self.state_path.parent.mkdir(parents=True, exist_ok=True)
        with FileLock(str(self.lock_path), timeout=60):
            state = self._read_state()
            state["cooldown_until"] = max(state["cooldown_until"], time.time() + seconds)
            self._write_state(state)


def call_with_retry(operation, throttle: YahooThrottle, attempts: int, cooldown_seconds: float, logger: logging.Logger):
    for attempt in range(1, attempts + 1):
        throttle.reserve()
        try:
            return operation()
        except Exception as error:
            message = str(error).lower()
            status_code = getattr(error, "status_code", None) or getattr(getattr(error, "response", None), "status_code", None)
            rate_limited = status_code == 429 or "429" in message or "rate limit" in message or "too many requests" in message
            if rate_limited:
                throttle.cooldown(cooldown_seconds)
            if attempt >= attempts:
                raise
            wait = min(2 ** (attempt - 1), 30)
            logger.warning("Yahoo operation failed (attempt %s/%s); retrying in %s seconds: %s", attempt, attempts, wait, error)
            time.sleep(wait)