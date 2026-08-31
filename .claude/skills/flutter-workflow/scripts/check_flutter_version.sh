#!/usr/bin/env bash
# The Flutter on PATH is the Flutter `.fvmrc` names.
#
# **The debt this closes was recorded at M2.2 and had already happened once:**
# M2.1 ran on 3.44.8, the next session started on 3.44.6, and nothing noticed.
# `.fvmrc` declared a version that nothing enforced, so it was documentation
# rather than a pin.
#
# CI closed half of it — both jobs use `flutter-version-file: .fvmrc`, so the
# runner cannot drift. The half left open was the developer machine, which is
# where the drift actually happened.
#
# **Why this is a planned gate and not a preflight check.** `dod_check.sh`
# stamps a successful run and short-circuits an unchanged tree in ~0.4s; its
# header explains that the stamp deliberately cannot see an SDK swapped under an
# unchanged `.fvmrc`, because paying `flutter --version` on every invocation
# would cost most of what the stamp saves. So this runs where the other gates
# run — only when the gate is actually running — and costs nothing on a cached
# invocation. The hole the stamp leaves is unchanged and still documented there;
# what closes now is the case where the gate runs at all.
#
# Usage: check_flutter_version.sh
# Exit:  0 match (or no `.fvmrc`), 1 mismatch or Flutter missing.
set -uo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$here" rev-parse --show-toplevel 2>/dev/null || pwd)"
fvmrc="$repo_root/.fvmrc"

if [[ ! -f "$fvmrc" ]]; then
  echo "no .fvmrc — nothing pinned, nothing to check"
  exit 0
fi

# Deliberately not a JSON parser: the file is two lines written by fvm and a
# grep keeps this script free of a python dependency the other gates already
# pay for.
want="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$fvmrc" | head -1)"
if [[ -z "$want" ]]; then
  echo "✗ .fvmrc exists but names no flutter version — the pin is not a pin" >&2
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "✗ .fvmrc pins Flutter $want but no flutter is on PATH" >&2
  exit 1
fi

# `flutter --version` prints "Flutter 3.44.8 • channel …" on the first line.
have="$(flutter --version 2>/dev/null | sed -n 's/^Flutter \([0-9][^ ]*\).*/\1/p' | head -1)"
if [[ -z "$have" ]]; then
  echo "✗ could not read a version out of 'flutter --version'" >&2
  exit 1
fi

if [[ "$have" != "$want" ]]; then
  cat >&2 <<EOF
✗ Flutter $have is on PATH, but .fvmrc pins $want.

  This is the failure M2.2 recorded: a session ran 3.44.8, the next started on
  3.44.6, and nothing said so. Generated code, analyzer output and golden
  rasterisation all move between versions, so a green gate on the wrong SDK is
  a green gate about a different project.

  Fix by switching the SDK (fvm use $want), not by editing .fvmrc — CI reads
  the same file through flutter-version-file, so editing it moves the runner
  too.
EOF
  exit 1
fi

echo "Flutter $have matches .fvmrc"
