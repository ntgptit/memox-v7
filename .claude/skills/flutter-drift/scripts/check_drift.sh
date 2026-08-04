#!/usr/bin/env bash
# Thin wrapper around check_drift.py, matching check_architecture.sh: one Python
# process instead of a pile of `find`/`grep` forks, and kept as `.sh` so every
# caller and every doc that names it keeps working.
#
# Usage: check_drift.sh [--quiet] [--diff]
#   --quiet  print only when there is something wrong
#   --diff   restrict findings to files changed against HEAD
# Exit:  0 clean (notes do not fail), 1 errors found.
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$here/check_drift.py" "$@"
