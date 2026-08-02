#!/usr/bin/env bash
# Thin wrapper. The check itself is `check_architecture.py` — one process
# instead of the seventeen `find lib` forks and the per-file subprocess loops
# this used to be. On Windows git-bash each fork costs tens of milliseconds and
# the bash version took two minutes; the Python finishes in under a second and
# is byte-for-byte identical on every rule (proven by fault injection when it
# landed). Kept as `.sh` so every `bash …/check_architecture.sh` caller and
# every doc that names it keeps working.
#
# Usage: check_architecture.sh [--quiet]
# Exit:  0 clean, 1 violations found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python "$here/check_architecture.py" "$@"
