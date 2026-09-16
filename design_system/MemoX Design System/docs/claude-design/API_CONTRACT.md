# MemoX — Data and Action Contracts

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Handoff for Claude Design — the exact data each product area receives and the commands it can issue |
| **Scope** | Use-case level contracts of the app at base commit `de1e862c`: inputs, outputs, nullability, enums, derived values, validation and failures. Out of scope: storage internals, state-management and navigation mechanics, any UI |
| **Source of truth for** | — (derived snapshot; `lib/features/*/domain/` wins on any disagreement) |
| **Depends on** | `PRODUCT_CONTEXT.md` |
| **Updated by task** | claude-design-handoff (no WBS id) |
| **Last updated** | 2026-09-16 |

## 0. What these contracts are

MemoX is local-first. **The app makes no HTTP calls.** Every area talks to
local use cases, and those use cases are the contract. A standalone REST
backend exists in the repository but is not connected to the app (Appendix A).

| Kind | Meaning |
|---|---|
| **Watch** | A live query. Delivers a value now and a new value whenever the underlying data changes — and, where noted, at local midnight |
| **Get** | A one-shot read |
| **Command** | A write. Returns a result, or fails with a typed failure (§2) |

**Notation**

- `field: Type` — always present. `field?: Type` — may be null.
- `Type[]` — a list, possibly empty.
- *(derived)* — computed from other fields of the same object; not stored.
- `DateTime` — an instant in UTC (samples use ISO-8601). `LocalDate` — a calendar date in the user's time zone.
- Enum values are written as the canonical value in §1.
- Field names match the source models, so they match `SAMPLE_DATA.json`.
- **Clock-dependent** contracts also take the current time and UTC offset from the app clock; those inputs are omitted below.
- Ids are UUID strings. They are needed for actions and are never displayed.

---

## 1. Shared enums and value types

| Enum | Values | Notes |
|---|---|---|
| `SchedulerType` | `eight_box` · `sm2` | Review algorithm. Data written by a newer app version may read as `unknown`; show as unsupported, never offer it |
| `DeckContentType` | `unset` · `card` · `deck` | Same `unknown` tolerance |
| `DeckScheduleStatus` | `notDue` · `dueToday` · `overdue` | Derived |
| `CardState` | `new` · `beginning` · `reviewing` · `mastered` | Derived. Source identifier for `new` is `isNew` |
| `CardDueBadge` | `notScheduled` · `dueNow` · `inMinutes(n)` · `inHours(n)` · `inDays(n)` | Derived from `dueAt` and now. Minutes ≥1, hours <24, days = whole days |
| `StudyMode` | `browse` · `self_assess` · `match` · `guess` · `recall` · `fill` | |
| `StudyAction` | `forgotten` · `remembered` · `again` · `hard` · `good` · `easy` | `eight_box` supports `forgotten`, `remembered`; `sm2` supports `again`, `hard`, `good`, `easy` |
| `StudyAnswerKind` | `learning` · `scheduled` · `relearning` | |
| `StudySessionKind` | `learning` · `reviewing` | |
| `StudySessionStatus` | `in_progress` · `completed` · `abandoned` · `invalidated` · `failed` | |
| `StudySessionEndReason` | `user_exit` · `interrupted` · `scheduler_reset` · `scheduler_changed` · `stale_generation` · `persistence_error` · `content_deleted` | Valid pairs below |
| `StudySessionDirection` | `korean_to_meaning` · `meaning_to_korean` · `mixed` | Session-level choice |
| `StudyRecallDirection` | `korean_to_meaning` · `meaning_to_korean` | Per turn; never `mixed` |
| `StudyOutcomeReason` | `timeout` | `recall` only |
| `StudyQueueItemStatus` | `pending` · `completed` | |
| `NewCardOrder` | `created` · `random` | |
| `AppThemeMode` | `system` · `light` · `dark` | |
| `AppLanguage` | `system` · `en` · `vi` | |
| `DeckListFilter` | `all` · `due` | Applied by the Library area over `WatchDeckList` |
| `DeckListSort` | `manual` · `dateAdded` · `name` · `cardsDue` · `progress` | `dateAdded` newest first · `name` A→Z ignoring case · `cardsDue` most due first · `progress` lowest mastered fraction first · ties keep manual order |
| `CardListFilter` | `all` · `due` · `new` · `flagged` | Source identifier for `new` is `isNew` |
| `CardListSort` | `newest` · `dueFirst` | `dueFirst` puts cards without a due time first |
| `TrashItemType` | `card` · `deck` | |
| `TrashFilter` | `all` · `cards` · `decks` | |
| `CardTransferFormat` | `csv` · `tsv` · `xlsx` | |
| `CardTransferField` | `front` · `back` · `example` · `hint` · `pronunciation` · `tags` | Also the six export headers, in this order |
| `CardImportRowStatus` | `ready` · `invalid` · `duplicateExisting` · `duplicateInFile` · `blank` | |
| `CardExportResult` | `shared` · `dismissed` | |
| `SearchMatchRank` | `exact` · `prefix` · `contains` | |
| `ProgressRange` | `last7Days` · `last30Days` | |
| `ReminderCapability` | `supported` · `unsupported` | |
| `ReminderPermission` | `granted` · `denied` · `notRequested` | Read from the OS |
| `TagRenameOutcome` | `renamed` · `merged` | |
| `DeckTemplateInstallOutcome` | `installed` · `alreadyPresent` | |
| `DeckReorderPlacement` | `before` · `after` | |

