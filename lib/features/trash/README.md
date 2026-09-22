# features/trash

A 30-day safety net for deletion (UC-21, AD-22). Read `features/deck/README.md`
first for the method.

## 1 · What business problem it owns

Nothing is destroyed when a user deletes it. A delete marks rows, groups them
into a **batch**, and the batch is recoverable until it is 30 days old or the
user explicitly purges it.

It owns the batch lifecycle and the restore rules. It does **not** own the
delete itself — Deck and Card call into `ContentTrashRepository` from inside
their own transactions.

## 2 · Public entry points

| Kind | Where to read it |
|---|---|
| Route | `RouteNames.trash` — reached only from the deck-list overflow menu, one door |
| Screen | `TrashScreen` |
| Contracts | `TrashRepository` (list/restore/purge), `ContentTrashRepository` (the one Deck and Card call) |
| Entity | `TrashBatchEntity` |

**`ContentTrashRepository` is the interesting one.** It is the contract another
feature depends on, and its methods deliberately **open no transaction of their
own** — they run inside the caller's. A nested transaction here could commit
while the caller's delete rolled back, leaving half-deleted state.

## 3 · Data flow

Deletion is a single column, not a copy:

```
delete → decks.delete_batch_id / cards.delete_batch_id := <batch id>
         (+ one row in delete_batches)
```

`NULL` means active. Nothing is moved anywhere. Every active-path query carries
`delete_batch_id IS NULL`, and that predicate — not a view, not a trigger — is
what makes trashed content invisible (BR-257).

Purge is one statement, and the FK cascade does the rest:

```sql
DELETE FROM delete_batches WHERE id = :batchId;
```

## 4 · Providers, by role

`presentation/providers/` is wiring only. `TrashController` holds the list, the
kind filter and the selection; three command controllers share one submit
lifecycle helper — a function, not a base class.

Selection is **locked to one kind at a time**: the first selected row decides
whether the rest can be decks or cards (BR-266). A mixed-kind restore has no
single valid target type, so the constraint lives in the selection, not in a
later validation.

## 5 · Where the business rules are

BR-256…BR-267, plus a large borrowed set.

**The most important thing about this feature: restore does not have its own
rules.** It calls Deck's `deckMoveRejection` verbatim (BR-261). A parallel rule
set would drift from Deck's and start accepting moves Deck rejects. The one
deliberate difference is that `alreadyParent` — a rejection for a move — is
*accepted* for a restore, because restoring something to where it already
belongs is the normal case.

Rules worth knowing before touching anything here:

- **Retention is 30×24h from `deleted_at`, not 30 calendar days** (BR-264), and a
  batch at exactly 30 days **is** purgeable. The boundary is testable because it
  is a duration.
- **A descendant already tombstoned under an older batch is not swept into a new
  one** (BR-258). Otherwise restoring the newer batch would revive something the
  user deleted separately.
- **Restoring rewrites `root_deck_id` for the whole subtree, tombstones
  included** (BR-262) — a later restore of a nested tombstone would otherwise
  name a root it no longer belongs to.
- **Undo targets exactly where the tombstone still points** (BR-263): no picker,
  no confirmation, and one refusal reason (`undoOriginUnavailable`) regardless of
  why the origin is gone — explaining a target-picker rejection to someone who
  never opened a picker is worse than one honest sentence.
- **Purge refuses rather than partially deletes** (BR-265). The precondition
  (`purgeBlockerCount`) must return 0, because `decks.parent_deck_id ON DELETE
  CASCADE` has never heard of a batch and would happily reach outside it. A
  user-requested purge refuses the whole set; the automatic sweep skips that one
  batch.
- **Deleting content closes any session touching it in the same transaction**,
  `end_reason = content_deleted` (BR-259).

## 6 · How errors are converted

`TrashConflictReason` carries six values, each mapping to copy that points at the
right place: `targetNoLongerValid` → back to the picker, `undoOriginUnavailable`
→ back to Trash, and so on. `DeckMoveRejection` values pass through unchanged and
reuse the same ARB strings a move uses.

`unknownItemType` exists so a batch written by a newer build drops out of the
list instead of crashing it.

## 7 · How to test it

`test/features/trash/`. `trash_leak_test.dart` is the one that matters most: it
drives the Reminder and Deck repositories directly to prove trashed content does
not surface, which is the semantic complement to
`test/database/query_inventory_test.dart` — a text scan that only proves a
statement *mentions* `delete_batch_id`.

## 8 · Known gaps

- The retention sweep is documented as running at startup and on resume; the
  wiring for those two triggers lives in `lib/app/`, not here.
- `delete_batches` is the one table without per-column pinning in
  `test/database/schema_test.dart`; its shape is covered indirectly by
  `migration_v11_test.dart`.
- **AD-22 is this feature's own architecture decision and is still cited nowhere
  inside `lib/features/trash/`.** What this documentation pass fixed was a
  different problem: the clock-injection comments here cited AD-06 (the scheduler
  decision) and the provider-wiring comment cited AD-14 (the colour decision).
  Those now cite AD-13 and AD-12. Adding an AD-22 citation where the tombstone
  model is implemented is still open work.
