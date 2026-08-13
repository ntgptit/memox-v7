# Recursive Architecture and Logic Review — Trash and Restore v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa tombstone batches, hierarchy, content_type, session invalidation, restore và purge |
| **Scope** | Canonical docs/schema/migrations/all active queries/domain/data/DI/lifecycle/tests của Trash |
| **Source of truth for** | Quy trình recursive architecture/logic review Trash and Restore v1 |
| **Depends on** | `docs/prompt/trash-restore-v1/implementation.md`, canonical Deck/Card/Study lifecycle contracts |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

This is high-risk migration work. `AUDIT_ONLY` must not edit; return reproducible
P0–P3 findings and affected query inventory. `APPLY_FIXES`/standalone creates a
failing invariant/test before each fix, edits sequentially and repeats. No
commit/push/PR/merge.

Prove soft-delete atomicity; batch identity preserves predeleted descendants;
every active Deck/Card/Study/Search/Progress/Tag/Export query excludes tombstones;
content_type resets/sets automatically; root/depth/scheduler/generation restore
guards identical to move/create; in-progress sessions invalidated with stored
reason; history/state retained until purge; undo restores same batch; 30-day
boundary and startup/resume/open triggers idempotent; purge never takes a newer
or unrelated batch; rollback leaves graph consistent; migrations/snapshots/
zero-row invariants complete; no UI/controller business logic.

Run production repository tests on real SQLite including depth 10, mixed batches,
concurrent-looking lifecycle sequences and query inventory guard. Full host gate
after repair; emulator deferred. Clean stop requires zero invariant rows, no
P0/P1/P2 and explicit list of cross-PR migration conflicts.