**Session status × end reason**

| `status` | allowed `endReason` |
|---|---|
| `in_progress`, `completed` | null |
| `abandoned` | `user_exit`, `interrupted` |
| `invalidated` | `scheduler_reset`, `scheduler_changed`, `stale_generation`, `content_deleted` |
| `failed` | `persistence_error` |

**Limits**

| Name | Value |
|---|---|
| Deck name | 1–200 characters after trim |
| Card front / back | 1–60 / 1–240 characters after trim |
| Card example, hint, pronunciation | 0–240 characters; empty becomes null |
| Tag name | 1–50 characters after trim; no control characters |
| Tags per card | 10 |
| Deck depth | 10 (root = 1) |
| Card limit | 1–200, default 20 |
| Reminder minute of day | 0–1439, default 1200 |
| History page | 50 events |
| Library search page | 20 results (app setting of the area) |
| `match` board | up to 5 pairs; stage needs ≥2 |
| `guess` options | exactly 5 |
| `recall` time | 20 seconds |
| Trash retention | 30 × 24 hours |

---

## 2. Failures

Every command either succeeds or fails with exactly one of these families.

| Family | Meaning | Carries |
|---|---|---|
| **Validation** | Input breaks a field rule | A set of problems, each tied to a field |
| **Conflict** | A rule refused the action given the data as it is now | One reason |
| **Not found** | The target no longer exists | One reason |
| **Study refusal** | A session action is not possible | One reason |
| **Storage failure** | A local read or write failed | Nothing user-facing; retryable |

| Enum | Values |
|---|---|
| `DeckValidationProblem` | `nameEmpty` · `nameTooLong` · `schedulerMissing` |
| `DeckConflictReason` | `parentHoldsCards` · `parentAtMaxDepth` · `resetNeedsRootDeck` · `resetSchedulerUnknown` · `schedulerNeedsRootDeck` · `schedulerLocked` · `unknownContentType` · `deckDepthUnknowable` · `subtreeHeightUnknowable` |
| `DeckMoveRejection` | `sourceIsRoot` · `itself` · `ownDescendant` · `holdsCards` · `differentScheduler` · `differentGeneration` · `tooDeep` · `alreadyParent` |
| `CardValidationProblem` | `frontEmpty` · `frontTooLong` · `backEmpty` · `backTooLong` · `exampleTooLong` · `hintTooLong` · `pronunciationTooLong` |
| `CardConflictReason` | `parentIsRoot` · `deckHoldsDecks` · `unknownContentType` · `moveTargetIsSameDeck` · `moveTargetIsRoot` · `moveTargetHoldsDecks` · `moveCrossRoot` · `rootSchedulerMissing` · `unknownScheduler` |
| `CardNotFoundReason` | `deckGone` · `cardGone` |
| `TagValidationProblem` | `nameEmpty` · `nameTooLong` · `nameTaken` · `tooManyTags` · `nameHasControlCharacter` |
| `TagCatalogProblem` | `tagMissing` |
| `CardTransferProblem` | `unsupportedFile` · `invalidEncoding` · `emptySource` · `emptySheet` · `unreadableFile` |
| `CardExportProblem` | `emptyScope` · `staleSelection` · `deckMissing` · `readFailed` · `encodeFailed` · `shareUnavailable` · `sharePlatformError` |
| `StudyRefusalReason` | `nothingDueToReview` · `nothingLeftToLearn` · `modeHasNoContent` · `modeNotSupportedByScheduler` · `staleGeneration` · `sessionNotOpen` |
| `StudyCardLimitProblem` | `notANumber` · `tooSmall` · `tooLarge` |
| `ReminderTimeProblem` | `outOfRange` |
| `ReminderSetupRejection` | `platformUnavailable` · `permissionDenied` · `scheduleFailed` · `cancelFailed` · `settingsWriteFailed` |
| `TrashConflictReason` | `targetNoLongerValid` · `targetLevelMismatch` · `undoOriginUnavailable` · `purgeWouldTakeAnotherBatch` · `unknownItemType` · `batchHeightUnknowable` |

`*Unknowable` and `unknown*` reasons mean the data could not be read safely
(for example written by a newer app version). They are rare and not
user-correctable.

---

## 3. Library and decks

### Deck

