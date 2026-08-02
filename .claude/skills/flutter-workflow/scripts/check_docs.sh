#!/usr/bin/env bash
# Thin wrapper. The check itself is `check_docs.py` — one process instead of the
# dozens of awk/grep/find forks and the per-file grep loop in section D this
# used to be. On Windows git-bash each fork costs tens of milliseconds and the
# bash version took 134 seconds; the Python finishes in ~1s and is byte-for-byte
# identical on every check (proven by fault injection when it landed). C1/C2
# still delegate to verify_invariants.py unchanged. Kept as `.sh` so every
# caller and every doc that names it keeps working.
#
# Usage: check_docs.sh [--db <path-to-sqlite-db>] [--quiet]
# Exit:  0 clean, 1 problems found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$here/check_docs.py" "$@"
