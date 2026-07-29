#!/usr/bin/env bash
# Specification integrity checker.
#
# The docs in docs/ are a contract that code will be written against, and the
# failure mode that matters is a reference that points at the wrong thing —
# BR-13 citing "BR-36" for reset after a renumber moved reset to BR-44. Nothing
# catches that at runtime; it only surfaces when a human reads it and complies.
#
# Three groups of checks:
#   A. Document integrity      — runs always
#   B. Invariant coverage      — runs always; verifies data-model.md actually
#                                specifies a query for each data invariant
#   C. Data invariants         — runs only when a SQLite database exists
#
# Usage:
#   check_docs.sh [--db <path-to-sqlite-db>] [--quiet]
# Exit: 0 clean, 1 problems found.

set -uo pipefail

DB=""
QUIET=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --db) DB="${2:-}"; shift 2 ;;
    --quiet) QUIET=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT" || exit 1

RED=$'\033[31m'; YEL=$'\033[33m'; GRN=$'\033[32m'; DIM=$'\033[2m'; OFF=$'\033[0m'
[[ -t 1 ]] || { RED=""; YEL=""; GRN=""; DIM=""; OFF=""; }

PROBLEMS=0
fail() { PROBLEMS=$((PROBLEMS + 1)); printf '%s✗%s %s\n    %s\n' "$RED" "$OFF" "$1" "$2"; }
warn() { [[ $QUIET -eq 1 ]] || printf '%s!%s %s\n    %s\n' "$YEL" "$OFF" "$1" "$2"; }
ok()   { [[ $QUIET -eq 1 ]] || printf '%s✓%s %s\n' "$GRN" "$OFF" "$1"; }
head_() { printf '\n%s── %s %s\n' "$DIM" "$1" "$OFF"; }

BR_FILE="docs/business-rules.md"
AD_FILE="docs/architecture.md"
UC_FILE="docs/use-cases.md"
WBS_FILE="docs/wbs.md"
README_FILE="docs/README.md"

for f in "$BR_FILE" "$AD_FILE" "$UC_FILE" "$WBS_FILE" "$README_FILE"; do
  [[ -f "$f" ]] || { fail "missing document" "$f"; }
done
[[ $PROBLEMS -eq 0 ]] || { echo; echo "cannot continue without the core documents"; exit 1; }

