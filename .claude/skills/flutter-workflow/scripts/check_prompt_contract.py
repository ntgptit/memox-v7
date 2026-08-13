#!/usr/bin/env python3
"""Validate executable prompt sets under ``docs/prompt/<feature>/``.

Prompt files are not product specifications, but AGENTS.md gives them a strict
delivery contract. This checker turns that contract into a fast, deterministic
gate so a newly accepted markdown baseline cannot hide a missing review phase.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path


EXPECTED_FILES = {
    "implementation.md",
    "recursive-architecture-logic-review.md",
    "recursive-ui-ux-review.md",
}
HEADER_FIELDS = (
    "Status",
    "Purpose",
    "Scope",
    "Source of truth for",
    "Depends on",
    "Updated by task",
    "Last updated",
)
HEADER_ROW = re.compile(r"^\| \*\*(.+?)\*\* \| .+ \|$")


@dataclass(frozen=True)
class Problem:
    path: Path
    message: str


def _normalized(text: str) -> str:
    return " ".join(text.casefold().split())


def _contains_any(text: str, choices: tuple[str, ...]) -> bool:
    return any(choice in text for choice in choices)


def _validate_header(path: Path, text: str) -> list[Problem]:
    lines = text.splitlines()
    if not lines or not lines[0].startswith("# "):
        return [Problem(path, "must start with one H1 title")]

    try:
        table_start = lines.index("| | |", 1, 4)
    except ValueError:
        return [Problem(path, "seven-field document header must follow the H1")]

    if table_start != 2 or len(lines) <= table_start + 8:
        return [Problem(path, "document header must start immediately after the H1")]
    if lines[table_start + 1] != "|---|---|":
        return [Problem(path, "document header separator is malformed")]

    actual: list[str] = []
    for line in lines[table_start + 2 : table_start + 9]:
        match = HEADER_ROW.match(line)
        actual.append(match.group(1) if match else "<malformed>")
    if tuple(actual) != HEADER_FIELDS:
        return [
            Problem(
                path,
                "header fields must be exactly: " + " · ".join(HEADER_FIELDS),
            )
        ]
    return []


def _validate_implementation(path: Path, text: str) -> list[Problem]:
    normalized = _normalized(text)
    problems: list[Problem] = []
    requirements = {
        "a concrete 5Why pre-flight": ("5why", "5 why"),
        "worktree-safety instructions": (
            "worktree",
            "branch/status/base",
            "git status",
            "commit/push/pr/merge",
        ),
        "verification requirements": (
            "verification",
            "verify",
            "gate",
            "tests và clean stop",
            "tests and clean stop",
        ),
        "an explicit clean-stop condition": ("clean stop", "stop condition"),
    }
    for label, terms in requirements.items():
        if not _contains_any(normalized, terms):
            problems.append(Problem(path, f"implementation prompt is missing {label}"))
    return problems


def _validate_review(path: Path, text: str, *, ui: bool) -> list[Problem]:
    normalized = _normalized(text)
    problems: list[Problem] = []
    shared = {
        "an audit-only first pass": ("audit-only", "audit only", "audit_only"),
        "an in-scope repair pass": (
            "auto-fix",
            "auto fix",
            "apply fixes",
            "apply_fixes",
        ),
        "a recursive clean-stop condition": ("clean stop", "stop condition"),
        "worktree-safety instructions": (
            "worktree",
            "latest tree",
            "latest diff",
            "commit/push/pr/merge",
            "commit/pr/merge",
        ),
        "verification after repairs": (
            "verification",
            "verify",
            "test",
            "gate",
            "xanh",
            "regression",
        ),
    }
    for label, terms in shared.items():
        if not _contains_any(normalized, terms):
            problems.append(Problem(path, f"review prompt is missing {label}"))

    if ui:
        ui_requirements = {
            "production-state rendering": (
                "production state",
                "production tree",
                "render production",
                "production assertion",
                "production card-row route",
            ),
            "getRect geometry assertions": ("getrect",),
            "golden/concept comparison rules": ("golden", "wireframe"),
            "approved-divergence accounting": (
                "approved divergence",
                "unapproved divergence",
                "approved difference",
                "unapproved difference",
            ),
        }
        for label, terms in ui_requirements.items():
            if not _contains_any(normalized, terms):
                problems.append(Problem(path, f"UI/UX prompt is missing {label}"))
    else:
        architecture_requirements = {
            "business-rule parity": (
                "business",
                "nghiệp vụ",
                "br-",
                "invariant",
                "rule",
                "scheduler",
                "prove ",
                "chứng minh",
                "no double-count",
            ),
            "architecture/dependency boundaries": ("architecture", "dependency", "boundary"),
            "persistence/failure handling": (
                "persistence",
                "database",
                "failure",
                "sqlite",
                "transaction",
                "query",
                "mutation",
            ),
        }
        for label, terms in architecture_requirements.items():
            if not _contains_any(normalized, terms):
                problems.append(Problem(path, f"architecture prompt is missing {label}"))
    return problems


def validate_prompt_root(root: Path) -> list[Problem]:
    prompt_root = root / "docs" / "prompt"
    if not prompt_root.is_dir():
        return [Problem(prompt_root, "prompt root does not exist")]

    problems: list[Problem] = []
    feature_dirs = sorted(
        directory
        for directory in prompt_root.iterdir()
        if directory.is_dir() and any(directory.glob("*.md"))
    )
    for directory in feature_dirs:
        markdown_files = {path.name for path in directory.glob("*.md")}
        missing = sorted(EXPECTED_FILES - markdown_files)
        extra = sorted(markdown_files - EXPECTED_FILES)
        if missing:
            problems.append(Problem(directory, f"missing prompt files: {', '.join(missing)}"))
        if extra:
            problems.append(Problem(directory, f"unexpected prompt files: {', '.join(extra)}"))

        for filename in sorted(EXPECTED_FILES & markdown_files):
            path = directory / filename
            text = path.read_text(encoding="utf-8-sig")
            problems.extend(_validate_header(path, text))
            if filename == "implementation.md":
                problems.extend(_validate_implementation(path, text))
            else:
                problems.extend(
                    _validate_review(
                        path,
                        text,
                        ui=filename == "recursive-ui-ux-review.md",
                    )
                )
    return problems


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()

    problems = validate_prompt_root(args.root.resolve())
    if problems:
        for problem in problems:
            try:
                display = problem.path.relative_to(args.root.resolve())
            except ValueError:
                display = problem.path
            print(f"ERROR {display}: {problem.message}", file=sys.stderr)
        print(f"Prompt contract failed with {len(problems)} problem(s).", file=sys.stderr)
        return 1

    feature_count = sum(
        1
        for directory in (args.root / "docs" / "prompt").iterdir()
        if directory.is_dir() and any(directory.glob("*.md"))
    )
    print(f"Prompt contract passed for {feature_count} feature set(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