| Field | Type | Notes |
|---|---|---|
| `id` | String | |
| `name` | String | 1–200 chars |
| `parentDeckId` | String? | null = root deck |
| `rootDeckId` | String | A root carries its own id |
| `contentType` | DeckContentType | Root is always `deck` |
| `schedulerType` | SchedulerType? | Root only; null on sub-decks |
| `schedulerGeneration` | int? | Root only; starts at 1 |
| `firstAnsweredAt` | DateTime? | Root only. Non-null = algorithm **locked** |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |
| `isRoot` | bool *(derived)* | `parentDeckId == null` |

### DeckSummary — one deck with its whole-subtree counts

| Field | Type | Notes |
|---|---|---|
| `deck` | Deck | |
| `totalCardCount` | int | Active cards in the subtree |
| `newCardCount` | int | Not yet learned |
| `dueCardCount` | int | Learned and due now |
| `overdueCardCount` | int | Due before start of local today; part of `dueCardCount` |
| `overdueDayCount` | int | Local days since the oldest due card became due; 0 when none is overdue |
| `learnedCardCount` | int | ⚠ **Mastered** cards (box 8 / interval ≥128), not "finished learning" |
| `subDeckCount` | int | **Direct** active sub-decks |
| `schedulerType` | SchedulerType | Resolved from the root |
| `learnedFraction` | double *(derived)* | `learnedCardCount / totalCardCount`, 0 when empty — the mastered fraction |
| `isFullyLearned` | bool *(derived)* | Every card mastered, and at least one card |
| `hasNewCards` | bool *(derived)* | |
| `dueTodayCardCount` | int *(derived)* | `dueCardCount − overdueCardCount` |
| `scheduledCardCount` | int *(derived)* | `totalCardCount − newCardCount − dueCardCount` |
| `hasDueCards` | bool *(derived)* | |
| `scheduleStatus` | DeckScheduleStatus *(derived)* | `notDue` if nothing due; `dueToday` if `overdueDayCount == 0`; else `overdue` |
| `hasStudyableCards` | bool *(derived)* | New or due cards exist |

### Watch `WatchDeckList` — clock-dependent

Input: `parentDeckId?: String` — null for the top level.

Output `DeckListSnapshot`:

| Field | Type | Notes |
|---|---|---|
| `parent` | Deck? | The deck whose children are listed; null at top level |
| `decks` | DeckSummary[] | Direct children (or root decks), in manual order |
| `ancestors` | DeckPathSegment[] | `{id, name}` of the decks **above** `parent`, root first. Empty at top level and when `parent` is a root |
| `nextDueAt` | DateTime? | Next instant a card of this level becomes due; null = none scheduled |
| `nextOverdueTickAt` | DateTime? | Next local midnight at which a due status changes; null = nothing to re-evaluate |
| `isRootLevel` | bool *(derived)* | |
| `levelNewCardCount`, `levelDueCardCount`, `levelOverdueCardCount`, `levelDueTodayCardCount`, `levelScheduledCardCount` | int *(derived)* | Sums over `decks` |
| `levelOverdueDayCount` | int *(derived)* | Largest `overdueDayCount` among decks with due cards |
| `levelScheduleStatus` | DeckScheduleStatus *(derived)* | |

Failure: not found when `parentDeckId` no longer exists.

### Commands

| Command | Input | Output | Failures |
|---|---|---|---|
| `CreateRootDeck` | `name`, `schedulerType?` | Deck | Validation: `nameEmpty`, `nameTooLong`, `schedulerMissing` |
| `CreateSubDeck` | `parentDeckId`, `name` | Deck | Validation: name · Conflict: `parentHoldsCards`, `parentAtMaxDepth`, `unknownContentType`, `deckDepthUnknowable` |
| `RenameDeck` | `deckId`, `name` | — | Validation: name |
| `MoveDeck` | `deckId`, `targetParentDeckId` | — | Conflict: any `DeckMoveRejection` |
| `ReorderDeck` | `deckId`, `targetSiblingDeckId`, `placement` | — | Conflict: no longer siblings |
| `GetDeckDeletionImpact` | `deckId` | `{descendantDeckCount: int, cardCount: int}` | Not found |
| `DeleteDeck` | `deckId` | `batchId: String` — for undo | Not found |
| `ChangeUnlockedScheduler` | `rootDeckId`, `schedulerType` | — | Conflict: `schedulerNeedsRootDeck`, `schedulerLocked` |
| `ResetLearningProgress` | `rootDeckId`, `schedulerType` | — | Conflict: `resetNeedsRootDeck`, `resetSchedulerUnknown` |

### Watch `WatchDeckMoveTargets`

Input: `deckId` (the deck to move). Output `DeckMoveTarget[]`, ordered by tree
then creation time; empty when the deck is a root.

| Field | Type | Notes |
|---|---|---|
| `deck` | Deck | Candidate parent |
| `depth` | int | Level of the candidate, root = 1 |
| `rejection` | DeckMoveRejection? | null = eligible |
| `isEligible` | bool *(derived)* | |

---

## 4. Starter library

### Get `LoadStarterTemplates` → `DeckTemplate[]`