# Files that may cite an ID. Templates under assets/ are excluded: they contain
# placeholder rows like "| BR-01 | |" that are examples, not citations.
ref_files() {
  { ls docs/*.md 2>/dev/null
    echo CLAUDE.md
    find .claude/skills -name 'SKILL.md' -o -path '*/references/*.md' 2>/dev/null
  } | sort -u
}

# ---------------------------------------------------------------------------
# A. Document integrity
# ---------------------------------------------------------------------------
head_ "A. Document integrity"

# Definitions: table rows "| BR-07 |" and headings "### BR-15 ·"
defined_ids() { # defined_ids <file> <prefix>
  grep -ohE "^(\| |#{2,4} )$2-[0-9]+" "$1" 2>/dev/null | grep -ohE "$2-[0-9]+" | sort
}
BR_DEFINED="$(defined_ids "$BR_FILE" BR | sort -u)"
AD_DEFINED="$(defined_ids "$AD_FILE" AD | sort -u)"
UC_DEFINED="$(defined_ids "$UC_FILE" UC | sort -u)"

# --- duplicates ---
for pair in "BR:$BR_FILE" "AD:$AD_FILE" "UC:$UC_FILE"; do
  prefix="${pair%%:*}"; file="${pair#*:}"
  dupes="$(defined_ids "$file" "$prefix" | uniq -d)"
  if [[ -n "$dupes" ]]; then
    while read -r d; do fail "duplicate ID definition" "$d defined more than once in $file"; done <<< "$dupes"
  fi
done
[[ $PROBLEMS -eq 0 ]] && ok "no duplicate BR / AD / UC definitions"

# --- dangling references ---
CITED="$(ref_files | xargs grep -ohE '\b(BR|AD|UC)-[0-9]+' 2>/dev/null | sort -u)"
ALL_DEFINED="$(printf '%s\n%s\n%s\n' "$BR_DEFINED" "$AD_DEFINED" "$UC_DEFINED" | grep -v '^$' | sort -u)"
DANGLING="$(comm -13 <(echo "$ALL_DEFINED") <(echo "$CITED"))"
if [[ -n "$DANGLING" ]]; then
  while read -r id; do
    where="$(ref_files | xargs grep -lE "\b$id\b" 2>/dev/null | tr '\n' ' ')"
    fail "reference to an ID that does not exist" "$id cited in: $where"
  done <<< "$DANGLING"
else
  ok "every cited BR / AD / UC id resolves ($(echo "$CITED" | wc -l | tr -d ' ') distinct ids)"
fi

# --- numbering continuity (gaps are legal under the append-only policy, but a
#     gap usually means a rule was deleted instead of marked BÃI BỎ) ---
for pair in "BR:$BR_DEFINED" "AD:$AD_DEFINED" "UC:$UC_DEFINED"; do
  prefix="${pair%%:*}"; ids="${pair#*:}"
  gaps="$(echo "$ids" | grep -ohE '[0-9]+' | sed 's/^0*//' | sort -n | awk '
    {if(p && $1!=p+1) for(i=p+1;i<$1;i++) print i; p=$1}')"
  [[ -n "$gaps" ]] && warn "numbering gap in $prefix" "missing: $(echo "$gaps" | tr '\n' ' ')— deleted instead of marked BÃI BỎ?"
done

# --- WBS task id duplicates ---
#
# The pattern must cover both prefixes. It was `T`-only until M2.1b, which made
# the check report "no duplicate WBS task IDs (8 tasks)" while the WBS held 33:
# a pass that reads like coverage while 25 M-tasks go unchecked. A check that
# silently skips most of its input is worse than no check, because the green
# tick is what the next session trusts.
TASK_ID_RE='[TM][0-9]+(\.[0-9]+)?[a-z]?'
TASK_IDS="$(grep -ohE "^### $TASK_ID_RE " "$WBS_FILE" | awk '{print $2}' | sort)"
TASK_DUPES="$(echo "$TASK_IDS" | uniq -d)"
if [[ -n "$TASK_DUPES" ]]; then
  while read -r t; do fail "duplicate WBS task ID" "$t appears more than once in $WBS_FILE"; done <<< "$TASK_DUPES"
else
  ok "no duplicate WBS task IDs ($(echo "$TASK_IDS" | wc -l | tr -d ' ') tasks)"
fi

# --- WBS dependencies point at a task that exists ---
#
# A dependency on a task ID that was renamed or never written reads as a real
# ordering constraint and silently isn't one. Only ID-shaped tokens are checked,
# so prose values like "none" or "product owner input" pass through untouched.
DEP_PAIRS="$(awk '
  /^### / {
    cur = ($2 ~ /^[TM][0-9]+(\.[0-9]+)?[a-z]?$/) ? $2 : ""
    next
  }
  cur != "" && /^- \*\*Dependencies:\*\*/ {
    line = $0
    sub(/^- \*\*Dependencies:\*\*[[:space:]]*/, "", line)
    n = split(line, toks, /[^A-Za-z0-9.]+/)
    for (i = 1; i <= n; i++) {
      t = toks[i]
      gsub(/\.+$/, "", t)
      if (t ~ /^[TM][0-9]+(\.[0-9]+)?[a-z]?$/) print cur "|" t
    }
  }
' "$WBS_FILE")"
dep_bad=0
if [[ -n "$DEP_PAIRS" ]]; then
  while IFS='|' read -r task dep; do
    [[ -z "$dep" ]] && continue
    grep -qxF "$dep" <<< "$TASK_IDS" && continue
    fail "WBS dependency points at a task that does not exist" \
      "$task depends on $dep, which is not defined in $WBS_FILE"
    dep_bad=1
  done <<< "$DEP_PAIRS"
fi
[[ $dep_bad -eq 0 ]] && ok "every WBS dependency resolves to a defined task ($(echo "$DEP_PAIRS" | grep -c . ) edges)"

# --- M-tasks carry the required fields and a non-empty acceptance block ---
#
# Scoped to M* deliberately: the T-tasks predate the §6.5 template and several
# legitimately lack `Editable documents`. `Out of scope` is excluded because
# §6.5 marks it conditional. An empty acceptance-criteria block is called out
# separately from a missing field — a task with the heading but no boxes looks
# specified and is not.
task_bad="$(awk '
  BEGIN {
    split("Status|Goal|Scope|Editable documents|Output|Acceptance criteria|Dependencies|Tests required|Checklist phases", req, "|")
  }
  /^### / {
    if (id != "") check()
    id = ($2 ~ /^M[0-9]+(\.[0-9]+)?[a-z]?$/) ? $2 : ""
    delete seen; ac = 0; inac = 0
    next
  }
  id != "" {
    for (i in req) if (index($0, "- **" req[i] ":**")) seen[req[i]] = 1
    if ($0 ~ /^- \*\*Acceptance criteria:\*\*/) { inac = 1; next }
    if ($0 ~ /^- \*\*/) inac = 0
    if (inac && $0 ~ /^[[:space:]]*- \[[ x]\]/) ac++
  }
  END { if (id != "") check() }
  function check(   i, miss) {
    miss = ""
    for (i in req) if (!(req[i] in seen)) miss = miss (miss ? ", " : "") req[i]
    if (miss != "") print id ": missing field(s): " miss
    else if (ac == 0) print id ": Acceptance criteria block is empty"
  }
