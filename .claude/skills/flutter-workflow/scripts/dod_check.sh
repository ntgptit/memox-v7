#!/usr/bin/env bash
# Mechanical half of the Definition of Done.
# Runs format, analyzer, generated-code freshness, the architecture and docs
# guards, the code-verification guard, and tests.
#
# Usage: .claude/skills/flutter-workflow/scripts/dod_check.sh
#        [--changed [--base <git-ref>]] [--fast] [--fix]
#   --changed  build the same feature × layer × risk plan as PR CI from the
#              diff against --base (default: origin/main), then run only the
#              selected host tests and Widgetbook surface. Unknown/high-risk
#              paths promote themselves to the full non-golden host suite.
#   --base     comparison ref for --changed; invalid without --changed
#   --fast  the tight-loop mode: run only the Deck + app test subset (what CI's
#           light gate runs), skipping goldens. ~20s instead of ~50s. It does
#           NOT run test/core, test/shared, or another feature's tests — run the
#           full gate (no --fast) before you commit, and always before a merge.
#   --fix   apply `dart format` instead of only reporting drift
#
# ---------------------------------------------------------------------------
# Where the time goes, measured rather than assumed (2026-08-02, this machine):
#
#   flutter test    43s        dart format          3s
#   flutter analyze 10s        guard (python)       2s
#                              3 doc/arch guards    2s
#
# **This file is not the bottleneck and rewriting it in another language does
# not help.** It has no per-file loop and no fork storm — the thing that made
# `check_architecture.sh` take two minutes before it became Python. It starts
# seven subprocesses and prints a summary; the cost is inside those seven.
#
# Two things in here *were* worth fixing, and both are scheduling rather than
# language:
#
#   1. It shelled into `bash check_*.sh`, and each of those wrappers only
#      `exec`s a `.py`. On Windows git-bash that fork measured **286ms**, three
#      times over — nearly a second spent starting shells that immediately
#      replace themselves. The `.py` is called directly now; the `.sh` wrappers
#      stay for everyone else who calls them by name.
#   2. Every gate ran in series although only one pair has an ordering
#      constraint. They run concurrently now, with each step's output buffered
#      and replayed in a fixed order — parallel execution, serial reading, so a
#      failure is still findable.
# ---------------------------------------------------------------------------

set -uo pipefail