| Field | Type | Notes |
|---|---|---|
| `templateId` | String | Stable across app versions |
| `version` | int | |
| `locale` | String | Content language: `en`, `vi`, `ko`, … |
| `title` | String | |
| `contentSource` | String | Today always `memox-fixture` |
| `defaultSchedulerType` | SchedulerType | Suggestion only |
| `children` | DeckTemplateNode[] | |
| `cardCount` | int *(derived)* | Cards in the whole template |

`DeckTemplateNode`: `name: String` · `children: DeckTemplateNode[]` ·
`cards: DeckTemplateCard[]` — a node has children or cards, never both ·
`cardCount` *(derived)*.
`DeckTemplateCard`: `front: String` · `back: String` · `example?: String`.

### Get `GetInstalledTemplateKeys` → `{templateId: String, version: int}[]`

### Command `InstallDeckTemplate`

Input: `template`, `schedulerType?: SchedulerType` (null = the template's
default), `allowDuplicate: bool` (default false; true = the user confirmed a
second copy). Output: `DeckTemplateInstallOutcome`. Failure: storage failure
(nothing copied).

---

## 5. Library search

### Watch `SearchLibrary`

Input: `query: String`, `pageSize: int`, `cursor?` (opaque, from the previous
page). An empty query after trimming returns an empty page without reading.

Output `LibrarySearchPage`:

| Field | Type | Notes |
|---|---|---|
| `decks` | DeckSearchHit[] | All deck hits come before any card hit, across pages |
| `cards` | CardSearchHit[] | |
| `hasMore` | bool *(derived)* | |
| `isEmpty` | bool *(derived)* | |

`DeckSearchHit`

| Field | Type | Notes |
|---|---|---|
| `deckId` | String | |
| `name` | String | |
| `deckPath` | String[] | Names of the decks **above** it, root first; empty for a root |
| `rank` | SearchMatchRank | |
| `isCardDeck` | bool | Holds cards |

`CardSearchHit`

| Field | Type | Notes |
|---|---|---|
| `cardId` | String | |
| `deckId` | String | |
| `front` | String | |
| `back` | String | |
| `deckPath` | String[] | Names from the root **down to and including** the card's deck |
| `rank` | SearchMatchRank | Best of front, back, tag |
| `matchedTagName` | String? | Set when a tag matched |

---

## 6. Cards

### Card

| Field | Type | Notes |
|---|---|---|
| `id` | String | |
| `deckId` | String | |
| `front` | String | 1–60 chars |
| `back` | String | 1–240 chars |
| `isFlagged` | bool | |
| `example` | String? | ≤240 |
| `hint` | String? | ≤240 |
| `pronunciation` | String? | ≤240 |
| `createdAt` | DateTime | |
| `updatedAt` | DateTime | |

### CardStudyState

| Field | Type | Notes |
|---|---|---|
| `cardId` | String | |
| `schedulerType` | SchedulerType | Same as the root |
| `schedulerVersion` | int | Internal |
| `schedulerGeneration` | int | Same as the root |
| `learnedAt` | DateTime? | null = new |
| `dueAt` | DateTime? | null exactly when `learnedAt` is null |
| `lastAnsweredAt` | DateTime? | |
| `answerCount` | int | Scheduled answers only |
| `lapseCount` | int | |
| `currentBox` | int? | `eight_box` only, 1–8 |
| `easeFactor` | double? | `sm2` only, ≥1.3 |
| `intervalDays` | int? | `sm2` only |
| `repetitions` | int? | `sm2` only |

A new card already carries its algorithm's starting values (box, or ease /
interval / repetitions); it is `new` because `learnedAt` is null.

### Watch `WatchCardListItems` — clock-dependent

Input: `deckId`, `filter: CardListFilter`, `sort: CardListSort`,
`searchTerm?: String`, `tagIds: String[]` (empty = no tag filter), `limit: int`
(the loaded window; grows by pages).

Output `CardListItem[]`:

| Field | Type | Notes |
|---|---|---|
| `card` | Card | |
| `studyState` | CardStudyState | |
| `tagNames` | String[] | No guaranteed order |
| `state` | CardState *(derived)* | |
| `dueAt` | DateTime? *(derived)* | |
| `dueBadge` | CardDueBadge *(derived)* | |

Search term matches `front` or `back` by containment, ignoring case, keeping
accents. Tags are OR among themselves, AND with filter and search.

### Other card reads

| Contract | Input | Output |
|---|---|---|
| Watch `WatchCardCount` | `deckId`, `filter`, `searchTerm?`, `tagIds` | `int` — same predicate as the list |
| Get `ReadCardIdsMatching` | `deckId`, `filter`, `searchTerm?`, `tagIds` | `String[]` — for select all |
| Watch `WatchCardStateDistribution` | `deckId` | `{total, isNew, beginning, reviewing, mastered}: int` |
| Watch `WatchDeckContext` | `deckId` | `{deckName: String, ancestors: {id, name}[]}` — ancestors root first |
| Watch `WatchCardMoveTargets` | `sourceDeckId` | `CardMoveTarget[]` = `{deckId, name, parentName?}` — eligible targets only |
| Watch `WatchCardTags` | `cardId` | `{id, name}[]` |
| Get `GetCard` | `cardId` | Card |
| Get `ReadDeckHoldsCards` | `deckId` | `bool` |

