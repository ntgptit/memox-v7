#!/usr/bin/env python3
"""Generated code is fresh, complete, and not committed.

Generated output is gitignored, so "run build_runner and fail if the tree is
dirty" cannot work — the tree is clean whatever the generators did. Three things
are checkable instead, and together they are what "verified fresh" means when
the output is not in the repo:

  1. no generated file is tracked by git;
  2. every hand-written source is tracked (the converse: an ignore rule for
     build output can also swallow a source directory of the same name);
  3. every `part '…g.dart' / .freezed.dart / .drift.dart` a source declares
     exists beside it;
  4. a clean rebuild reproduces the same output, byte for byte (the slow one).

**Why Python.** Checks 1–3 are unchanged; check 3 (the rebuild) still shells out
to `dart`. The bash version's part-directive scan grepped every source file in a
loop — ~135 forks — and on Windows git-bash the `--skip-rebuild` path took 52
seconds. This reads each source once, in one process. The `.sh` beside it is a
thin wrapper so every caller keeps working.

Usage: check_generated.py [--skip-rebuild]
Exit:  0 clean, 1 problems found.
"""

from __future__ import annotations

import hashlib
import re
import shutil
import subprocess
import sys
from pathlib import Path

# Resolved once. On Windows `dart` is `dart.BAT`, which a bare
# `subprocess.run(["dart", …])` does not find — the bash version's
# `command -v dart` did, so without this the clean-rebuild path would silently
# skip on Windows while reporting "dart not on PATH".
_DART = shutil.which("dart")

_TTY = sys.stdout.isatty()
_RED = "\033[31m" if _TTY else ""
_GRN = "\033[32m" if _TTY else ""
_YLW = "\033[33m" if _TTY else ""
_OFF = "\033[0m" if _TTY else ""

_violations = 0


def _report(kind: str, where: str, why: str) -> None:
    global _violations
    _violations += 1
    print(f"{_RED}✗{_OFF} {kind}\n    {where}\n    {why}")


def _note(msg: str) -> None:
    print(f"{_YLW}·{_OFF} {msg}")


_GENERATED_SUFFIX_RE = re.compile(r"\.(g|freezed|drift|mocks|config)\.dart$")
_PART_RE = re.compile(r"^part '([^']+\.(?:g|freezed|drift)\.dart)';")


def _repo_root() -> Path:
    try:
        top = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        if top:
            return Path(top)
    except (OSError, subprocess.CalledProcessError):
        pass
    return Path.cwd()


def _generated_files(root: Path) -> list[str]:
    """Files the generators own, repo-relative posix, excluding the hand-written
    drift fixtures under test/drift/generated/ (drift names some `*.g.dart`)."""
    out: list[str] = []
    for base in ("lib", "test"):
        b = root / base
        if not b.is_dir():
            continue
        for p in b.rglob("*.dart"):
            if not _GENERATED_SUFFIX_RE.search(p.name):
                continue
            rel = p.relative_to(root).as_posix()
            if rel.startswith("test/drift/generated/"):
                continue
            out.append(rel)
    return sorted(out)


def _handwritten_lib(root: Path) -> list[str]:
    """Hand-written lib sources, repo-relative posix. Excludes generated
    suffixes and lib/l10n/generated/ (gen-l10n output, ignored on purpose)."""
    out: list[str] = []
    b = root / "lib"
    if not b.is_dir():
        return out
    for p in b.rglob("*.dart"):
        if _GENERATED_SUFFIX_RE.search(p.name) or p.name.endswith(".drift.dart"):
            continue
        rel = p.relative_to(root).as_posix()
        if rel.startswith("lib/l10n/generated/"):
            continue
        out.append(rel)
    return sorted(out)


def _git_tracked(root: Path) -> set[str]:
    try:
        out = subprocess.run(
            ["git", "ls-files"], cwd=root, capture_output=True, text=True, check=True
        ).stdout
    except (OSError, subprocess.CalledProcessError):
        return set()
    return set(out.splitlines())


