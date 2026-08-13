#!/usr/bin/env python3
"""Classify a change set for the pull-request CI workflow.

The classifier deliberately has one fast path only: every changed path must
live under ``docs/prompt/``. Empty or unrecognised input fails safe to the full
code gate. Keeping this decision in a tested script prevents workflow-shell
globs from silently widening the fast path.
"""

from __future__ import annotations

import argparse
import sys
from dataclasses import dataclass
from pathlib import Path


PROMPT_PREFIX = "docs/prompt/"


@dataclass(frozen=True)
class ChangeClassification:
    changed_count: int
    has_prompt_changes: bool
    prompt_only: bool
    code_required: bool


def classify(paths: list[str], *, force_code: bool = False) -> ChangeClassification:
    normalized = [path.replace("\\", "/").lstrip("./") for path in paths if path]
    has_prompt_changes = any(path.startswith(PROMPT_PREFIX) for path in normalized)
    prompt_only = bool(normalized) and all(
        path.startswith(PROMPT_PREFIX) for path in normalized
    )
    if force_code:
        prompt_only = False
    return ChangeClassification(
        changed_count=len(normalized),
        has_prompt_changes=has_prompt_changes,
        prompt_only=prompt_only,
        code_required=not prompt_only,
    )


def _bool(value: bool) -> str:
    return "true" if value else "false"


def _write_github_output(path: Path, result: ChangeClassification) -> None:
    with path.open("a", encoding="utf-8") as output:
        output.write(f"changed_count={result.changed_count}\n")
        output.write(f"has_prompt_changes={_bool(result.has_prompt_changes)}\n")
        output.write(f"prompt_only={_bool(result.prompt_only)}\n")
        output.write(f"code_required={_bool(result.code_required)}\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--github-output",
        type=Path,
        help="Append key/value outputs to this GitHub Actions output file.",
    )
    parser.add_argument(
        "--force-code",
        action="store_true",
        help="Disable the prompt-only fast path (used by workflow_dispatch).",
    )
    parser.add_argument(
        "--nul",
        action="store_true",
        help="Read NUL-delimited paths from stdin instead of newline-delimited paths.",
    )
    args = parser.parse_args()

    raw = sys.stdin.buffer.read()
    separator = b"\0" if args.nul else b"\n"
    paths = [item.decode("utf-8") for item in raw.split(separator) if item]
    result = classify(paths, force_code=args.force_code)

    if args.github_output:
        _write_github_output(args.github_output, result)
    else:
        print(f"changed_count={result.changed_count}")
        print(f"has_prompt_changes={_bool(result.has_prompt_changes)}")
        print(f"prompt_only={_bool(result.prompt_only)}")
        print(f"code_required={_bool(result.code_required)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