### Card commands

| Command | Input | Output | Failures |
|---|---|---|---|
| `CreateCard` | `deckId`, `front`, `back`, `example?`, `hint?`, `pronunciation?` | Card | Validation: `CardValidationProblem` · Conflict: `parentIsRoot`, `deckHoldsDecks`, `unknownContentType`, `rootSchedulerMissing`, `unknownScheduler` · Not found: `deckGone` |
| `UpdateCard` | `cardId`, `front`, `back`, `example?`, `hint?`, `pronunciation?` | Card | Validation · Not found: `cardGone` |
| `SetCardFlag` | `cardId`, `isFlagged` | — | Not found |
| `SetCardsFlag` | `cardIds`, `isFlagged` | — | All or nothing |
| `AddCardTag` | `cardId`, `name` | — | Validation: `TagValidationProblem` |
| `RemoveCardTag` | `cardId`, `tagId` | — | |
| `AddTagToCards` | `cardIds`, `name` | — | Validation: `tooManyTags` for any card rejects all |
| `DeleteCard` | `cardId` | `batchId` — for undo | Not found |
| `DeleteCards` | `cardIds` | — | One Trash entry per card; no undo |
| `MoveCards` | `cardIds`, `targetDeckId` | — | Conflict: `moveTargetIsSameDeck`, `moveTargetIsRoot`, `moveTargetHoldsDecks`, `moveCrossRoot` |

---

## 7. Card detail and history

### Watch `WatchCardDetail`

Input: `cardId`. Output `CardDetail`: `card: Card` · `studyState: CardStudyState` ·
`tagNames: String[]` · `state: CardState` *(derived)*. Not found: `cardGone`.

### Get `LoadCardHistoryPage`

