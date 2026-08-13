#!/usr/bin/env bash
set -euo pipefail

# Flutter's Linux test runner asks for lowercase material-font paths while the
# SDK artifact uses mixed-case filenames. Prepare both spellings once per job
# and fail with a toolchain error instead of hundreds of misleading widget-test
# failures.
flutter precache --force --universal
fonts="$FLUTTER_ROOT/bin/cache/artifacts/material_fonts"
cd "$fonts"
for file in *; do
  lower="$(printf '%s' "$file" | tr '[:upper:]' '[:lower:]')"
  [ "$file" = "$lower" ] && continue
  [ -e "$lower" ] && continue
  ln -s "$file" "$lower"
done

if [ ! -f "$fonts/roboto-regular.ttf" ]; then
  echo "::error::material fonts unreachable after precache — the toolchain is incomplete, not the project"
  ls -la "$fonts" || true
  exit 1
fi
echo "material fonts reachable at $fonts/roboto-regular.ttf"
