#!/usr/bin/env bash
# Mechanical half of the Definition of Done.
# Runs format check, analyzer, architecture boundaries and tests.
# Exits non-zero if any gate fails, so it is safe to wire into CI or a hook.
#
# Usage: .claude/skills/flutter-workflow/scripts/dod_check.sh [--fix]
#   --fix  apply `dart format` instead of only reporting drift

set -uo pipefail

FIX=0
[[ "${1:-}" == "--fix" ]] && FIX=1

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
if [[ -x "$ARCH_CHECK" ]]; then
  step "architecture boundaries"
  "$ARCH_CHECK" || FAILED+=("architecture")
else
  SKIPPED+=("architecture (script not executable at $ARCH_CHECK)")
fi

# ------------------------------------------------ code verification guard
# The project's main guard. Owns every check flutter analyze cannot express —
# layer boundaries, Riverpod usage, design tokens, memox data invariants —
# including the rules riverpod_lint covered before it was descoped.
GUARD_RUNNER="$REPO_ROOT/code-verification-guard-v2/guard/run.py"
if [[ -f "$GUARD_RUNNER" ]]; then
  if command -v python >/dev/null 2>&1; then
    step "code verification guard (memox-v7)"
    python "$GUARD_RUNNER" check --project "$REPO_ROOT" --ruleset memox-v7 \
      || FAILED+=("guard — see the rule ids above")
  else
    SKIPPED+=("guard (python not on PATH)")
  fi
else
  SKIPPED+=("guard (not vendored at $GUARD_RUNNER)")
fi

# ------------------------------------------------------------------ test
if command -v flutter >/dev/null 2>&1; then
  if [[ -d test ]]; then
    step "flutter test"
    flutter test || FAILED+=("test")
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