Input: `cardId`, `after?: {answeredAt, id}` (the previous page's `nextCursor`).

Output `CardHistoryPage`: `events: CardHistoryEvent[]` (newest first, ≤50) ·
`hasMore: bool` · `nextCursor?: {answeredAt: DateTime, id: String}`.

`CardHistoryEvent`

| Field | Type | Notes |
|---|---|---|
| `id` | String | |
| `answeredAt` | DateTime | |
| `schedulerType` | SchedulerType | At the time of the answer |
| `schedulerGeneration` | int | Group key |
| `kind` | StudyAnswerKind | |
| `mode` | StudyMode | Never `browse` |
| `action` | StudyAction | |
| `outcomeReason` | StudyOutcomeReason? | `timeout` |
| `usedHint` | bool? | `fill` only |
| `nextDueAt` | DateTime? | Present when the schedule moved |
| `previousBox`, `nextBox` | int? | `eight_box` rows |
| `previousEaseFactor`, `nextEaseFactor` | double? | `sm2` rows |
| `previousIntervalDays`, `nextIntervalDays` | int? | `sm2` rows |
| `hasScheduleChange` | bool *(derived)* | Any before/after field present |

---

## 8. Tags

| Contract | Input | Output | Failures |
|---|---|---|---|
| Watch `WatchTagCatalog` | `searchTerm?` | `TagCatalogEntry[]`, sorted by case-folded name | |
| Command `RenameTag` | `tagId`, `name` | `TagRenameOutcome` | Validation: `TagValidationProblem` · `tagMissing` |
| Command `DeleteTag` | `tagId` | — | `tagMissing` |

`TagCatalogEntry`: `id: String` · `name: String` · `cardCount: int` (active
cards) · `linkedCardCount: int` (including cards in Trash — the number that
lose the tag on delete).

---

## 9. Import

| Step | Contract | Input | Output | Failures |
|---|---|---|---|---|
| 1 | Command `PickCardImportSource` | — | A file source, or nothing when cancelled | `unsupportedFile`, `unreadableFile` |
| 2 | Get `ParseCardTransfer` | file source, or pasted text | A sheet: rows of cell strings | `invalidEncoding`, `emptySource`, `emptySheet`, `unreadableFile` |
| 3 | Get `BuildCardImportPreview` | `deckId`, sheet, `mapping`, `hasHeaderRow: bool` | CardImportPreview | |
| 4 | Command `CommitCardImport` | `deckId`, `plan` = `{records, shouldIncludeDuplicates: bool}` | CardImportResult | Conflict (target no longer accepts cards) · storage failure |

`mapping` — column index → `CardTransferField`. A field is assigned to at most
one column. Complete when `front` and `back` are both assigned. Built
automatically from header names: the six field names, plus aliases
`term`/`word`/`question` → front, `meaning`/`definition`/`answer` → back,
`sentence`/`examples` → example, `hints` → hint, `reading` → pronunciation,
`tag`/`label`/`labels` → tags. The user may reassign any column.

`CardImportPreview`

| Field | Type | Notes |
|---|---|---|
| `rows` | CardImportRowPreview[] | One per data row |
| `totalRows` | int | |
| `readyCount` | int | |
| `duplicateCount` | int | Both duplicate kinds |
| `invalidCount` | int | |
| `blankCount` | int | |

`CardImportRowPreview`: `sourceRowNumber: int` · `status: CardImportRowStatus` ·
`front: String` · `back: String` · `cardProblems: CardValidationProblem[]` ·
`tagProblems: TagValidationProblem[]`.

`CardImportResult`: `imported: int` · `duplicatesSkipped: int`.

Outcome of the flow: `completed` (all imported) · `completedWithSkips` (some
invalid or duplicate rows skipped) · `noCardsAdded` (`imported == 0`) ·
`commitFailure`.

---

## 10. Export

### Command `ExportCards`

Input `CardExportRequest`: `deckId` · `scope` · `format: CardTransferFormat`.
`scope` is one of `wholeDeck` or `selection {cardIds: String[]}` (duplicates
removed; must not be empty).

Output: `CardExportResult`. Failures: `CardExportProblem`.

File content: header row `front,back,example,hint,pronunciation,tags`; one row
per card, ordered by creation time; tags joined with `;` (a `;` inside a tag is
written `\;`, a backslash `\\`); empty optional cells are empty. CSV and TSV are
UTF-8 with BOM; XLSX cells are text.

---

## 11. Trash

### Watch `WatchTrashBatches` → `TrashBatch[]`, newest first

| Field | Type | Notes |
|---|---|---|
| `batchId` | String | |
| `itemType` | TrashItemType | |
| `itemName` | String | Deck name, or card front |
| `deletedAt` | DateTime | |
| `originDeckId` | String? | The parent it was deleted from; null for a root deck |
| `originDeckName` | String? | |
| `originPath` | `{deckId, name}[]` | Decks **above** the origin deck, root first; empty when the origin is a root deck or there is no origin |
| `deckCount` | int | Decks inside this entry, the item itself included |
| `cardCount` | int | Cards inside this entry |
| `isRootDeck` | bool *(derived)* | |
| `expiresAt` | DateTime *(derived)* | `deletedAt + 30 days` |
| `daysLeft` | int *(derived)* | Remaining time rounded **up** to whole days; 0 when expired |

### Watch `WatchTrashRestoreTargets`

Input: `batchId`. Output: eligible `TrashRestoreTarget[]`, each either
`topLevel` (root decks only) or `deck {deckId, name, parentName?}`.

### Commands

| Command | Input | Failures |
|---|---|---|
| `RestoreTrashBatch` | `batchId`, `target` | `targetNoLongerValid`, `targetLevelMismatch`, `unknownItemType`, `batchHeightUnknowable` |
| `UndoDelete` | `batchId` | `undoOriginUnavailable` |
| `PurgeTrashBatches` | `batchIds` | `purgeWouldTakeAnotherBatch` |
| `PurgeExpiredTrash` | — | System-run on start, resume and opening Trash |

---

## 12. Study

### Watch `WatchStudyHome` — clock-dependent

Output `StudyHome`:

| Field | Type | Notes |
|---|---|---|
| `resume` | StudyHomeResume? | Today's resumable session |
| `decks` | StudyHomeDeck[] | Root decks, ordered overdue ↓, due today ↓, new ↓, name, id |
| `nextDueAt` | DateTime? | |
| `nextOverdueTickAt` | DateTime? | |
| `isLibraryEmpty` | bool *(derived)* | No root decks |
| `hasNoCards` | bool *(derived)* | Root decks exist, none has a card |
| `studiableDecks` | StudyHomeDeck[] *(derived)* | Decks with at least one card |

`StudyHomeResume`: `sessionId` · `deckId` · `deckName` · `kind: StudySessionKind` ·
`currentMode: StudyMode`.

`StudyHomeDeck`: `deckId` · `deckName` · `schedulerType` · `totalCardCount` ·
`overdueCount` · `dueTodayCount` · `newCount` · `dueCount` *(derived)* ·
`hasWorkload` *(derived)* · `isStudiable` *(derived, has cards)*.

### Deck study entry

| Contract | Input | Output |
|---|---|---|
| Get `GetStudyDeckContext` | `deckId` | `{deckId, deckName, rootDeckId, schedulerType, schedulerGeneration}` |
| Watch `WatchStudyEntry` — clock-dependent | `deckId` | `StudyEntrySummary` = `{newCount, dueCount, fillableCount, distinctMeanings}: int` |
| Get `GetReviewOptions` | `deckId` | `{modes: StudyMode[], schedulerType}` — `modes` never contains `browse` |
| Get `ResumeStudyDay` — clock-dependent | `deckId` | StudySession? — today's in-progress session for the deck |

Per-mode capacity for review *(derived from `StudyEntrySummary`)*:

| Mode | Cards it can take | Unavailable when |
|---|---|---|
| `self_assess` | `dueCount` | — |
| `match` | `dueCount` | fewer than 2 |
| `guess` | `dueCount` if `distinctMeanings ≥ 5`, else 0 | fewer than 5 distinct meanings |
| `recall` | `dueCount` | 0 |
| `fill` | `fillableCount` (due cards with an example) | 0 |

`isDirectionChoiceRequiredFor(mode)` *(derived)* is true only for `sm2` +
reviewing + `self_assess`.

### Study options

| Contract | Input | Output | Failures |
|---|---|---|---|
| Get `GetStudyOptions` | `deckId` | `{cardLimit: int, newCardOrder, isRootOverride: bool}` | |
| Command `SaveStudyOptions` | `deckId`, `cardLimit: String` (as typed), `newCardOrder` | — | `StudyCardLimitProblem` |
| Command `ClearStudyOptionsOverride` | `deckId` | — | |

### Session

**Command `OpenStudySession`** — clock-dependent

Input: `deckId` · `kind: StudySessionKind` · `reviewMode?: StudyMode` (required
for reviewing) · `direction?: StudySessionDirection` (required exactly when
`isDirectionChoiceRequiredFor`) · `resumeSessionId?` (continue instead of
starting).

Output `StudySessionStart`: `session: StudySession` · `deckName` ·
`schedulerType` · `actions: StudyAction[]` (the algorithm's action set) ·
`cards: StudyCard[]` (the session's card set).

Failures: `nothingDueToReview`, `nothingLeftToLearn`, `modeHasNoContent`,
`modeNotSupportedByScheduler` · validation when a required direction is
missing · conflict when a direction is given where none applies.

`StudySession`

| Field | Type | Notes |
|---|---|---|
| `id` | String | |
| `deckId` | String | Root or sub-deck |
| `rootDeckId` | String | |
| `schedulerGeneration` | int | |
| `kind` | StudySessionKind | |
| `currentMode` | StudyMode | Stage running now |
| `status` | StudySessionStatus | |
| `endReason` | StudySessionEndReason? | |
| `cursor` | int | Internal |
| `cardLimit` | int | Fixed at open |
| `direction` | StudySessionDirection? | |
| `startedAt` | DateTime | |
| `endedAt` | DateTime? | |
| `isOpen` | bool *(derived)* | |

**Get `GetNextStageTurn`** — clock-dependent

Input: `session`. Output: `(mode?: StudyMode, turn?: StudyTurn)`. A null mode
means the session has finished; a new mode means the learning sequence moved to
the next stage.

`StudyTurn`: `item: StudyQueueItem` · `card: StudyCard` · `progress: StudyStageProgress`.

`StudyCard`: `id` · `front` · `back` · `example?` · `hint?` · `pronunciation?` ·
`frontFolded` · `backFolded` (internal).

`StudyQueueItem` — relevant to design: `mode` · `round` · `direction?:
StudyRecallDirection` · `remainingMs?: int` (recall) · `isRevealed: bool`
(recall) · `status`. Internal: `sessionId`, `cardId`, `position`,
`availableAt`, `answersInSession`.

`StudyStageProgress`: `round: int` · `done: int` · `total: int` ·
`completedCardIds: String[]` · `roundCardIds: String[]` · `fraction` *(derived)*
· `remaining` *(derived)*.

**Mode payloads** *(built from the turn and the session's cards)*

| Mode | Payload |
|---|---|
| `guess` | `GuessQuestion` = `{term: StudyCard, options: {cardId, text}[5]}` — option text is a card's back; correct when `option.cardId == term.id` |
| `match` | `MatchBoard` = `{terms: MatchTile[], meanings: MatchTile[]}`; `MatchTile` = `{cardId, text, isTerm}`; a pair is correct when both tiles share `cardId` |
| `fill` | `FillOutcome` = `{isCorrect, comparisonVersion, hasUsedHint}` — the typed text is not kept |
| `recall` | 20-second limit; `remainingMs` and `isRevealed` resume a turn |

**Commands during a session**

| Command | Input | Output | Failures |
|---|---|---|---|
| `MarkBrowsed` | `sessionId`, `cardId` | — | |
| `SubmitStudyAnswer` | `session`, `cardId`, `mode`, `action`, `outcomeReason?`, fill grading details | `StudyAnswerCommit` = `{cardId, round, currentItemStatus}` · `isCleared` *(derived)* | `staleGeneration`, `sessionNotOpen`, storage failure (retry the same turn) |
| `SaveTurnProgress` | recall remaining time / revealed | — | |
| `AdvanceStudyStage` | `session` | next `StudyMode?` | |
| `EndStudySession` | `sessionId`, `status`, `reason?` | — | Leaving = `abandoned` + `user_exit` |

**Get `GetSessionSummary`**

Input: `sessionId`, `schedulerType`. Output `StudySessionSummary`: `kind` ·
`status` · `endReason?` · `finishedCards: int` (learned in a learning session,
reviewed in a review session) · `answeredCards: int` · `wrongTurns: int` ·
`totalTurns: int` · `hasCompleted` *(derived)*.

---

## 13. Progress

### Watch `WatchProgressOverview` — clock-dependent, re-emits at local midnight

Output `ProgressOverview`:

| Field | Type | Notes |
|---|---|---|
| `lastSevenDays` | ProgressActivityDay[7] | Oldest → newest, today last, zero-filled |
| `currentStreakDays` | int | |
| `hasLifetimeActivity` | bool | |
| `nextLocalMidnight` | DateTime | |
| `today` | ProgressActivityDay *(derived)* | Last element |
| `isStreakHeldFromYesterday` | bool *(derived)* | Streak > 0 and today inactive |

`ProgressActivityDay`: `localDate: LocalDate` · `totalCards: int` (card-days) ·
`learningCards: int` · `reviewingCards` *(derived)* · `isActive` *(derived)*.

### Watch `WatchDeckActivity` — clock-dependent

Input: `deckId?` — null for the library level.

Output `DeckActivitySnapshot`:

| Field | Type | Notes |
|---|---|---|
| `scopeDeckId` | String? | null at library level |
| `scopeName` | String? | |
| `scopePath` | `{id, name}[]` | Decks above the scope, root first |
| `decks` | DeckActivity[] | Direct children (library: root decks) |
| `scopeLast7Days` | DeckActivityMetrics | |
| `scopeLast30Days` | DeckActivityMetrics | |
| `nextDayBoundaryAt` | DateTime | |
| `isTopLevel` | bool *(derived)* | |

`DeckActivity`: `deckId` · `name` · `path: {id, name}[]` (decks above it, root
first) · `last7Days: DeckActivityMetrics` · `last30Days: DeckActivityMetrics`.
Sorted by the area for the selected `ProgressRange`: `activeCardCount` ↓, name,
id.

`DeckActivityMetrics`: `activeCardCount` · `activeDayCount` ·
`learningCardDayCount` · `reviewingCardDayCount` · `cardDayCount` *(derived)* ·
`hasActivity` *(derived)*.

---

## 14. Settings

| Contract | Input | Output | Failures |
|---|---|---|---|
| Watch `WatchAppSettings` | — | `AppSettings` = `{cardLimit: int, newCardOrder, themeMode, language}` | |
| Command `SaveThemeMode` | `themeMode` | — | |
| Command `SaveLanguage` | `language` | — | |
| Command `SaveStudyDefaults` | `cardLimit: String` (as typed), `newCardOrder` | — | `StudyCardLimitProblem` |
| Command `ResetAppSettings` | — | — | |

Defaults: `cardLimit` 20 · `newCardOrder` `created` · `themeMode` `system` ·
`language` `system`.

---

## 15. Daily reminder

### Watch `WatchReminderOverview`

Output `ReminderOverview`: `settings: ReminderSettings` · `capability:
ReminderCapability` · `isChangeable` *(derived, capability is supported)*.

`ReminderSettings`: `isEnabled: bool` · `time: {minuteOfDay: int}` (`hour`,
`minute` derived; local time) · `lastDeliveredAt?: DateTime`.

Permission is not part of the overview: a refusal surfaces as the
`permissionDenied` failure of `EnableReminder`.

### Commands — clock-dependent

| Command | Input | Failures |
|---|---|---|
| `EnableReminder` | `time` | `platformUnavailable`, `permissionDenied`, `scheduleFailed`, `settingsWriteFailed` · `outOfRange` |
| `ChangeReminderTime` | `time` | `scheduleFailed`, `settingsWriteFailed` · `outOfRange` |
| `DisableReminder` | — | `cancelFailed` (the reminder is off, an earlier notification may remain), `settingsWriteFailed` |

### Notification content (system-built)

`ReminderSummary` — built only when something is due: `totalDueCount: int` ·
`leadDeckName: String` · `otherDeckCount: int`. It is computed from
`ReminderWorkload[]` = `{deckId, deckName, overdueCount, dueTodayCount,
overdueDayCount}` per root deck, ordered by urgency (overdue ↓, overdue days ↓,
due today ↓, name, id).

---

## Appendix A · Standalone backend (not used by the app)

`memox-api` is a Spring Boot + PostgreSQL service in the same repository,
described by its own OpenAPI document as a *standalone MemoX backend API;
authentication and sync are not enabled yet*. The app does not call it, has no
network dependency and no account. **Do not design network, sign-in, sync or
offline-conflict states.**

For orientation only, it mirrors a subset of the local contracts:

| Resource | Operations |
|---|---|
| `/api/v1/decks` | list, create root, summaries, get, rename, delete, children, move, reorder, level, tree, card move targets, card keys, export |
| `/api/v1/cards` | list, get, update, history, tags, state counts, ids, bulk delete / flag / move / tag |
| `/api/v1/tags` | catalog, rename, delete |
| `/api/v1/trash` | list, restore, purge, purge expired |
| `/api/v1/health` | health |

It has no study, progress, reminder, settings, search or starter-library
endpoints.
