# Drift → MyBatis parity, Phase 2

| | |
|---|---|
| **Status** | active |
| **Scope** | `deck.drift`, `card.drift`, `tag.drift`, `trash.drift` — the library reads and writes |
| **Companion** | `docs/superpowers/plans/2026-09-09-memox-api-phase-2-library-writes.md` |
| **Enforced by** | `memox-api/src/test/java/com/memox/contract/DriftParityTest.java` |

The Flutter client and `memox-api` implement the same business rules against the same schema, one in
SQLite through Drift and one in PostgreSQL through MyBatis. This document is the mapping between
them: which statement answers which, what had to change on the way, and — the part a reader cannot
get by reading 69 statements — **where the two deliberately disagree, and why**.

It is checked rather than asserted. `DriftParityTest` fails if a Phase 2 Drift query has no row
here, if a row names a MyBatis statement that does not exist, or if a mapper statement has no row.
Adding SQL on either side without a line in this table turns the suite red, which is the only thing
that keeps a document like this true after its branch merges.

## How to read the table

**MyBatis id `—`** means the statement was **not ported**, and the note says why. That is not the
same as "not done": an unported statement with a reason is a decision, an unported statement with no
row is something nobody noticed. This document exists to make the second impossible.

**Translation rows** cite the SQLite → PostgreSQL contract in §2 of the plan. Row 13 was added while
executing Task 7 and is worth repeating here because nothing fails when it is wrong: **SQLite sorts
NULLs first ascending; PostgreSQL sorts them last.**

## 1. `deck.drift`

| Drift statement | MyBatis id | Notes |
|---|---|---|
| `rootDecks` | `findRootDecks`, `countRootDecks` | Paged read plus its total; Wave 3 pagination. |
| `rootDeckSummaries` | `findRootDeckSummaries` | `nextDueAt` is an **uncorrelated** sub-select on purpose — see divergence 1. |
| `allDecks` | `findAllActiveDecks` | |
| `deckById` | `findActiveDeckById`, `findActiveDeckByIdForUpdate` | Two statements because a write path needs `FOR UPDATE` and a read path must not take the lock. |
| `decksInTree` | `findDecksInTree` | Flat, ordered by `sibling_position, id` — not a tree walk. |
| `childDeckLevel` | `findChildDeckLevel` | Recursive branch + ancestry walk; translation row 2 for the JSON breadcrumb. |
| `nextSiblingPosition` | `nextSiblingPosition` | See divergence 5: the filter differs, and it must. |
| `siblingDecks` | `findSiblingDecksForUpdate` | |
| `cardMoveTargets` | `findCardMoveTargets` | Ordered by name, not by id. |
| `subtreeDeckIds` | `findSubtreeDeckIds` | Cycle-safe `UNION`, no depth cap. |
| `deckDepthProbe` | `probeDeckDepth` | Bounded walk; hitting the bound is refused, never rounded down. |
| `subtreeHeightProbe` | `probeSubtreeHeight` | Same contract, other direction. |
| `directChildDeckCount` | `countDirectChildDecks` | Active rows only (BR-260). |
| `directCardCount` | `countDirectCards` | Active rows only (BR-260). |
| `subtreeCardCount` | `countSubtreeCards` | |
| `updateSubtreeRootDeck` | `updateSubtreeRootDeck` | Crosses tombstones deliberately (BR-262). |
| `resetTreeStudyStates` | — | **Phase 3.** Reset increments `scheduler_generation`, which every study write is then checked against; shipping the reset without the check it protects is worse than shipping neither. |

## 2. `card.drift`

