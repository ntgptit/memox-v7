#!/usr/bin/env bash
# Generated code is fresh, complete, and not committed.
#
# `.gitignore` says CI "runs build_runner and then fails if the tree is dirty".
# That check cannot work as described: generated output is gitignored, so the tree
# is clean whatever the generators did. The reasoning was right and the mechanism
# was not, so this script is the mechanism.
#
# Three things are actually checkable, and together they are what "verified fresh"
# means when the output is not in the repo:
#
#   1. no generated file is tracked by git — otherwise it CAN go stale, and a
#      reviewer would be reading a diff of machine output;
#   2. every `part '…g.dart'` / `.freezed.dart` / `.drift.dart` a source declares
#      exists — a generator that silently skipped a file leaves the part missing,
#      and `flutter analyze` reports it as fifty unrelated errors;
#   3. a full rebuild produces byte-identical output to the incremental one — if
#      it does not, "fresh" is not a property anyone can verify.
#
# Usage: check_generated.sh [--skip-rebuild]
#   --skip-rebuild  run checks 1 and 2 only (rebuild is the slow one)
# Exit: 0 clean, 1 problems found.

set -uo pipefail

SKIP_REBUILD=0
[[ "${1:-}" == "--skip-rebuild" ]] && SKIP_REBUILD=1

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

