#!/usr/bin/env bash
# The one definition of *what the formatter looks at*, so the local gate and CI
# cannot disagree about it.
#
# **`dart format .` was wrong twice over.** Work on this repo runs in worktrees
# under `.claude/worktrees/`, which are checkouts of this same repository on
# other branches. So `.` handed the formatter another branch's source — a branch
# whose formatting predates a `dart format` bump turned the gate red for code
# that is not in the working tree at all — and it walked into those worktrees'
# `build/` output, where Gradle deletes directories while they are being listed:
#
#   PathNotFoundException: Directory listing failed, path =
#   '.\.claude\worktrees\...\build\app\intermediates\...'
#
# That crash made the local `format` step red on every run for weeks. Being an
# environment fault rather than a formatting one, it was reported and worked
# around each time instead of fixed — and a gate everybody knows is red has
# stopped being a gate.
#
# `git ls-files` answers exactly the right question — which Dart files does
# *this* working tree track — and answers it again by itself when a new
# top-level directory appears. Untracked build output is not listed, the
# worktrees are excluded already, and nothing is hardcoded to go stale.
#
# Cut to the first path segment so the formatter gets a handful of directories
# rather than six hundred paths, which on Windows is the difference between one
# process and "The command line is too long".
#
# **CI runs this too, and that is the point of the file.** It used to run
# `dart format .` on the grounds that a fresh clone has no worktrees, which is
# true and still leaves two definitions of the same check — the shape this repo
# has been bitten by often enough to write down. One definition, one answer,
# both callers.
#
# A repo without git is a fresh unpacked archive, which has no worktrees either,
# so `.` is the right fallback there.
#
# Usage: check_format.sh [--fix]
# Exit:  0 formatted, 1 drift found (or a write failed under --fix).
set -uo pipefail

roots() {
  if ! command -v git >/dev/null 2>&1; then
    echo "."

    return
  fi

  local found
  found=$(git ls-files '*.dart' | cut -d/ -f1 | sort -u | tr '\n' ' ')
  echo "${found:-.}"
}

if ! command -v dart >/dev/null 2>&1; then
  echo "dart not found on PATH — the format gate cannot run here."
  exit 1
fi

# shellcheck disable=SC2046  # word splitting is the point: one argument per root
if [[ "${1:-}" == "--fix" ]]; then
  exec dart format $(roots)
fi

# shellcheck disable=SC2046
exec dart format --output=none --set-exit-if-changed $(roots)