| Drift statement | MyBatis id | Notes |
|---|---|---|
| `cardsByDeck` | `findActiveCardsByDeck`, `countActiveCardsByDeck` | |
| `cardListItems` | `findCardListItems` | Dynamic predicate; `EXISTS` for tags so a card with three selected tags appears once (BR-231). |
| `cardCount` | `countCardListItems` | Shares the predicate fragment with the list — one vị từ, two statements. |
| `cardIdsMatching` | `findCardIdsMatching` | Unpaged: "select all" means all of the filter (BR-167). |
| `cardDeckContextForIds` | `findCardDeckContextForIds` | |
| `moveCardsToDeck` | `moveCardsToDeck` | |
| `setCardsFlagByIds` | `setCardsFlagByIds` | Translation row 6: the boolean handler is named explicitly. |
| `tagCountsForCards` | `findCardsAtTagCeiling` | **Divergence 5.** |
| `cardsAlreadyTagged` | `findCardsAlreadyTagged` | |
| `cardById` | `findCardById` | |
| `cardDetailById` | `findCardDetailById` | Deliberately the same shape as the list row, so detail and the row it was opened from cannot disagree. |
| `cardHistoryFirstPage` | `findCardHistoryFirstPage` | All twenty `study_answers` columns — see divergence 8. |
| `cardHistoryAfter` | `findCardHistoryAfter` | Keyset pagination on `(answered_at, id)`. |
| `studyStateByCard` | — | No Phase 2 caller: `findCardDetailById` already carries the study state, and a standalone read of it is a study concern. |
| `flaggedCardsByDeck` | — | Answered by `findCardListItems` with its flagged filter. A second statement would be a second place for the list predicate to drift. |
| `cardStateCountsByDeck` | `countCardStatesByDeck` | |
| `deckContextById` | `findDeckContext` | Lives in `deck_mapper.xml`: it reads `decks`, whichever feature asked. |
| `cardKeysInDeck` | `findCardKeysInDeck` | Active cards only (BR-170). |
| `tagsByFoldedNames` | — | Import only, and import is Phase 3. |
| `exportDeckName` | `findExportDeckName` | Read in the same transaction as the rows (BR-177). |
| `exportCardsInDeck` | `findExportCardsInDeck` | **Divergence 6** on the tag order. |
| `exportCardsByIds` | `findExportCardsByIds` | Same projection fragment as above, by construction. |

## 3. `tag.drift`

