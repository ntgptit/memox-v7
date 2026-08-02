#!/usr/bin/env bash
# Mechanical half of the Definition of Done.
# Runs format, analyzer, generated-code freshness, the architecture and docs
# guards, the code-verification guard, and tests.
#
# Usage: .claude/skills/flutter-workflow/scripts/dod_check.sh [--fast] [--fix]
#   --fast  the tight-loop mode: run only the Deck + app test subset (what CI's
#           light gate runs), skipping goldens. ~20s instead of ~50s. It does
#           NOT run test/core, test/shared, or another feature's tests — run the
#           full gate (no --fast) before you commit, and always before a merge.
#   --fix   apply `dart format` instead of only reporting drift
#
# The two slow bash guards this used to shell into (architecture, docs) are now
# one-process Python and cost ~1s each; the time here is `flutter analyze` and
# `flutter test`.

set -uo pipefail

FIX=0
FAST=0
for arg in "$@"; do
  case "$arg" in
    --fix) FIX=1 ;;
    --fast) FAST=1 ;;
    *) echo "unknown argument: $arg" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

FAILED=()
SKIPPED=()

hr() { printf '%s\n' "------------------------------------------------------------"; }
step() { hr; printf '▶ %s\n' "$1"; }

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH — Dart gates cannot run here."
  echo "Install Flutter, or run this script in an environment that has it."
  SKIPPED+=("format" "analyze" "test")
fi

if [[ ! -f pubspec.yaml ]]; then
  echo "No pubspec.yaml at $REPO_ROOT — the Flutter project has not been created yet."
  echo "That is expected before Phase 2.3. Nothing to check."
  exit 0
fi

# ---------------------------------------------------------------- format
if command -v dart >/dev/null 2>&1; then
  step "dart format"
  if [[ $FIX -eq 1 ]]; then
    dart format . && echo "formatted"
  else
    dart format --output=none --set-exit-if-changed . \
      || FAILED+=("format — run with --fix, or 'dart format .'")
  fi
fi

# --------------------------------------------------------------- analyze
if command -v flutter >/dev/null 2>&1; then
  step "flutter analyze"
  # --fatal-infos would be stricter than the checklist requires; errors and
  # warnings are the bar, and analysis_options.yaml decides which is which.
  flutter analyze --no-fatal-infos || FAILED+=("analyze")
fi

# ------------------------------------------------------- generated code
# Generated output is gitignored, so nothing else here notices when it is stale,
# missing or — worse — committed. `--skip-rebuild` because the reproducibility
# comparison rebuilds from scratch, which belongs in CI rather than in a gate
# somebody runs before every commit.
GEN_CHECK="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_generated.sh"
if [[ -f "$GEN_CHECK" ]]; then
  step "generated code"
  bash "$GEN_CHECK" --skip-rebuild || FAILED+=("generated code")
else
  SKIPPED+=("generated code (script missing at $GEN_CHECK)")
fi

# ---------------------------------------------- architecture boundaries
ARCH_CHECK="$REPO_ROOT/.claude/skills/flutter-architecture/scripts/check_architecture.sh"
if [[ -f "$ARCH_CHECK" ]]; then
  step "architecture boundaries"
  bash "$ARCH_CHECK" || FAILED+=("architecture")
else
  SKIPPED+=("architecture (script missing at $ARCH_CHECK)")
fi

# ---------------------------------------------------- document integrity
# Cheap now that it is one Python process (~1s), so it belongs in the local
# gate rather than only in CI — a dangling BR reference or a stale WBS
# dependency is caught before the commit, not on the PR.
DOCS_CHECK="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_docs.sh"
if [[ -f "$DOCS_CHECK" ]]; then
  step "document integrity"
  bash "$DOCS_CHECK" --quiet || FAILED+=("docs")
else
  SKIPPED+=("docs (script missing at $DOCS_CHECK)")
fi

# ------------------------------------------------ code verification guard
# The project's main guard. Owns every check flutter analyze cannot express —
# layer boundaries, Riverpod usage, design tokens, memox data invariants —
# including the rules riverpod_lint covered before it was descoped.
GUARD_RUNNER="$REPO_ROOT/code-verification-guard-v2/guard/run.py"
# `python3` as well as `python`. Only `python` was tried, so on a machine where the
# interpreter is named `python3` — most Linux distributions, and the CI runner — the
# project's main guard was *skipped* and this script still printed success. A skip
# that reads as a pass is the same defect as a rule that scans nothing.
GUARD_PY=""
for candidate in python python3; do
  command -v "$candidate" >/dev/null 2>&1 && { GUARD_PY="$candidate"; break; }
done

if [[ ! -f "$GUARD_RUNNER" ]]; then
  SKIPPED+=("guard (not vendored at $GUARD_RUNNER)")
elif [[ -z "$GUARD_PY" ]]; then
  SKIPPED+=("guard (neither python nor python3 on PATH)")
else
  step "code verification guard (memox-v7)"
  "$GUARD_PY" "$GUARD_RUNNER" check --project "$REPO_ROOT" --ruleset memox-v7 \
    || FAILED+=("guard — see the rule ids above")
fi

# ------------------------------------------------------------------ test
if command -v flutter >/dev/null 2>&1; then
  if [[ -d test ]]; then
    if [[ $FAST -eq 1 ]]; then
      step "flutter test (--fast: Deck + app subset, no goldens)"
      flutter test --exclude-tags golden test/app test/features/deck \
        || FAILED+=("test")
    else
      step "flutter test (full suite)"
      flutter test || FAILED+=("test")
    fi
  else
    SKIPPED+=("test (no test/ directory yet)")
  fi
fi

# --------------------------------------------------------------- summary
hr
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  echo "skipped:"
  printf '  - %s\n' "${SKIPPED[@]}"
fi

if [[ $FAST -eq 1 ]]; then
  echo
  echo "⚡ --fast ran the Deck + app subset only. It did NOT run test/core,"
  echo "   test/shared, test/features/<other>, the visual audits, or goldens."
  echo "   Run without --fast before you commit."
fi

if [[ ${#FAILED[@]} -eq 0 ]]; then
  echo "✓ mechanical gates passed"
  echo
  echo "Still needs a human: acceptance criteria, scope match, design fidelity,"
  echo "light/dark, small screen, text scale, loading/empty/error/success,"
  echo "accessibility, and whether docs/wbs.md tells the truth."
  exit 0
fi

echo "✗ failed gates:"
printf '  - %s\n' "${FAILED[@]}"
exit 1