RED=''; GRN=''; YLW=''; OFF=''
if [[ -t 1 ]]; then RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'; OFF=$'\033[0m'; fi

VIOLATIONS=0
report() { # report <kind> <where> <why>
  VIOLATIONS=$((VIOLATIONS + 1))
  printf '%s✗%s %s\n    %s\n    %s\n' "$RED" "$OFF" "$1" "$2" "$3"
}
note() { printf '%s·%s %s\n' "$YLW" "$OFF" "$1"; }
hr() { printf '%s\n' "------------------------------------------------------------"; }

# Files the generators own. The negations in .gitignore are load-bearing —
# drift names some fixtures *.g.dart — so they are excluded here too.
generated_files() {
  find lib test -type f \
    \( -name '*.g.dart' -o -name '*.freezed.dart' -o -name '*.drift.dart' \
       -o -name '*.mocks.dart' -o -name '*.config.dart' \) \
    2>/dev/null | grep -v '^test/drift/generated/' | sort
}

# ---------------------------------------------------------------------------
# 1. Nothing generated is tracked.
# ---------------------------------------------------------------------------
TRACKED=0
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  TRACKED=$((TRACKED + 1))
  report "generated file is committed" "$file" \
    "Machine output in the repo is output that can go stale, and a diff nobody can review. It is in .gitignore — 'git rm --cached' it."
done < <(git ls-files 2>/dev/null \
  | grep -E '\.(g|freezed|drift|mocks|config)\.dart$' \
  | grep -v '^test/drift/generated/' | grep -v '^drift_schemas/')

# ---------------------------------------------------------------------------
# 1b. Every hand-written source file IS tracked.
#
#     The converse of check 1, and the one that was missing. An ignore rule written
#     for build output can also match a source directory that happens to share its
#     name: `**/failures/`, added for golden-test diffs, silently swallowed
#     `lib/features/deck/domain/failures/` — three source files, never committed.
#     Every local gate passed, because the files were on disk. The first CI run
#     failed to compile, because a fresh checkout is the only place the difference
#     shows.
#
#     `comm` against `git ls-files` rather than `git check-ignore`, so a file that is
#     absent from the index for *any* reason — ignored, or simply never added — is
#     reported. `lib/l10n/generated/` is excluded: it is gen-l10n output and is
#     ignored on purpose.
# ---------------------------------------------------------------------------
UNTRACKED=0
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  UNTRACKED=$((UNTRACKED + 1))
  report "source file is not in git" "$file" \
    "A fresh clone does not have this file, so CI compiles something different from what you are running. Look for a .gitignore pattern written for build output that also matches a source path."
done < <(
  comm -23 \
    <(find lib -name '*.dart' -type f \
        ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.drift.dart' \
        ! -name '*.mocks.dart' ! -name '*.config.dart' 2>/dev/null \
      | grep -v '^lib/l10n/generated/' | sort) \
    <(git ls-files -- 'lib/*.dart' 'lib/**/*.dart' 2>/dev/null | sort)
)

# ---------------------------------------------------------------------------
# 2. Every declared part exists.
#
#    This is the check that actually detects staleness. A source that declares
#    `part 'x.g.dart'` and has no `x.g.dart` beside it means the generator did
#    not run, or ran and skipped this file. Both are the state a fresh clone is
#    in, and both are the state a half-finished build leaves behind.
# ---------------------------------------------------------------------------
DECLARED=0
MISSING=0
while IFS= read -r source; do
  [[ -z "$source" ]] && continue
  dir="$(dirname "$source")"
  while IFS= read -r part; do
    [[ -z "$part" ]] && continue
    DECLARED=$((DECLARED + 1))
    [[ -f "$dir/$part" ]] && continue
    MISSING=$((MISSING + 1))
    report "declared part is missing" "$source -> $part" \
      "Run: dart run build_runner build --delete-conflicting-outputs"
  done < <(grep -oE "^part '[^']+\.(g|freezed|drift)\.dart';" "$source" 2>/dev/null \
    | sed -E "s/^part '//; s/';$//")
done < <(find lib -name '*.dart' -type f \
  ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.drift.dart' 2>/dev/null | sort)

# ---------------------------------------------------------------------------
# 3. A full rebuild changes nothing.
#
#    build_runner is incremental and caches aggressively. If a clean rebuild
#    disagrees with the cached one, then what CI verified is not what a developer
#    is running, and neither of them can be called fresh.
# ---------------------------------------------------------------------------
REBUILD_CHECKED=0
if [[ $SKIP_REBUILD -eq 1 ]]; then
  note "rebuild comparison skipped (--skip-rebuild)"
elif ! command -v dart >/dev/null 2>&1; then
  note "rebuild comparison skipped — dart not on PATH"
else
  BEFORE="$(mktemp)"; AFTER="$(mktemp)"
  trap 'rm -f "$BEFORE" "$AFTER"' EXIT

  hash_generated() { # hash_generated <outfile>
    : > "$1"
    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      printf '%s  %s\n' "$(sha256sum "$file" | cut -d' ' -f1)" "$file" >> "$1"
    done < <(generated_files)
  }

  hash_generated "$BEFORE"
  REBUILD_CHECKED=$(wc -l < "$BEFORE" | tr -d ' ')

  if [[ "$REBUILD_CHECKED" -eq 0 ]]; then
    report "nothing to compare" "lib/, test/" \
      "No generated files exist, so the rebuild check has no subject. Generate first."
  else
    printf 'rebuilding %s generated files from scratch…\n' "$REBUILD_CHECKED"
    if dart run build_runner build --delete-conflicting-outputs >/dev/null 2>&1 \
      || dart run build_runner build >/dev/null 2>&1; then
      hash_generated "$AFTER"
      if ! diff -q "$BEFORE" "$AFTER" >/dev/null 2>&1; then
        report "codegen is not reproducible" "$(diff "$BEFORE" "$AFTER" | head -5 | tr '\n' ' ')" \
          "A clean rebuild disagreed with the incremental one, so what CI verified is not what runs locally."
      fi
    else
      report "build_runner failed" "dart run build_runner build" \
        "Generation must succeed from the current sources; nothing downstream is meaningful until it does."
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Scope. Every check above selects its subjects by pattern, so a rename turns
# them into checks that pass because they looked at nothing.
# ---------------------------------------------------------------------------
hr
SOURCE_COUNT=$(find lib -name '*.dart' -type f \
  ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.drift.dart' 2>/dev/null \
  | grep -vc '^lib/l10n/generated/' || true)
printf 'scanned: %s hand-written sources under lib/, %s declared parts, %s generated files hashed\n' \
  "$SOURCE_COUNT" "$DECLARED" "$REBUILD_CHECKED"

if [[ "$SOURCE_COUNT" -eq 0 ]]; then
  report "zero scope" "lib/" \
    "No hand-written Dart file matched under lib/, so the tracked-source check inspected nothing."
fi

if [[ "$DECLARED" -eq 0 ]]; then
  report "zero scope" "lib/" \
    "No source declares a generated part. Either codegen was removed, or the pattern this script matches has stopped matching — and then every check above passed on nothing."
fi

hr
if [[ $VIOLATIONS -eq 0 ]]; then
  printf '%s✓%s generated code is fresh, complete and uncommitted\n' "$GRN" "$OFF"
  exit 0
fi
printf '%s✗%s %d generated-code problem(s)\n' "$RED" "$OFF" "$VIOLATIONS"
exit 1
