#!/usr/bin/env bash
# Thin wrapper. The check itself is `check_generated.py` — one process instead
# of the per-source part-directive grep loop this used to be (~135 forks). On
# Windows git-bash the `--skip-rebuild` path took 52 seconds; the Python does it
# in ~0.6s and is identical on every check (proven by fault injection when it
# landed). The clean-rebuild path (no --skip-rebuild) still shells out to
# `dart run build_runner`, now with a try/finally that regenerates a usable tree
# if an interrupted rebuild leaves it half-deleted. Kept as `.sh` so every
# caller keeps working.
#
# Usage: check_generated.sh [--skip-rebuild]
# Exit:  0 clean, 1 problems found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$here/check_generated.py" "$@"
