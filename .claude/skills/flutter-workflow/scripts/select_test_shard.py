#!/usr/bin/env python3
"""Select one deterministic, file-level Flutter test shard.

Flutter's built-in ``--total-shards`` splits individual tests. MemoX has a few
harness suites whose later assertions deliberately verify setup performed by an
earlier test in the same file, so case-level sharding skips the setup while
retaining the assertion. This selector keeps every file atomic and greedily
balances the shards by the number of declared tests in each file.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


TEST_DECLARATION = re.compile(r"\b(?:testWidgets|testGoldens|test)\s*\(")


@dataclass(frozen=True)
class WeightedTestFile:
    path: str
    weight: int


def partition(
    files: list[WeightedTestFile], *, total_shards: int
) -> list[list[WeightedTestFile]]:
    if total_shards < 1:
        raise ValueError("total_shards must be positive")
    bins: list[list[WeightedTestFile]] = [[] for _ in range(total_shards)]
    weights = [0] * total_shards
    for item in sorted(files, key=lambda value: (-value.weight, value.path)):
        target = min(range(total_shards), key=lambda index: (weights[index], index))
        bins[target].append(item)
        weights[target] += item.weight
    for selected in bins:
        selected.sort(key=lambda value: value.path)
    return bins


def discover(
    root: Path, *, include_paths: set[str] | None = None
) -> list[WeightedTestFile]:
    completed = subprocess.run(
        ["git", "-C", str(root), "ls-files", "-z", "--", "test"],
        check=True,
        capture_output=True,
    )
    paths = [
        raw.decode("utf-8")
        for raw in completed.stdout.split(b"\0")
        if raw and raw.decode("utf-8").endswith("_test.dart")
    ]
    if include_paths is not None:
        tracked = set(paths)
        unknown = sorted(include_paths - tracked)
        if unknown:
            raise ValueError(
                "verification plan selected missing or untracked tests: "
                + ", ".join(unknown)
            )
        paths = [path for path in paths if path in include_paths]
    files: list[WeightedTestFile] = []
    for relative_path in paths:
        text = (root / relative_path).read_text(encoding="utf-8")
        files.append(
            WeightedTestFile(
                path=relative_path,
                weight=max(1, len(TEST_DECLARATION.findall(text))),
            )
        )
    return files


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--total-shards", type=int, required=True)
    parser.add_argument("--shard-index", type=int, required=True)
    parser.add_argument(
        "--test-files-json",
        help="JSON array from the sealed verification plan; omit for all tests.",
    )
    parser.add_argument("--nul", action="store_true")
    args = parser.parse_args()

    if not 0 <= args.shard_index < args.total_shards:
        parser.error("shard-index must be in [0, total-shards)")
    include_paths = None
    if args.test_files_json is not None:
        decoded = json.loads(args.test_files_json)
        if not isinstance(decoded, list) or not all(
            isinstance(item, str) for item in decoded
        ):
            parser.error("test-files-json must be a JSON array of strings")
        include_paths = set(decoded)
    try:
        discovered = discover(args.root.resolve(), include_paths=include_paths)
    except ValueError as error:
        print(str(error), file=sys.stderr)
        return 1
    shards = partition(discovered, total_shards=args.total_shards)
    selected = shards[args.shard_index]
    if not selected:
        print("selected test shard is empty", file=sys.stderr)
        return 1

    total_weight = sum(item.weight for item in selected)
    print(
        f"selected {len(selected)} test files with estimated weight {total_weight}",
        file=sys.stderr,
    )
    separator = "\0" if args.nul else "\n"
    sys.stdout.write(separator.join(item.path for item in selected))
    if args.nul:
        sys.stdout.write("\0")
    else:
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
