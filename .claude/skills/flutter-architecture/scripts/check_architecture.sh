#!/usr/bin/env bash
# Verifies the layer boundaries and code-style rules that the Dart analyzer
# cannot express. Import direction is an architectural property, not a lint,
# so it needs its own check — and one that runs in CI, because a boundary
# nobody verifies is a boundary that has already broken.
#
# Usage: .claude/skills/flutter-architecture/scripts/check_architecture.sh [--quiet]
# Exit:  0 clean, 1 violations found.

set -uo pipefail

QUIET=0
[[ "${1:-}" == "--quiet" ]] && QUIET=1

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

LIB="lib"
if [[ ! -d "$LIB" ]]; then
  echo "No lib/ directory — nothing to check yet (expected before Phase 2.3)."
  exit 0
fi

VIOLATIONS=0
RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; DIM=$'\033[2m'; OFF=$'\033[0m'
[[ -t 1 ]] || { RED=""; YEL=""; GRN=""; DIM=""; OFF=""; }

report() { # report <severity> <rule> <file:line> <detail>
  local sev="$1" rule="$2" loc="$3" detail="$4"
  if [[ "$sev" == "error" ]]; then
    VIOLATIONS=$((VIOLATIONS + 1))
    printf '%s✗%s %s\n    %s%s%s\n    %s\n' "$RED" "$OFF" "$rule" "$DIM" "$loc" "$OFF" "$detail"
    return
  fi
  [[ $QUIET -eq 1 ]] || printf '%s!%s %s\n    %s%s%s\n    %s\n' "$YEL" "$OFF" "$rule" "$DIM" "$loc" "$OFF" "$detail"
}

# Source files only — generated code is excluded because we do not control its
# imports and it is regenerated anyway.
dart_files() {
  find "$LIB" -name '*.dart' \
    ! -name '*.g.dart' ! -name '*.freezed.dart' ! -name '*.mocks.dart' \
    -type f 2>/dev/null | sort
}

# ---------------------------------------------------------------------------
# 1. domain/ must stay framework-free.
#    freezed_annotation and meta are allowed: they are pure-Dart annotation
#    packages with no framework dependency. json_annotation is not —
#    serialization is a data-layer concern and its presence in domain means a
#    DTO has been modelled as an entity.
# ---------------------------------------------------------------------------
FORBIDDEN_IN_DOMAIN='package:flutter/|package:flutter_riverpod/|package:riverpod|package:dio/|package:drift/|package:sqlite|package:json_annotation/|package:go_router/|package:path_provider/|package:shared_preferences/|package:flutter_secure_storage/|dart:ui'

while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  while IFS=: read -r lineno line; do
    [[ -z "$lineno" ]] && continue
    pkg="$(printf '%s' "$line" | sed -E "s/.*(package:[a-z_0-9]+|dart:ui).*/\1/")"
    report error "domain imports a framework package" "$file:$lineno" \
      "domain/ must compile as plain Dart — found $pkg. Move the type to data/, or depend on a domain abstraction instead."
  done < <(grep -nE "^\s*import\s+'($FORBIDDEN_IN_DOMAIN)" "$file" 2>/dev/null)
done < <(dart_files | grep '/domain/')

# ---------------------------------------------------------------------------
# 2. presentation/ must not reach into data/.
#    Presentation talks to use cases or repository contracts. An import of
#    data/ means the UI is coupled to a DTO, a Drift table or a Dio call.
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  own="$(printf '%s' "$file" | sed -nE 's#^lib/features/([^/]+)/.*#\1#p')"
  while IFS=: read -r lineno line; do
    [[ -z "$lineno" ]] && continue
    # An import of *another* feature's data/ is a cross-feature violation and is
    # reported by rule 3. Reporting it here too would count one import twice.
    other="$(printf '%s' "$line" | sed -nE 's#.*features/([a-z_0-9]+)/data/.*#\1#p')"
    [[ -n "$other" && "$other" != "$own" ]] && continue
    report error "presentation imports data" "$file:$lineno" \
      "$(printf '%s' "$line" | sed -E 's/^\s+//') — go through the domain contract or a use case."
  done < <(grep -nE "^\s*import\s+'[^']*(/data/|\.\./data/)" "$file" 2>/dev/null)
done < <(dart_files | grep '/presentation/')

# ---------------------------------------------------------------------------
# 3. Features are islands: no importing another feature's data/ or
#    presentation/. Handles both package: and relative import forms.
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  own="$(printf '%s' "$file" | sed -E 's#^lib/features/([^/]+)/.*#\1#')"
  [[ -z "$own" || "$own" == "$file" ]] && continue

  while IFS=: read -r lineno line; do
    [[ -z "$lineno" ]] && continue
    # package:app/features/<other>/<layer>/...
    other="$(printf '%s' "$line" | sed -nE "s#.*features/([a-z_0-9]+)/(data|presentation)/.*#\1#p")"
    # ../../<other>/<layer>/...  (relative sibling-feature import)
    [[ -z "$other" ]] && other="$(printf '%s' "$line" | sed -nE "s#.*\.\./\.\./([a-z_0-9]+)/(data|presentation)/.*#\1#p")"
    [[ -z "$other" || "$other" == "$own" ]] && continue
    report error "cross-feature import" "$file:$lineno" \
      "feature '$own' reaches into '$other' internals. Promote the shared piece to shared/ or core/, or expose a domain contract."
  done < <(grep -nE "^\s*import\s+'[^']*(features/[a-z_0-9]+/(data|presentation)/|\.\./\.\./[a-z_0-9]+/(data|presentation)/)" "$file" 2>/dev/null)