def main() -> int:
    skip_rebuild = "--skip-rebuild" in sys.argv[1:]
    root = _repo_root()
    tracked = _git_tracked(root)

    # 1. Nothing generated is tracked.
    for f in sorted(tracked):
        if not _GENERATED_SUFFIX_RE.search(f):
            continue
        if f.startswith("test/drift/generated/") or f.startswith("drift_schemas/"):
            continue
        _report(
            "generated file is committed", f,
            "Machine output in the repo is output that can go stale, and a "
            "diff nobody can review. It is in .gitignore — 'git rm --cached' it.",
        )

    # 1b. Every hand-written source IS tracked.
    handwritten = _handwritten_lib(root)
    for f in handwritten:
        if f not in tracked:
            _report(
                "source file is not in git", f,
                "A fresh clone does not have this file, so CI compiles "
                "something different from what you are running. Look for a "
                ".gitignore pattern written for build output that also matches "
                "a source path.",
            )

    # 2. Every declared part exists beside its source.
    declared = 0
    for f in handwritten:
        path = root / f
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue
        parent = path.parent
        for line in lines:
            m = _PART_RE.match(line)
            if not m:
                continue
            declared += 1
            if not (parent / m.group(1)).is_file():
                _report(
                    "declared part is missing", f"{f} -> {m.group(1)}",
                    "Run: dart run build_runner build --delete-conflicting-outputs",
                )

    # 3. A clean rebuild reproduces the same output, byte for byte.
    rebuild_checked = 0
    if skip_rebuild:
        _note("clean-rebuild comparison skipped (--skip-rebuild)")
    elif _DART is None:
        _note("clean-rebuild comparison skipped — dart not on PATH")
    else:
        rebuild_checked = _check_rebuild(root)

    # Scope.
    print("-" * 60)
    source_count = len(handwritten)
    print(
        f"scanned: {source_count} hand-written sources under lib/, "
        f"{declared} declared parts, {rebuild_checked} generated files hashed"
    )
    if source_count == 0:
        _report(
            "zero scope", "lib/",
            "No hand-written Dart file matched under lib/, so the "
            "tracked-source check inspected nothing.",
        )
    if declared == 0:
        _report(
            "zero scope", "lib/",
            "No source declares a generated part. Either codegen was removed, "
            "or the pattern this script matches has stopped matching — and then "
            "every check above passed on nothing.",
        )

    print("-" * 60)
    if _violations == 0:
        print(f"{_GRN}✓{_OFF} generated code is fresh, complete and uncommitted")
        return 0
    print(f"{_RED}✗{_OFF} {_violations} generated-code problem(s)")
    return 1


def _dart(*args: str, cwd: Path) -> subprocess.CompletedProcess[bytes]:
    assert _DART is not None
    return subprocess.run([_DART, *args], cwd=cwd, capture_output=True)


def _hashes(root: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for rel in _generated_files(root):
        try:
            out[rel] = hashlib.sha256((root / rel).read_bytes()).hexdigest()
        except OSError:
            continue
    return out


def _check_rebuild(root: Path) -> int:
    before = _hashes(root)
    if not before:
        _report(
            "nothing to compare", "lib/, test/",
            "No generated files exist, so the clean-rebuild check has no "
            "subject. Generate first.",
        )
        return 0

    print(
        f"clean rebuild: removing cache and {len(before)} generated files, "
        "then building from source…"
    )
    clean_done = False
    try:
        _dart("run", "build_runner", "clean", cwd=root)
        for rel in before:
            try:
                (root / rel).unlink()
            except OSError:
                pass
        build_dir = root / ".dart_tool" / "build"
        if build_dir.is_dir():
            _rmtree(build_dir)

        result = _dart(
            "run", "build_runner", "build", "--delete-conflicting-outputs",
            cwd=root,
        )
        if result.returncode != 0:
            _report(
                "clean build_runner build failed", "dart run build_runner build",
                "Generation must succeed from source alone; a build that only "
                "works from cache is not reproducible.",
            )
            return len(before)

        clean_done = True
        after = _hashes(root)
        missing = sorted(set(before) - set(after))
        extra = sorted(set(after) - set(before))
        if missing:
            _report(
                "clean rebuild is missing generated files",
                " ".join(missing[:5]),
                "A from-nothing build did not re-emit these, so a fresh clone "
                "would not have them either.",
            )
        if extra:
            _report(
                "clean rebuild produced unexpected generated files",
                " ".join(extra[:5]),
                "These outputs were not present before — the generator set is "
                "not what the tree recorded.",
            )
        if not missing and not extra:
            changed = [p for p in before if before[p] != after.get(p)]
            if changed:
                _report(
                    "codegen is not reproducible", " ".join(sorted(changed)[:5]),
                    "A clean rebuild produced different bytes for the same "
                    "path, so 'fresh' is not verifiable.",
                )
        return len(before)
    finally:
        # If the outputs were removed but the verifying build did not finish,
        # regenerate so the working tree is left buildable.
        if not clean_done:
            _note("restoring generated files after an interrupted clean rebuild…")
            _dart(
                "run", "build_runner", "build", "--delete-conflicting-outputs",
                cwd=root,
            )


def _rmtree(path: Path) -> None:
    import shutil

    try:
        shutil.rmtree(path)
    except OSError:
        pass


if __name__ == "__main__":
    sys.exit(main())
