#!/usr/bin/env python3
"""Verifies the layer boundaries the Dart analyzer cannot express.

Import direction is an architectural property, not a lint, so it needs its own
check — one that runs in CI, because a boundary nobody verifies is a boundary
that has already broken.

**Why Python and not the bash it replaced.** The rules are unchanged; the shape
of the runtime is not. The bash version forked `find lib` seventeen times and a
subprocess per file inside its loops, and on Windows git-bash each fork costs
tens of milliseconds — the whole script took two minutes there while finishing
in a second on Linux CI. This reads every source file once, in one process. The
`.sh` beside it is now a thin wrapper so every `bash …/check_architecture.sh`
caller and every doc that names it still works.

Usage: check_architecture.py [--quiet]
Exit:  0 clean, 1 violations found.
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

# --- output ---------------------------------------------------------------

_TTY = sys.stdout.isatty()
_RED = "\033[31m" if _TTY else ""
_YEL = "\033[33m" if _TTY else ""
_GRN = "\033[32m" if _TTY else ""
_DIM = "\033[2m" if _TTY else ""
_OFF = "\033[0m" if _TTY else ""

_QUIET = "--quiet" in sys.argv[1:]
_violations = 0


def _error(rule: str, loc: str, detail: str) -> None:
    global _violations
    _violations += 1
    print(f"{_RED}✗{_OFF} {rule}\n    {_DIM}{loc}{_OFF}\n    {detail}")


def _warn(rule: str, loc: str, detail: str) -> None:
    if _QUIET:
        return
    print(f"{_YEL}!{_OFF} {rule}\n    {_DIM}{loc}{_OFF}\n    {detail}")


# --- file collection ------------------------------------------------------

_GENERATED = (".g.dart", ".freezed.dart", ".mocks.dart")

# Whole directories of generated code that do not carry a generated suffix.
# flutter gen-l10n writes plain .dart names here; the files are regenerated
# on every build and are not committed, so no rule below can act on them.
_GENERATED_DIRS = ("lib/l10n/generated/",)


def _dart_files(lib: Path, repo_root: Path) -> list[tuple[str, list[str]]]:
    """Every source `.dart` under lib/, read once, keyed by its **repo-relative
    posix path** — `lib/features/…`, the form every `^lib/` rule below matches.

    Generated code is excluded: we do not control its imports and it is
    regenerated anyway."""
    out: list[tuple[str, list[str]]] = []
    for path in sorted(lib.rglob("*.dart"), key=lambda p: p.as_posix()):
        if path.name.endswith(_GENERATED):
            continue
        if not path.is_file():
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except OSError:
            continue
        rel = path.relative_to(repo_root).as_posix()
        if any(fragment in rel for fragment in _GENERATED_DIRS):
            continue
        out.append((rel, lines))
    return out


# --- rule patterns (unchanged from the bash version) ----------------------

_FORBIDDEN_IN_DOMAIN = re.compile(
    r"^\s*import\s+'("
    r"package:flutter/|package:flutter_riverpod/|package:riverpod|"
    r"package:dio/|package:drift/|package:sqlite|package:json_annotation/|"
    r"package:go_router/|package:path_provider/|package:shared_preferences/|"
    r"package:flutter_secure_storage/|dart:ui)"
)
_DOMAIN_PKG = re.compile(r"(package:[a-z_0-9]+|dart:ui)")

_DATA_IMPORT = re.compile(r"^\s*import\s+'[^']*(/data/|\.\./data/)")
_DATA_OTHER = re.compile(r"features/([a-z_0-9]+)/data/")

_CROSS_FEATURE = re.compile(
    r"^\s*import\s+'[^']*("
    r"features/[a-z_0-9]+/(data|presentation)/|"
    r"\.\./\.\./[a-z_0-9]+/(data|presentation)/)"
)
_CROSS_OTHER_PKG = re.compile(r"features/([a-z_0-9]+)/(data|presentation)/")
_CROSS_OTHER_REL = re.compile(r"\.\./\.\./([a-z_0-9]+)/(data|presentation)/")

_FEATURES_IMPORT = re.compile(r"^\s*import\s+'[^']*features/")
_APP_IMPORT = re.compile(r"^\s*import\s+'([^']*/)?(\.\./)*app/")

_EMPTY_CATCH = re.compile(r"catch\s*\([^)]*\)\s*\{\s*\}")
_PRINT = re.compile(r"(^|[^.\w])print\s*\(")

_OWN_FEATURE = re.compile(r"^lib/features/([^/]+)/")
_TOP_LAYER = re.compile(r"^lib/([^/]+)/")


def _check_imports(files: list[tuple[str, list[str]]]) -> None:
    for path, lines in files:
        own_match = _OWN_FEATURE.match(path)
        own = own_match.group(1) if own_match else None
        is_domain = "/domain/" in path
        is_presentation = "/presentation/" in path
        is_feature = "/features/" in path
        is_core_shared = bool(re.match(r"^lib/(core|shared)/", path))
        layer_match = _TOP_LAYER.match(path)
        layer = layer_match.group(1) if layer_match else ""

        for i, line in enumerate(lines, start=1):
            loc = f"{path}:{i}"

            # 1. domain/ must stay framework-free.
            if is_domain and _FORBIDDEN_IN_DOMAIN.match(line):
                pkg_match = _DOMAIN_PKG.search(line)
                pkg = pkg_match.group(1) if pkg_match else "a framework package"
                _error(
                    "domain imports a framework package",
                    loc,
                    f"domain/ must compile as plain Dart — found {pkg}. Move "
                    "the type to data/, or depend on a domain abstraction "
                    "instead.",
                )

            # 2. presentation/ must not reach into data/. An import of another
            #    feature's data/ is a cross-feature violation and is reported by
            #    rule 3 — reporting it here too would count one import twice.
            if is_presentation and _DATA_IMPORT.match(line):
                other = _DATA_OTHER.search(line)
                if not (other and own and other.group(1) != own):
                    _error(
                        "presentation imports data",
                        loc,
                        f"{line.lstrip()} — go through the domain contract or "
                        "a use case.",
                    )

            # 3. Features are islands: no importing another feature's data/ or
            #    presentation/.
            if is_feature and own and _CROSS_FEATURE.match(line):
                other_m = _CROSS_OTHER_PKG.search(line) or _CROSS_OTHER_REL.search(
                    line
                )
                other = other_m.group(1) if other_m else None
                if other and other != own:
                    _error(
                        "cross-feature import",
                        loc,
                        f"feature '{own}' reaches into '{other}' internals. "
                        "Promote the shared piece to shared/ or core/, or "
                        "expose a domain contract.",
                    )

            # 4. core/ and shared/ must not depend on features.
            if is_core_shared and _FEATURES_IMPORT.match(line):
                _error(
                    f"{layer}/ depends on a feature",
                    loc,
                    f"{layer}/ is shared infrastructure — feature-specific "
                    "code belongs in that feature.",
                )

            # 4b. features/ must not depend on app/.
            if path.startswith("lib/features/") and _APP_IMPORT.match(line):
                _error(
                    "a feature depends on app/",
                    loc,
                    "app/ composes features, never the reverse. A provider the "
                    "feature needs belongs in its own di/, declared as the "
                    "domain contract and bound at the root; a constant both "
                    "sides speak belongs in core/.",
                )

            # 5. Swallowed exceptions.
            if _EMPTY_CATCH.search(line):
                _error(
                    "swallowed exception",
                    loc,
                    "catch with an empty body. Catch the specific type and log "
                    "it, or let it propagate.",
                )

            # 6. print() in library code.
            if _PRINT.search(line) and "debugPrint" not in line:
                _error(
                    "print() in lib/",
                    loc,
                    "use dart:developer's log(). print() is banned and cannot "
                    "be filtered or redacted.",
                )


# 7. File naming — role suffix per directory. (fragment, allowed suffixes)
_SUFFIX_RULES: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("/presentation/screens/", ("_screen.dart",)),
    ("/presentation/controllers/", ("_controller.dart",)),
    ("/presentation/states/", ("_state.dart",)),
    ("/presentation/widgets/", ("_widget.dart",)),
    ("/domain/entities/", ("_entity.dart",)),
    ("/domain/repositories/", ("_repository.dart",)),
    ("/domain/usecases/", ("_use_case.dart",)),
    # CLAUDE.md's domain suffix table also admits _scheduler and _mode, and
    # Study keeps its Strategy files (study_mode.dart, sm2_scheduler.dart, …)
    # under models/ — recorded in wbs.md M-task outputs, the AD-18 dispatch
    # table, and AD-18's boundary section, which all name `domain/models/`.
    ("/domain/models/", ("_model.dart", "_mode.dart", "_scheduler.dart")),
    ("/domain/failures/", ("_failure.dart",)),
    ("/data/mappers/", ("_mapper.dart",)),
    ("/data/repositories/", ("_repository_impl.dart",)),
    ("/data/datasources/", ("_dao.dart", "_data_source.dart")),
    ("/data/models/", ("_model.dart",)),
    ("/presentation/providers/", ("_provider.dart",)),
    ("/di/", ("_provider.dart", "_bindings.dart")),
)


def _check_suffixes(files: list[tuple[str, list[str]]]) -> None:
    for fragment, allowed in _SUFFIX_RULES:
        expected = " ".join(allowed)
        for path, _lines in files:
            if fragment not in path:
                continue
            base = path.rsplit("/", 1)[-1]
            if any(base.endswith(suffix) for suffix in allowed):
                continue
            _warn(
                "naming convention",
                path,
                f"files under {fragment} should end in one of: {expected} — "
                "so the role is visible at the import site.",
            )


def _check_file_sizes(files: list[tuple[str, list[str]]]) -> None:
    # 8. Oversized files. `wc -l` counts newlines, so a 401-line file has 400
    #    of them if it ends in one; the boundary is kept identical by counting
    #    lines the same way the bash version did (`-le 400` passes).
    for path, lines in files:
        # splitlines() already dropped the trailing newline's empty element,
        # matching `wc -l` for a file that ends in a newline.
        count = len(lines)
        if count <= 400:
            continue
        _warn(
            "large file",
            path,
            f"{count} lines — likely more than one responsibility. Split by "
            "section or by role.",
        )


def _check_scope(files: list[tuple[str, list[str]]], lib: str) -> None:
    # 9. Scope. Every rule above selects files by path fragment, so a folder
    #    rename turns the whole check into rules that pass because they looked
    #    at nothing. Zero is a hard failure.
    paths = [p for p, _ in files]
    scopes = {
        "all": len(paths),
        "features": sum("/features/" in p for p in paths),
        "domain": sum("/domain/" in p for p in paths),
        "data": sum("/data/" in p for p in paths),
        "presentation": sum("/presentation/" in p for p in paths),
        "di": sum("/di/" in p for p in paths),
    }
    print("-" * 60)
    print(
        f"scanned {scopes['all']} files under {lib} — features "
        f"{scopes['features']} (domain {scopes['domain']}, data {scopes['data']}"
        f", presentation {scopes['presentation']}, di {scopes['di']})"
    )
    for name, count in scopes.items():
        if count > 0:
            continue
        _error(
            f"zero scope: {name}",
            lib,
            "No file matched, so every rule scoped to it passed without "
            "inspecting anything. Either the layer was removed or the path "
            "changed.",
        )


def main() -> int:
    repo_root = _repo_root()
    lib_dir = repo_root / "lib"
    if not lib_dir.is_dir():
        # A skip before the project exists is honest; a skip after it exists is
        # this script reporting success for having looked at nothing.
        if (repo_root / "pubspec.yaml").is_file():
            print(
                "No lib/ directory, but pubspec.yaml exists — the project is "
                "created and\nthis script found nothing to inspect. That is a "
                "failure, not a skip.",
                file=sys.stderr,
            )
            return 1
        print(
            "No lib/ directory and no pubspec.yaml — nothing to check yet\n"
            "(expected before Phase 2.3)."
        )
        return 0

    files = _dart_files(lib_dir, repo_root)
    _check_imports(files)
    _check_suffixes(files)
    _check_file_sizes(files)
    _check_scope(files, "lib")

    print("-" * 60)
    if _violations == 0:
        print(f"{_GRN}✓{_OFF} architecture boundaries clean")
        return 0
    print(f"{_RED}✗{_OFF} {_violations} boundary violation(s)")
    return 1


def _repo_root() -> Path:
    try:
        top = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        if top:
            return Path(top)
    except (OSError, subprocess.CalledProcessError):
        pass
    return Path.cwd()


if __name__ == "__main__":
    sys.exit(main())
