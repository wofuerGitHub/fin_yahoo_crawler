import json
import logging
import threading

from mylib.yahoo_throttle import YahooThrottle, call_with_retry


def test_concurrent_reservations_are_unique_and_persisted(tmp_path):
    throttle = YahooThrottle(tmp_path / "speed.json", 600, logging.getLogger("test-throttle"))
    reserved = []
    threads = [threading.Thread(target=lambda: reserved.append(throttle.reserve())) for _ in range(8)]

    for thread in threads:
        thread.start()
    for thread in threads:
        thread.join()

    assert len(set(reserved)) == len(reserved)
    assert json.loads((tmp_path / "speed.json").read_text(encoding="utf-8"))["next_allowed_at"] == max(reserved)


def test_malformed_state_recovers(tmp_path):
    state = tmp_path / "speed.json"
    state.write_text("not-json", encoding="utf-8")
    throttle = YahooThrottle(state, 600, logging.getLogger("test-throttle"))

    throttle.reserve()

    assert json.loads(state.read_text(encoding="utf-8"))["next_allowed_at"] > 0


def test_rate_limit_retries_are_bounded_and_apply_shared_cooldown(monkeypatch):
    class FakeThrottle:
        def __init__(self):
            self.reservations = 0
            self.cooldowns = []

        def reserve(self):
            self.reservations += 1

        def cooldown(self, seconds):
            self.cooldowns.append(seconds)

    class RateLimitError(Exception):
        status_code = 429

    monkeypatch.setattr("mylib.yahoo_throttle.time.sleep", lambda seconds: None)
    throttle = FakeThrottle()
    attempts = 0

    def operation():
        nonlocal attempts
        attempts += 1
        if attempts < 3:
            raise RateLimitError("rate limited")
        return "ok"

    result = call_with_retry(operation, throttle, attempts=3, cooldown_seconds=17, logger=logging.getLogger("test-throttle"))

    assert result == "ok"
    assert throttle.reservations == 3
    assert throttle.cooldowns == [17, 17]