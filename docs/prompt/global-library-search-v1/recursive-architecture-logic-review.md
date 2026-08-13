# Recursive Architecture and Logic Review — Global Library Search v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa scope, normalization, ranking, pagination, debounce và navigation boundary của Global Search |
| **Scope** | Docs/domain/data/controller/Library integration/router seam/tests của Global Library Search |
| **Source of truth for** | Quy trình recursive architecture/logic review Global Library Search v1 |
| **Depends on** | `docs/prompt/global-library-search-v1/implementation.md`, canonical Deck/Card/tag/search contracts |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

`AUDIT_ONLY` no edits; return reproducible severity/file:line findings.
`APPLY_FIXES`/standalone add failing test, fix and recurse. No commit/push/PR/merge.

Prove exact field scope; shared Unicode folding; empty query zero repository/DB;
250ms debounce outside widget; stale data/errors ignored and dispose safe; Decks
then Cards; exact→prefix→contains + stable ties; keyset pagination no duplicates/
gaps; tag multi-match dedupes; active/Trash exclusion; moves/renames refresh path;
no N+1/raw full-table transport; index only with evidence; result actions use
Deck Detail/Card Detail contract and never silently Edit; read-only/no Study
mutation; dependency boundaries and route docs correct.

Use real SQLite plus fake timer/domain contract. Run targeted/full host gate in
repair; emulator deferred. Clean stop without P0/P1/P2 and with negative tests
for stale query, empty I/O, Unicode, ties and concurrent page changes.
