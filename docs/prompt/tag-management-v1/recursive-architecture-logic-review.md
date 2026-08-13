# Recursive Architecture and Logic Review — Tag Management v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa filter algebra, normalization, atomic merge/delete và Card integration của tags |
| **Scope** | Docs/domain/data/transactions/controller/Card List integration/tests của Tag Management |
| **Source of truth for** | Quy trình recursive architecture/logic review Tag Management v1 |
| **Depends on** | `docs/prompt/tag-management-v1/implementation.md`, canonical Card/tag contracts |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

`AUDIT_ONLY` report-only with reproduction; `APPLY_FIXES`/standalone add failing
tests, fix and recurse. No commit/push/PR/merge.

Prove OR within selected tags and AND with search/state; no selected tag is
identity; EXISTS/distinct avoids duplicated rows/counts/pages; shared folding
is reused; rename keeps links; collision merge atomic/deduped and respects max
10; delete unlinks only; rollback leaves original graph; active counts exclude
Trash while rename preserves restorable links; purge cascades; import/export
compatibility; cursor resets and stale queries ignored; no study/content mutation;
domain/presentation boundaries intact.

Use real SQLite for all transaction/filter/pagination cases. Run targeted/full
host gate in repair; emulator deferred. Clean stop without P0/P1/P2 and with
negative tests for collision, rollback, duplicated joins and filter composition.