' "$WBS_FILE")"
if [[ -n "$task_bad" ]]; then
  while read -r t; do fail "M-task does not meet the WBS template" "$t  (§6.5)"; done <<< "$task_bad"
else
  ok "every M-task carries the 9 required fields and a non-empty acceptance block"
fi

# --- unresolved markers inside MVP scope ---
MARKERS="$(grep -rnE '\[cần xác nhận\]|\[TODO\]|\[TBD\]' docs/*.md CLAUDE.md 2>/dev/null || true)"
if [[ -n "$MARKERS" ]]; then
  while read -r m; do fail "unresolved marker in MVP scope" "$m"; done <<< "$MARKERS"
else
  ok "no unresolved [cần xác nhận] / [TODO] / [TBD] markers"
fi

# --- documents listed as "Not written yet" that actually exist ---
if grep -q '^## Not written yet' "$README_FILE"; then
  listed="$(sed -n '/^## Not written yet/,/^## /p' "$README_FILE" \
            | grep -ohE '`[a-z-]+\.md`' | tr -d '`' | sort -u)"
  for doc in $listed; do
    [[ -f "docs/$doc" ]] && fail "document exists but is listed as not written" \
      "docs/$doc is in the 'Not written yet' section of $README_FILE"
  done
  [[ $PROBLEMS -eq 0 ]] && ok "'Not written yet' section matches reality"
fi

