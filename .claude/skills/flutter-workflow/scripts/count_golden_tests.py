#!/usr/bin/env python3
"""Count the golden tests that actually ran, and fail below a floor.

`flutter test --tags golden` exits 0 when it runs *zero* tests — a broken tag,
a renamed `test/` path, or a deleted suite all leave the job green with no
coverage. The compact reporter's animated output cannot be counted reliably, so
this reads the machine-readable JSON reporter instead and counts test-completion
events, which are unambiguous.

The floor is a tripwire, not a target: it sits well below the current golden
count so ordinary work never touches it, and it is raised deliberately. Its job
is to notice that the scope collapsed, not to police how many goldens exist.

Usage:
    count_golden_tests.py <json-report-file> <floor>

The report file is the newline-delimited JSON that
`flutter test --reporter json` writes. Exit 0 when the count meets the floor and
every test that ran passed; exit 1 otherwise.
"""

from __future__ import annotations

import json
import sys


def _load_events(path: str) -> list[dict]:
    """Return the JSON events in *path*, skipping blank or non-JSON lines.

    The reporter emits one JSON object per line. A stray progress or warning
    line from the toolchain is not fatal to the count, so it is skipped rather
    than aborting the whole parse.
    """
    events: list[dict] = []
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(event, dict):
                events.append(event)
    return events


def count_and_check(path: str, floor: int) -> int:
    """Print the discovered count and return a process exit code."""
    events = _load_events(path)

    # `testDone` is emitted once per test as it finishes. `hidden` marks the
    # synthetic "loading <suite>" entries the reporter creates per file, which
    # are not tests. `skipped` marks a test that was declared but did not run —
    # `@Skip(...)` or `skip: true` — which reports `result: success` and would
    # otherwise pad the count: 60 real + 20 skipped would read as 80 and clear a
    # floor of 70 while only 60 actually ran. Both are excluded so the count is of
    # tests that genuinely executed.
    done = [
        e
        for e in events
        if e.get("type") == "testDone"
        and not e.get("hidden", False)
        and not e.get("skipped", False)
    ]
    discovered = len(done)
    failed = [e for e in done if e.get("result") != "success"]

    print(f"Golden tests discovered: {discovered}")
    print(f"Minimum required: {floor}")

    if discovered < floor:
        print(
            f"::error::Expected at least {floor} golden tests, but only "
            f"{discovered} ran. Possible causes: tag regression, discovery "
            f"regression, test deletion."
        )
        return 1

    if failed:
        # A defensive second gate. `flutter test` already exits non-zero on a
        # failure, so this is normally unreachable — but if the count step is
        # ever run on its own, a red suite must not read as a passing floor.
        print(
            f"::error::{len(failed)} golden test(s) did not pass; "
            "the floor is not a substitute for the suite passing."
        )
        return 1

    print(f"golden count floor satisfied ({discovered} >= {floor})")
    return 0


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: count_golden_tests.py <json-report-file> <floor>", file=sys.stderr)
        return 2
    try:
        floor = int(argv[2])
    except ValueError:
        print(f"floor must be an integer, got {argv[2]!r}", file=sys.stderr)
        return 2
    return count_and_check(argv[1], floor)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
