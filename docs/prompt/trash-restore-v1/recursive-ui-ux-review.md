# Recursive UI/UX Review — Trash and Restore v1

| | |
|---|---|
| **Status** | active |
| **Purpose** | Audit và sửa Trash discovery, selection, restore target, destructive safety và accessibility |
| **Scope** | Trash list/empty/error, Undo, multi-select, target picker và permanent purge dialogs |
| **Source of truth for** | Quy trình recursive UI/UX review Trash and Restore v1 |
| **Depends on** | `docs/prompt/trash-restore-v1/implementation.md`, Trash wireframes và MemoX destructive-action tokens |
| **Updated by task** | Parallel feature prompt batch |
| **Last updated** | 2026-08-13 |

---

Render production routes. `AUDIT_ONLY` inspect/measure/report only;
`APPLY_FIXES`/standalone repair recursively. No commit/push/PR/merge.

Inspect empty, card-only, deck subtree, mixed/expired, single Undo, card/deck
selection, restore target none/many/incompatible, validation error, restoring,
purging and failure/retry; EN/VI, light/dark, 320dp@2.0, 390/412dp. Pin
`getRect` for gutters, filters/list shared edges, row widths/metadata/action
baselines, selection bar, target rows, dialogs/snackbar and bottom/safe insets.

Ensure Trash entry discoverable; original path is context not implied restore;
selection type restriction understandable; soft delete looks recoverable while
permanent purge alone uses destructive emphasis; confirmation states exact count
and history loss; default focus/cancel safe; Undo duration/action accessible;
expired live removal does not cause disorienting jump. Add production geometry/
semantics regression per fix and compare goldens to wireframes. Clean stop when
all states inspected and no unapproved divergence/P0/P1/P2.