# --- banned pattern: single-level root resolution (BR-57) ---
#
# Only actual USAGE counts. Prose that forbids the pattern necessarily contains
# it, and so does this script — a linter that flags the rule forbidding X is
# noise. So: look inside fenced code blocks in the docs, and in real SQL/Dart
# sources, never in prose.
sql_lines_in_docs() {
  local f
  for f in $(ls docs/*.md 2>/dev/null) $(find .claude/skills -path '*/references/*.md' 2>/dev/null); do
    awk -v F="$f" '
      /^```/ { infence = !infence; next }
      # Comment lines inside a fence are still prose — a schema comment saying
      # "never write COALESCE(...)" must not trip the check it documents.
      infence && $0 !~ /^[[:space:]]*(--|\/\/|#)/ { print F ":" NR ":" $0 }
    ' "$f"
  done
}
BANNED="$( { sql_lines_in_docs
             grep -rn 'COALESCE([[:space:]]*parent_deck_id' lib/ test/ 2>/dev/null || true
           } | grep -E 'COALESCE\([[:space:]]*([A-Za-z_][A-Za-z_0-9]*\.)?parent_deck_id' || true )"
if [[ -n "$BANNED" ]]; then
  while read -r b; do
    fail "banned root-resolution pattern used in SQL (BR-57)" "$b
    COALESCE(parent_deck_id, id) returns the level-2 deck at depth 3. Use root_deck_id."
  done <<< "$BANNED"
else
  ok "no COALESCE(parent_deck_id, …) used in any SQL or source"
fi

# ---------------------------------------------------------------------------
# B. Invariant coverage — is each data invariant actually specified?
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# A2. Document contract — docs/document-conventions.md
# ---------------------------------------------------------------------------
head_ "A2. Document contract (document-conventions.md)"

REQUIRED_HEADER=("Status" "Purpose" "Scope" "Source of truth for" "Depends on" "Updated by task" "Last updated")

# --- every document declares the full header ---
hdr_bad=0
for f in docs/*.md; do
  for k in "${REQUIRED_HEADER[@]}"; do
    head -20 "$f" | grep -qF "| **$k**" && continue
    fail "document header missing a field" "$f is missing: **$k**  (§4)"
    hdr_bad=1
  done
done
[[ $hdr_bad -eq 0 ]] && ok "all $(ls docs/*.md | wc -l | tr -d ' ') documents declare the full 7-field header"

# --- canonical location: no two documents claim the same source of truth ---
# Each "Source of truth for" cell is a "·"-separated list of topics.
dupe_sot="$(for f in docs/*.md; do
    line="$(grep -m1 -F '| **Source of truth for**' "$f" | sed 's/.*truth for\*\* | //; s/ |$//')"
    [[ -z "$line" ]] && continue
    echo "$line" | tr '·' '\n' | sed 's/^ *//; s/ *$//' | grep -v '^$' \
      | while read -r topic; do echo "$topic|$f"; done
  done | sort | awk -F'|' '{if($1==prev && $2!=prevf) print $1" → "prevf" AND "$2; prev=$1; prevf=$2}')"
if [[ -n "$dupe_sot" ]]; then
  while read -r d; do fail "two documents claim the same source of truth" "$d  (§5)"; done <<< "$dupe_sot"
else
  ok "no topic is claimed as source of truth by two documents"
fi

# --- BR rows carry the required columns ---
br_bad="$(awk -F'|' '/^\| BR-[0-9]+ \|/ { if (NF < 7) print FILENAME":"NR": "$2" has "NF-2" columns, needs 5" }' "$BR_FILE")"
if [[ -n "$br_bad" ]]; then
  while read -r b; do fail "BR row missing required columns" "$b  (§6.2: ID | Status | Rule | Enforced by | Related)"; done <<< "$br_bad"
else
  ok "every BR table row carries ID / Status / Rule / Enforced by / Related"
fi

# --- section-form BR entries declare Status / Enforced by / Related ---
sec_bad="$(awk '
  /^### BR-[0-9]+ /       { id=$2; found=0; next }
  id != "" && /\*\*Status:\*\*/ && /\*\*Enforced by:\*\*/ { found=1 }
  id != "" && /^### |^## /{ if(!found) print id; id="" }
  END { if(id != "" && !found) print id }
' "$BR_FILE")"
if [[ -n "$sec_bad" ]]; then
  while read -r s; do fail "section-form BR missing Status / Enforced by" "$s in $BR_FILE  (§6.2)"; done <<< "$sec_bad"
else
  ok "every section-form BR declares Status and Enforced by"
fi

# --- UC sections carry all nine required parts ---
uc_bad="$(awk '
  BEGIN { split("Actor|Trigger|Preconditions|Main flow|Alternative flows|Error flows|Postconditions|Business rules|UI states", req, "|") }
  /^## UC-[0-9]+ / { if (id != "") check(); id=$2; delete seen; next }
  id != "" { for (i in req) if (index($0, "**" req[i])) seen[req[i]]=1 }
  END { if (id != "") check() }
  function check(  i, miss) {
    miss=""
    for (i in req) if (!(req[i] in seen)) miss = miss (miss?", ":"") req[i]
    if (miss != "") print id ": " miss
  }
' "$UC_FILE")"
if [[ -n "$uc_bad" ]]; then
  while read -r u; do fail "UC missing required section" "$u  (§6.3)"; done <<< "$uc_bad"
else
  ok "every UC carries all nine required sections"
fi

# --- AD sections carry Status, Affected documents and a Decision ---
ad_bad="$(awk '
  /^## AD-[0-9]+ / { if (id != "") check(); id=$2; s=a=d=0; next }
  id != "" && /^\| \*\*Status\*\*/            { s=1 }
  id != "" && /^\| \*\*Affected documents\*\*/{ a=1 }
  id != "" && /\*\*Quyết định|\*\*Decision/   { d=1 }
  END { if (id != "") check() }
  function check(  m) {
    m=""
    if (!s) m = m "Status "
    if (!a) m = m "Affected-documents "
    if (!d) m = m "Decision "
    if (m != "") print id ": missing " m
  }
' "$AD_FILE")"
if [[ -n "$ad_bad" ]]; then
  while read -r a; do fail "AD missing required field" "$a  (§6.1)"; done <<< "$ad_bad"
else
  ok "every AD declares Status, Affected documents and a Decision"
fi

head_ "B. Invariant coverage in docs/data-model.md"

DM="docs/data-model.md"
if [[ ! -f "$DM" ]]; then
  fail "missing document" "$DM"
else
  # Each entry: <label>|<regex that must appear in the invariant section>
  INVARIANTS=(
    "root deck has direct cards|WHERE d\.parent_deck_id IS NULL"
    "content_type=unset but has content|content_type = 'unset'"
    "content_type=card but has sub-decks|content_type = 'card'"
    "content_type=deck but has direct cards|content_type = 'deck'"
    "descendant points at wrong root|root_deck_id <> p\.root_deck_id"
    "cycle in the deck tree|WITH RECURSIVE"
    "card state scheduler/generation mismatch|s\.scheduler_generation <> root\.scheduler_generation"
    "session status × end_reason matrix|status = 'invalidated'"
    "relearning must not change schedule|review_kind = 'relearning'"
  )
  missing=0
  for entry in "${INVARIANTS[@]}"; do
    label="${entry%%|*}"; pattern="${entry#*|}"
    grep -qE "$pattern" "$DM" || { fail "invariant not specified" "no query in $DM for: $label"; missing=1; }
  done
  [[ $missing -eq 0 ]] && ok "all ${#INVARIANTS[@]} data invariants have a query in $DM"
fi

# ---------------------------------------------------------------------------
# C. Data invariants — only when a database exists
# ---------------------------------------------------------------------------
head_ "C1. Invariant queries — do they parse and discriminate?"

# Runs against an in-memory fixture, so it works before any real database
# exists. A query that never returns rows would pass a "no violations found"
# check perfectly while enforcing nothing; this catches that.
VERIFIER=".claude/skills/flutter-workflow/scripts/verify_invariants.py"
if ! command -v python3 >/dev/null 2>&1; then
  warn "python3 not on PATH" "cannot self-test the invariant queries"
elif [[ ! -f "$VERIFIER" ]]; then
  warn "verifier missing" "$VERIFIER"
elif out="$(python3 "$VERIFIER" 2>&1)"; then
  n="$(echo "$out" | grep -cE '^\s+✓ Q[0-9]+')"
  ok "$n invariant queries parse, stay clean on valid data, and each fires on its own violation"
else
  fail "invariant query self-test failed" "$(echo "$out" | grep -E '✗|LỖI' | head -5)"
fi

head_ "C2. Data invariants against a real database"

if [[ -z "$DB" ]]; then
  echo "  skipped — no --db given. Nothing here has been checked."
  echo "  Build the fixtures, then point this section at them:"
  echo "    flutter test test/database/fixture_db_test.dart"
  echo "    $0 --db build/invariant_fixture_clean.db"
elif [[ ! -f "$DB" ]]; then
  fail "database not found" "$DB"
elif ! command -v python3 >/dev/null 2>&1; then
  fail "python3 not on PATH" "cannot run the data invariants against $DB"
else
  # Delegated, not re-implemented. The queries live in docs/data-model.md and
  # the verifier reads them from there; this file used to carry a hand-copied
  # subset, and four of the fourteen were simply missing — ten ran, and the run
  # reported success. A second copy of a rule set is a second thing to forget.
  #
  # Also removes the dependency on the sqlite3 CLI, which is not installed
  # everywhere and made this section skip silently when it was absent.
  if out="$(python3 "$VERIFIER" --db "$DB" 2>&1)"; then
    ok "all 14 data invariants ran clean against $DB"
  else
    fail "data invariants violated" "$(echo "$out" | grep -E '✗' | head -6)"
  fi
fi

# ---------------------------------------------------------------------------
printf '\n%s\n' "------------------------------------------------------------"
if [[ $PROBLEMS -eq 0 ]]; then
  printf '%s✓%s specification is internally consistent\n' "$GRN" "$OFF"
  echo
  echo "Not checked here: whether a rule is a good rule, and whether a citation"
  echo "points at the semantically right rule. Both still need a human."
  exit 0
fi
printf '%s✗%s %d problem(s)\n' "$RED" "$OFF" "$PROBLEMS"
exit 1