FIX=0
FAST=0
CHANGED=0
BASE_REF="origin/main"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix) FIX=1 ;;
    --fast) FAST=1 ;;
    --changed) CHANGED=1 ;;
    --base)
      shift
      [[ $# -gt 0 ]] || { echo "--base requires a git ref" >&2; exit 2; }
      BASE_REF="$1"
      ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [[ $FAST -eq 1 && $CHANGED -eq 1 ]]; then
  echo "--fast and --changed are mutually exclusive" >&2
  exit 2
fi
if [[ $CHANGED -eq 0 && "$BASE_REF" != "origin/main" ]]; then
  echo "--base is only valid with --changed" >&2
  exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

FAILED=()
SKIPPED=()

hr() { printf '%s\n' "------------------------------------------------------------"; }
step() { hr; printf '▶ %s\n' "$1"; }

if [[ ! -f pubspec.yaml ]]; then
  echo "No pubspec.yaml at $REPO_ROOT — the Flutter project has not been created yet."
  echo "That is expected before Phase 2.3. Nothing to check."
  exit 0
fi

# `python3` as well as `python`. Only `python` was tried once, so on a machine
# where the interpreter is named `python3` — most Linux distributions, and the
# CI runner — the project's main guard was *skipped* and this script still
# printed success. A skip that reads as a pass is the same defect as a rule that
# scans nothing.
PY=""
for candidate in python python3; do
  command -v "$candidate" >/dev/null 2>&1 && { PY="$candidate"; break; }
done

WORK="$(mktemp -d 2>/dev/null || echo "${TMPDIR:-/tmp}/dod_$$")"
mkdir -p "$WORK"
trap 'rm -rf "$WORK"' EXIT

NEEDS_STATIC=1
NEEDS_HOST_TESTS=1
NEEDS_WIDGETBOOK=0
HAS_PROMPT_CHANGES=0
PLAN_JSON="$WORK/verification-plan.json"

if [[ $CHANGED -eq 1 ]]; then
  if [[ -z "$PY" ]]; then
    echo "python is required to build a changed-scope verification plan" >&2
    exit 1
  fi
  git rev-parse --verify "$BASE_REF^{commit}" >/dev/null 2>&1 || {
    echo "cannot resolve --base ref: $BASE_REF" >&2
    exit 2
  }
  {
    # Include type changes (`T`), otherwise a mixed docs + script-to-symlink
    # change can hide the high-risk path and incorrectly select docs-only.
    git diff --name-only --diff-filter=ACMRTD -z "$BASE_REF" --
    git ls-files --others --exclude-standard -z
  } >"$WORK/changed-paths.nul"
  PLAN_BUILDER="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/build_verification_plan.py"
  "$PY" "$PLAN_BUILDER" --root "$REPO_ROOT" --nul \
    --paths-file "$WORK/changed-paths.nul" --json-output "$PLAN_JSON" || exit 1

  read_plan_bool() {
    "$PY" -c "import json,sys; print('1' if json.load(open(sys.argv[1], encoding='utf-8'))[sys.argv[2]] else '0')" "$PLAN_JSON" "$1"
  }
  NEEDS_STATIC="$(read_plan_bool needs_static)"
  NEEDS_HOST_TESTS="$(read_plan_bool needs_host_tests)"
  NEEDS_WIDGETBOOK="$(read_plan_bool needs_widgetbook)"
  HAS_PROMPT_CHANGES="$(read_plan_bool has_prompt_changes)"
  "$PY" -c "import json,sys; p=json.load(open(sys.argv[1], encoding='utf-8')); print('verification plan:', p['risk'], '·', len(p['test_files']), 'files · weight', p['estimated_test_weight'], '· CI shards', p['shard_count']); [print('  -', r) for r in p['reasons']]" "$PLAN_JSON"
fi

NEEDS_FLUTTER=0
if [[ $NEEDS_STATIC -eq 1 || $NEEDS_HOST_TESTS -eq 1 || $NEEDS_WIDGETBOOK -eq 1 ]]; then
  NEEDS_FLUTTER=1
fi

if [[ $NEEDS_FLUTTER -eq 1 ]] && ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found on PATH — selected Dart gates cannot run here."
  echo "Install Flutter, or run this script in an environment that has it."
  FAILED+=("flutter unavailable for selected mandatory gates")
fi

# ------------------------------------------------------------ the schedule
# name | label | command. Order here is the order results are printed, which is
# deliberately not the order they finish.
NAMES=()
LABELS=()
CMDS=()

plan() { NAMES+=("$1"); LABELS+=("$2"); CMDS+=("$3"); }

# **What the formatter looks at is `check_format.sh`'s to decide, not this
# file's.** It was inlined here first and CI kept its own `dart format .`, which
# is two definitions of one check — and the pair only agreed by luck, because a
# fresh CI clone happens to have no worktrees. The script is the single answer
# both callers ask; its header carries the reasoning.
#
# `--fix` writes files, so it cannot share a window with the analyzer or the
# tests reading them. It runs alone, first, before anything is scheduled.
FMT_SH="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_format.sh"
if [[ $NEEDS_STATIC -eq 0 ]]; then
  :
elif [[ ! -f "$FMT_SH" ]]; then
  FAILED+=("format script missing at $FMT_SH")
elif [[ $FIX -eq 1 ]]; then
  step "dart format --fix"
  if bash "$FMT_SH" --fix; then
    echo "formatted"
  else
    FAILED+=("format --fix")
  fi
else
  plan format "dart format" "bash '$FMT_SH'"
fi

if [[ $NEEDS_STATIC -eq 1 ]] && command -v flutter >/dev/null 2>&1; then
  # --fatal-infos would be stricter than the checklist requires; errors and
  # warnings are the bar, and analysis_options.yaml decides which is which.
  plan analyze "flutter analyze" "flutter analyze --no-fatal-infos"
fi

# Generated output is gitignored, so nothing else here notices when it is stale,
# missing or — worse — committed. `--skip-rebuild` because the reproducibility
# comparison rebuilds from scratch, which belongs in CI rather than in a gate
# somebody runs before every commit.
GEN_PY="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_generated.py"
if [[ $NEEDS_STATIC -eq 0 ]]; then
  :
elif [[ -n "$PY" && -f "$GEN_PY" ]]; then
  plan generated "generated code" "$PY '$GEN_PY' --skip-rebuild"
else
  FAILED+=("generated code gate unavailable: $GEN_PY")
fi

ARCH_PY="$REPO_ROOT/.claude/skills/flutter-architecture/scripts/check_architecture.py"
if [[ $NEEDS_STATIC -eq 0 ]]; then
  :
elif [[ -n "$PY" && -f "$ARCH_PY" ]]; then
  plan architecture "architecture boundaries" "$PY '$ARCH_PY'"
else
  FAILED+=("architecture gate unavailable: $ARCH_PY")
fi

# Cheap now that it is one Python process, so it belongs in the local gate
# rather than only in CI — a dangling BR reference or a stale WBS dependency is
# caught before the commit, not on the PR.
DOCS_PY="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_docs.py"
if [[ -n "$PY" && -f "$DOCS_PY" ]]; then
  plan docs "document integrity" "$PY '$DOCS_PY' --quiet"
else
  FAILED+=("document gate unavailable: $DOCS_PY")
fi

CI_TOOLING_TESTS="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/tests"
if [[ -n "$PY" && -d "$CI_TOOLING_TESTS" ]]; then
  plan ci_tooling "CI tooling unit tests" \
    "$PY -m unittest discover -s '$CI_TOOLING_TESTS' -p 'test_*.py'"
else
  FAILED+=("CI tooling tests unavailable: $CI_TOOLING_TESTS")
fi

PROMPT_GUARD="$REPO_ROOT/.claude/skills/flutter-workflow/scripts/check_prompt_contract.py"
if [[ $HAS_PROMPT_CHANGES -eq 1 ]]; then
  if [[ -n "$PY" && -f "$PROMPT_GUARD" ]]; then
    plan prompt_contract "prompt delivery contract" "$PY '$PROMPT_GUARD'"
  else
    FAILED+=("prompt contract gate unavailable: $PROMPT_GUARD")
  fi
fi

# The project's main guard. Owns every check flutter analyze cannot express —
# layer boundaries, Riverpod usage, design tokens, memox data invariants —
# including the rules riverpod_lint covered before it was descoped.
GUARD_RUNNER="$REPO_ROOT/code-verification-guard-v2/guard/run.py"
if [[ $NEEDS_STATIC -eq 0 ]]; then
  :
elif [[ ! -f "$GUARD_RUNNER" ]]; then
  FAILED+=("code verification guard missing at $GUARD_RUNNER")
elif [[ -z "$PY" ]]; then
  FAILED+=("code verification guard cannot run without python")
else
  plan guard "code verification guard (memox-v7)" \
    "$PY '$GUARD_RUNNER' check --project '$REPO_ROOT' --ruleset memox-v7"
fi

if [[ $NEEDS_HOST_TESTS -eq 1 ]] && command -v flutter >/dev/null 2>&1; then
  if [[ ! -d test ]]; then
    FAILED+=("selected host tests unavailable: no test/ directory")
  elif [[ $CHANGED -eq 1 ]]; then
    mapfile -d '' CHANGED_TEST_TARGETS < <(
      "$PY" -c "import json,sys; p=json.load(open(sys.argv[1], encoding='utf-8')); sys.stdout.buffer.write(b'\\0'.join(x.encode() for x in p['local_test_targets']) + b'\\0')" "$PLAN_JSON"
    )
    if [[ ${#CHANGED_TEST_TARGETS[@]} -eq 0 ]]; then
      FAILED+=("test plan selected no test files")
    else
      printf -v QUOTED_TEST_TARGETS " %q" "${CHANGED_TEST_TARGETS[@]}"
      plan test "flutter test (--changed: ${#CHANGED_TEST_TARGETS[@]} compressed targets, no goldens)" \
        "flutter test --exclude-tags golden${QUOTED_TEST_TARGETS}"
    fi
  elif [[ $FAST -eq 1 ]]; then
    plan test "flutter test (--fast: Deck + app subset, no goldens)" \
      "flutter test --exclude-tags golden test/app test/features/deck"
  else
    plan test "flutter test (full suite)" "flutter test"
  fi
fi


if [[ $NEEDS_WIDGETBOOK -eq 1 ]] && command -v flutter >/dev/null 2>&1; then
  if [[ -d widgetbook ]]; then
    plan widgetbook "Widgetbook smoke test" \
      "(cd '$REPO_ROOT/widgetbook' && flutter test --reporter failures-only)"
  else
    FAILED+=("selected Widgetbook gate unavailable: $REPO_ROOT/widgetbook")
  fi
fi

# ------------------------------------------------------------- run them all
# Output is captured per step rather than streamed. Interleaved output from
# seven concurrent processes is unreadable exactly when it matters — when
# something failed and you are looking for which line said so.
for i in "${!NAMES[@]}"; do
  {
    eval "${CMDS[$i]}" >"$WORK/${NAMES[$i]}.log" 2>&1
    printf '%s' "$?" >"$WORK/${NAMES[$i]}.rc"
  } &
done
wait

for i in "${!NAMES[@]}"; do
  step "${LABELS[$i]}"
  cat "$WORK/${NAMES[$i]}.log"
  if [[ "$(cat "$WORK/${NAMES[$i]}.rc" 2>/dev/null || echo 1)" != "0" ]]; then
    case "${NAMES[$i]}" in
      format) FAILED+=("format — run with --fix, or 'dart format .'") ;;
      guard)  FAILED+=("guard — see the rule ids above") ;;
      *)      FAILED+=("${NAMES[$i]}") ;;
    esac
  fi
done

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

if [[ $CHANGED -eq 1 ]]; then
  echo
  echo "⚙ --changed used the sealed verification plan against $BASE_REF."
  echo "   Unknown and high-risk paths automatically promoted to the full host suite."
  echo "   Run without --changed for the final full local gate when required by release policy."
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
