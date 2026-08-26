#!/usr/bin/env python3
"""Evaluate the aggregate PR gate from conditional GitHub job results."""

from __future__ import annotations

import argparse


def evaluate(
    *,
    classify_result: str,
    contracts_result: str,
    static_result: str,
    host_result: str,
    widgetbook_result: str,
    goldens_result: str,
    needs_contracts: bool,
    needs_static: bool,
    needs_host_tests: bool,
    needs_widgetbook: bool,
    needs_goldens: bool,
) -> list[str]:
    problems: list[str] = []
    if classify_result != "success":
        return [f"change classification did not succeed ({classify_result})"]

    for label, result, required in (
        ("contract verification", contracts_result, needs_contracts),
        ("static verification", static_result, needs_static),
        ("host-test shards", host_result, needs_host_tests),
        ("Widgetbook smoke test", widgetbook_result, needs_widgetbook),
        ("golden comparison", goldens_result, needs_goldens),
    ):
        expected = "success" if required else "skipped"
        if result != expected:
            problems.append(f"{label} result was {result}; expected {expected}")
    return problems


def _parse_bool(value: str) -> bool:
    if value not in {"true", "false"}:
        raise argparse.ArgumentTypeError("expected 'true' or 'false'")
    return value == "true"


def main() -> int:
    parser = argparse.ArgumentParser()
    for name in (
        "classify-result",
        "contracts-result",
        "static-result",
        "host-result",
        "widgetbook-result",
        "goldens-result",
    ):
        parser.add_argument(f"--{name}", required=True)
    for name in (
        "needs-contracts",
        "needs-static",
        "needs-host-tests",
        "needs-widgetbook",
        "needs-goldens",
    ):
        parser.add_argument(f"--{name}", type=_parse_bool, required=True)
    args = parser.parse_args()

    problems = evaluate(
        classify_result=args.classify_result,
        contracts_result=args.contracts_result,
        static_result=args.static_result,
        host_result=args.host_result,
        widgetbook_result=args.widgetbook_result,
        goldens_result=args.goldens_result,
        needs_contracts=args.needs_contracts,
        needs_static=args.needs_static,
        needs_host_tests=args.needs_host_tests,
        needs_widgetbook=args.needs_widgetbook,
        needs_goldens=args.needs_goldens,
    )
    if problems:
        for problem in problems:
            print(f"ERROR: {problem}")
        return 1
    print("Selected CI path passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
