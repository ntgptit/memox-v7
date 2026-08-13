# Recursive Architecture and Logic Review — Card Detail and History v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa history truth, pagination, generation grouping và navigation boundaries của Card Detail |
| **Scope** | Docs/domain/data/DI/controller/router/tests của Card Detail and History |
| **Source of truth for** | Quy trình recursive architecture/logic review Card Detail and History v1 |
| **Depends on** | `docs/prompt/card-detail-history-v1/implementation.md`, canonical Card/Study contracts |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

`AUDIT_ONLY` reproduce/report only; `APPLY_FIXES`/standalone add failing test,
fix, rerun and repeat. Do not commit/push/PR/merge.

Prove detail reads full content/tags/current state without mutation; history
uses stored kind/action/mode/generation and never inference; ordering/cursor is
`answered_at,id` newest-first with 50 rows and no duplicate/gap; concurrent
insert/load-more stale handling is deterministic; reset retains old generations;
both scheduler transitions map correctly; empty/not-found/delete lifecycle typed;
selection tap does not navigate; Back preserves list state; dependency flow and
route constants/docs correct; no raw rows/N+1/private logging.

Use real SQLite for pagination/tie/reset/delete and fake domain contract for UI.
Run targeted + full host gate during repair; emulator deferred. Clean stop only
without P0/P1/P2 and with tests covering negative paging/history cases.