| Drift statement | MyBatis id | Notes |
|---|---|---|
| `tagByFoldedName` | `findTagByFoldedName` | No `owner_id` predicate — see divergence 7. |
| `allTags` | — | `findTagCatalog` with an empty term is the same list and carries the counts. Two list statements would be two orderings of one thing. |
| `tagsForCard` | `findTagsForCard` | Ordered by the spelling: this is a display list, and BR-230's folded order is the catalog's rule. |
| `tagsForCards` | — | The card list already carries tag names per row; ids are needed on the detail screen only. |
| `tagCountForCard` | — | The rule it serves is BR-94's ceiling, which `findCardsAtTagCeiling` answers directly. |
| `tagCatalog` | `findTagCatalog` | **Divergence 3.** |
| `tagById` | `findTagById` | |
| `tagCardCount` | — | The catalog row already carries that number. |
| `renameTagById` | `renameTagById` | Only the two name columns; `card_tags` is never touched. |
| `linkCardsOfTagTo` | `linkCardsOfTagTo` | Translation row 3: `INSERT OR IGNORE` → `ON CONFLICT DO NOTHING`. Deliberately does **not** join `cards` (BR-237's second clause). |
| `unlinkAllCardsFromTag` | `unlinkAllCardsFromTag` | Explicit, not left to the cascade. |
| `deleteTagById` | `deleteTagById` | |
| `orphanedTags` | — | **Divergence 4.** |

## 4. `trash.drift`

| Drift statement | MyBatis id | Notes |
|---|---|---|
| `trashBatchRows` | `findTrashBatchRows` | One ancestry walk for the whole list, not one per row. Translation row 2. |
| `batchById` | `findBatchById` | |
| `eligibleBatches` | `findEligibleBatches` | `<=` cutoff, oldest first (BR-264). |
| `batchDeckIds` | — | No caller: restore and purge act by batch id, and the counts come from `findTrashBatchRows`. |
| `batchCardIds` | — | Same. |
| `activeSubtreeDeckIds` | `findActiveSubtreeDeckIds` | The active filter on the recursive step is BR-258's "keeps its old tombstone". |
| `activeCardIdsInDecks` | `findActiveCardIdsInDecks` | |
| `batchSubtreeHeightProbe` | — | **Divergence 2**: restore runs the move, which measures the height itself. |
| `purgeBlockerCount` | `countPurgeBlockers` | Allowed set is a parameter, not the cutoff — one statement, two policies. |
| `tombstoneDeckInBatch` | `findTombstoneDeckInBatch` | |
| `tombstoneCardInBatch` | `findTombstoneCardIdInBatch` | Narrowed to the id: the restore path needs existence, not the row. |
| `anyDeckById` | — | **Divergence 2**: the move reads the roots itself, from rows that are active again. |
| `markDecksDeleted` | `markDecksDeleted` | |
| `markCardsDeleted` | `markCardsDeleted` | |
| `restoreDecksInBatch` | `restoreDecksInBatch` | |
| `restoreCardsInBatch` | `restoreCardsInBatch` | |
| `purgeBatch` | `deleteBatch` | One row; both tombstone columns cascade from it. |

## 5. Statements this API has and Drift does not

Drift writes through generated companions, so an insert or a narrow update has no `.drift` query to
map to. These exist only on the server, and they are listed so the table describes the whole mapper
rather than a subset of it.

| Drift statement | MyBatis id | Notes |
|---|---|---|
| `—` | `insertRootDeck`, `insertSubDeck` | |
| `—` | `lockRootDeckCreation` | Serialises root creation so two requests cannot claim one sibling position. |
| `—` | `updateSiblingPosition`, `reparentDeck`, `updateDeckName`, `updateContentType` | One column family each; a wide update is how an edit silently touches a schedule. |
| `—` | `insertCard`, `insertInitialStudyState` | BR-09 creates both in one transaction. |
| `—` | `activeDeckExists` | |
| `—` | `updateCardContent` | Content and its folded columns together; never the flag, never the schedule (BR-92). |
| `—` | `insertTag` | |
| `—` | `countActiveCardsByIds`, `findActiveCardIds` | Batch guards: a tombstoned id must refuse the request rather than be skipped. |
| `—` | `linkTagToCards`, `unlinkTag` | Drift links one row at a time from Dart; one statement with `ON CONFLICT DO NOTHING` is the same filter. |
| `—` | `findSourceDeckIdsOfActiveCards` | Read **before** the marking, because the emptiness count runs after it. |
| `—` | `insertDeleteBatch` | |

## 6. Deliberate divergences

Each names the rule it serves. Two of them are **withdrawn** — recorded because they were tried and
were wrong, and a reader who re-derives them from the SQL alone would make the same mistake.

### 1. ~~`rootDeckSummaries.nextDueAt`~~ — withdrawn

Drift's sub-select is uncorrelated and returns the same instant for every root deck. That looks like
a bug and is not: the comment above it calls it the list screen's re-measure timer, *"one scalar
subquery, evaluated once per statement"*, and a sibling comment says *"the global MIN in
`rootDeckSummaries` is correct there"*. Correlating it shipped in PR #516 and was reverted in #517.

**The lesson, recorded because it cost a release:** the design lives in the comment above the SQL,
not in the SQL. Nothing failed when it was "fixed" — every row was still there, with a plausible
value.

### 2. ~~`childDeckLevel.nextDueAt`~~ — withdrawn

The same defect on the level view, caught before it shipped.

### 3. `tagCatalog.cardCount` — active cards only

Drift counts `card_tags` rows without joining `cards`, so a card sitting in Trash keeps inflating its
tags' counts. **BR-237 forbids it**, and the port joins `cards` on `delete_batch_id IS NULL`.

The rule has a second clause the plan did not quote: rename and merge **MUST still preserve the tag
links of hidden cards** so a restore loses no metadata. So `linkCardsOfTagTo` deliberately does *not*
join `cards` — two statements in one feature pulling opposite ways, for one rule.

**Flutter follow-up:** `tagCatalog` should join `cards`. Recorded in `docs/wbs.md`.

### 4. `orphanedTags` — not ported

Nothing calls it, and an automatic orphan purge would **violate BR-230**: deleting a card cascades
its links away and leaves the tag at count 0, and that row must stay — *"a tag nothing points at is
precisely what the catalog exists to let a user delete"*. The `NOT IN` → `NOT EXISTS` improvement the
plan noted is correct and moot.

### 5. `tagCountsForCards` → `findCardsAtTagCeiling`

Drift returns a count per card and folds it into the cap check in Dart. The rule only ever asks
*which of these is full*, so `HAVING COUNT(*) >= 10` answers it in the statement and the service
compares two id sets instead of a map of numbers nothing else reads (BR-94, BR-166).

### 6. Export tag ordering — the rule moves into the statement

BR-177: *"Tag của mỗi card MUST sắp theo tên đã fold (BR-93) với tie-break ổn định."*

SQLite does not honour an `ORDER BY` inside an aggregate — the comment above `exportCardsInDeck` says
so and calls the clause sitting there a courtesy that *"read as a guarantee that did not exist"* — so
the Dart repository re-sorts by folded name after splitting. PostgreSQL's `string_agg(… ORDER BY …)`
**is** a guarantee, so the port puts the rule in the statement that has to keep it:
`ORDER BY t.name_folded, t.name`.

The plan specified `ORDER BY t.name, t.id`, which is the spelling rather than the fold. Byte-ordered,
`Verb` sorts before `adjective`; folded, it does not — so the two platforms would have produced
different artifacts for the same deck, which is the one thing BR-177 exists to prevent.

This is deliberately **not** the order `findCardListItems` uses: that one needs an order that does
not flicker between two reads, and BR-177 does not govern a screen.

### 7. `owner_id` is not a predicate anywhere

Drift writes `owner_id IS :ownerId` because the local profile's owner is NULL and `= NULL` never
matches. This API has no principal at all (AD-03, "No auth yet, auth-ready"), no other mapper carries
one, and threading a permanently-null parameter from a controller through a service into every
statement would be a fourth spelling of "not yet". The column stays on the table, the unique index
over `COALESCE(owner_id, '')` still holds, and `Tag` does not carry the field either.

### 8. The history projection carries all twenty columns

`study_answers` has 20 columns and the plan's projection listed 19, dropping `comparison_version` —
under a Drift comment about exactly that: *"a column dropped from a projection is a fact that
silently stops being displayed"* (BR-242), which is why Drift uses `SELECT *` there. A test asserts
all twenty survive the read.

### 9. `nextSiblingPosition` counts tombstones

Drift filters `delete_batch_id IS NULL`; the server must **not**, because
`uq_decks_sibling_scope_position` covers tombstoned rows too. A soft-deleted sibling keeps its
position and therefore keeps holding the slot, so `MAX + 1` over active rows alone would hand a new
deck a slot a tombstone already owns.

The same fact answers a question the plan raised and got backwards: a restored deck's old position
**cannot** have been taken by a sibling created after the delete. It still takes a fresh slot, but
because a restore is a move (divergence 2) and a move always takes one.

### 10. Restore executes the move rather than re-checking it

BR-261: a restored sub-deck's target MUST satisfy **exactly** the move's rules, and *"MUST NOT có bộ
luật thứ hai dành riêng cho restore"*. So restore clears the batch's tombstones and then calls
`DeckMoveService.move` / `CardBulkService.move` on rows that are active again. The rules are
executed, not re-listed; a refusal rolls the transaction back and the rows return to being
tombstones. The refusals are the move's own error codes for the same reason.

## 7. Outstanding obligations

Not divergences. Rules this API is required to meet and does not yet.

### BR-259 — session invalidation on delete

A soft-delete MUST close an in-progress session touching the deleted content, **in the same
transaction**, with `status = invalidated` and `end_reason = content_deleted`, and the reason MUST be
stored rather than inferred later. `trash.drift` states plainly why the write is not a Trash
statement:

> Session invalidation (BR-259) is **not** here. The two lookups and the write live in
> `queries/study.drift`, because the session status × end_reason pair belongs to
> `StudySessionStatus.isValidWith` and Trash may not write it behind that enum's back.

This API has no study module, so **the delete path is incomplete by exactly that one write.** When
the study slice lands it must add the invalidation *to* `TrashDeleteService`'s transaction, not
beside it. Recorded in `docs/wbs.md`.

### BR-266 — the user-requested purge

`countPurgeBlockers` takes its allowed set as a parameter because there are two callers: the
retention sweep, which **skips** a blocked batch, and a user-requested purge, which **refuses** one
because the user named it. Only the sweep is built. The statement needs no change when the second
arrives — which is the reason `trash.drift` gives for the parameter.
