#!/usr/bin/env python3
"""Evaluate the aggregate PR gate from conditional GitHub job results."""

from __future__ import annotations

import argparse


def evaluate(
    *,
    classify_result: str,
    prompt_result: str,
    static_result: str,
    host_result: str,
    widgetbook_result: str,
    has_prompt_changes: bool,
    prompt_only: bool,
    code_required: bool,
) -> list[str]:
    problems: list[str] = []
    if classify_result != "success":
        return [f"change classification did not succeed ({classify_result})"]

    if prompt_only:
        if prompt_result != "success":
            problems.append(f"prompt-only path did not pass prompt contract ({prompt_result})")
        for label, result in (
            ("static job", static_result),
            ("host tests", host_result),
            ("Widgetbook", widgetbook_result),
        ):
            if result != "skipped":
                problems.append(f"{label} unexpectedly ran on prompt-only change ({result})")
        return problems

    if not code_required:
        return ["classifier selected neither the prompt nor code path"]

    for label, result in (
        ("static verification", static_result),
        ("host-test shards", host_result),
        ("Widgetbook smoke test", widgetbook_result),
    ):
        if result != "success":
            problems.append(f"{label} did not succeed ({result})")

    expected_prompt = "success" if has_prompt_changes else "skipped"
    if prompt_result != expected_prompt:
        problems.append(
            "prompt contract result was "
            f"{prompt_result}; expected {expected_prompt} for this change set"
        )
    return problems


def _parse_bool(value: str) -> bool:
    if value not in {"true", "false"}:
        raise argparse.ArgumentTypeError("expected 'true' or 'false'")
    return value == "true"


def main() -> int:
    parser = argparse.ArgumentParser()
    for name in (
        "classify-result",
        "prompt-result",
        "static-result",
        "host-result",
        "widgetbook-result",
    ):
        parser.add_argument(f"--{name}", required=True)
    for name in ("has-prompt-changes", "prompt-only", "code-required"):
        parser.add_argument(f"--{name}", type=_parse_bool, required=True)
    args = parser.parse_args()

    problems = evaluate(
        classify_result=args.classify_result,
        prompt_result=args.prompt_result,
        static_result=args.static_result,
        host_result=args.host_result,
        widgetbook_result=args.widgetbook_result,
        has_prompt_changes=args.has_prompt_changes,
        prompt_only=args.prompt_only,
        code_required=args.code_required,
    )
    if problems:
        for problem in problems:
            print(f"ERROR: {problem}")
        return 1
    print("Selected CI path passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