done < <(dart_files | grep '/features/')

# ---------------------------------------------------------------------------
# 4. core/ and shared/ must not depend on features. They are the base of the
#    dependency graph; an edge back up to a feature creates a cycle and makes
#    core/ unusable by any other feature.
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  layer="$(printf '%s' "$file" | sed -E 's#^lib/([^/]+)/.*#\1#')"
  while IFS=: read -r lineno line; do
    [[ -z "$lineno" ]] && continue
    report error "$layer/ depends on a feature" "$file:$lineno" \
      "$layer/ is shared infrastructure — feature-specific code belongs in that feature."
  done < <(grep -nE "^\s*import\s+'[^']*features/" "$file" 2>/dev/null)
done < <(dart_files | grep -E '^lib/(core|shared)/')

# ---------------------------------------------------------------------------
# 5. Swallowed exceptions. `catch (_) {}` reports a failure as "nothing
#    happened", which is the hardest defect class to diagnose in the field.
# ---------------------------------------------------------------------------
while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  file="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"
  report error "swallowed exception" "$file:$lineno" \
    "catch with an empty body. Catch the specific type and log it, or let it propagate."
done < <(dart_files | xargs grep -nE 'catch\s*\([^)]*\)\s*\{\s*\}' 2>/dev/null)

# ---------------------------------------------------------------------------
# 6. print() in library code. `print` is banned by analysis_options.yaml; the
#    supported alternative is `dart:developer`'s `log`, which the two diagnostics
#    in core/ already use (core/state/provider_observer.dart,
#    core/database/query_log_interceptor.dart). There is deliberately no
#    core/logging abstraction — bootstrap.dart records why, and this message used
#    to point at that directory as though it existed.
# ---------------------------------------------------------------------------
while IFS= read -r hit; do
  [[ -z "$hit" ]] && continue
  file="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"
  report error "print() in lib/" "$file:$lineno" \
    "use dart:developer's log(). print() is banned and cannot be filtered or redacted."
done < <(dart_files | xargs grep -nE '(^|[^.\w])print\s*\(' 2>/dev/null | grep -v 'debugPrint')

# ---------------------------------------------------------------------------
# 7. File naming. Files in a role-specific directory should carry the matching
#    suffix, so the role is readable from an import line.
# ---------------------------------------------------------------------------
check_suffix() { # check_suffix <dir-fragment> <suffix> [more suffixes...]
  local fragment="$1"; shift
  local allowed=("$@")
  # Joined before the loop: `while IFS= read` leaves IFS empty inside the body,
  # so expanding the array there would print only its first element.
  local expected="${allowed[*]}"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    base="$(basename "$file")"
    local ok=0
    for suffix in "${allowed[@]}"; do
      if [[ "$base" == *"$suffix" ]]; then ok=1; break; fi
    done
    [[ $ok -eq 1 ]] && continue
    report warn "naming convention" "$file" \
      "files under $fragment should end in one of: $expected — so the role is visible at the import site."
  done < <(dart_files | grep "$fragment")
}
# Plural, because that is the folder naming the features use and the industry
# convention they follow. These were singular until M4.10 and therefore matched
# **zero files** — the check ran, found nothing to look at, and passed. A check
# that cannot fail is worse than no check: it reads as coverage.
check_suffix '/presentation/screens/'     '_screen.dart'
check_suffix '/presentation/controllers/' '_controller.dart'
check_suffix '/presentation/states/'      '_state.dart'
check_suffix '/presentation/widgets/'     '_widget.dart'
check_suffix '/domain/entities/'          '_entity.dart'
check_suffix '/domain/repositories/'      '_repository.dart'
check_suffix '/domain/usecases/'          '_use_case.dart'
check_suffix '/domain/models/'            '_model.dart'
check_suffix '/domain/failures/'          '_failure.dart'
check_suffix '/data/mappers/'             '_mapper.dart'
check_suffix '/data/repositories/'        '_repository_impl.dart'
# Two suffixes because the guard's data list admits both, and which one is right
# depends on what the source is: a Drift DAO is a `_dao`, anything else is a
# `_data_source`.
check_suffix '/data/datasources/'         '_dao.dart' '_data_source.dart'
check_suffix '/data/models/'              '_model.dart'
# `_provider` is for dependency wiring only. Anything holding submit state or a
# command is a `_controller` and belongs in `presentation/controllers/` — the
# guard's widget scope exempts files by that suffix, so the distinction decides
# which rules apply.
check_suffix '/presentation/providers/'   '_provider.dart'

# ---------------------------------------------------------------------------
# 8. Oversized files. Not a hard failure — a legitimately long generated-ish
#    file exists — but past ~400 lines a Dart source file usually holds more
#    than one responsibility.
# ---------------------------------------------------------------------------
while IFS= read -r file; do
  [[ -z "$file" ]] && continue
  lines=$(wc -l < "$file" | tr -d ' ')
  [[ "$lines" -le 400 ]] && continue
  report warn "large file" "$file" \
    "$lines lines — likely more than one responsibility. Split by section or by role."
done < <(dart_files)

# ---------------------------------------------------------------------------
printf '%s\n' "------------------------------------------------------------"
if [[ $VIOLATIONS -eq 0 ]]; then
  printf '%s✓%s architecture boundaries clean\n' "$GRN" "$OFF"
  exit 0
fi
printf '%s✗%s %d boundary violation(s)\n' "$RED" "$OFF" "$VIOLATIONS"
exit 1
