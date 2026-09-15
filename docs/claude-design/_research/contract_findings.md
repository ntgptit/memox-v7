# UI Data Contract & Screen Requirements

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Research note behind the Claude Design handoff — UI data contracts and screen requirements as found at base commit de1e862c |
| **Scope** | For each product area: read-model fields, enums, use cases (user actions), failures/refusals, states. Out of scope: current Flutter UI layout, widgets, theme, state-management mechanics |
| **Source of truth for** | — (derived research; docs/ and lib/ remain the sources) |
| **Depends on** | docs/product.md, docs/architecture.md (AD-06, AD-11, AD-12, AD-13, AD-19), docs/business-rules.md, docs/business-rules/study-mode.md, docs/use-cases.md, docs/data-model.md |
| **Updated by task** | claude-design-handoff (no WBS id) |
| **Last updated** | 2026-09-16 |

All facts below are SOURCE-CONFIRMED by file path unless marked DERIVED or UNKNOWN.

## 1. Product-area map

Four top-level destinations, fixed order: **Library (Thư viện) · Study (Học) · Progress (Tiến độ) · Settings (Cài đặt)** — SOURCE-CONFIRMED `docs/product.md:162-179`, `docs/architecture.md` AD-19 (`lib/core/navigation/route_names.dart`). Cold start opens Library/Decks. Supported UI languages = ARB locales: `en`, `vi` (`lib/l10n/app_en.arb:2`, `app_vi.arb:2`).

| Area | Parameters | Parent |
|---|---|---|
| Library (deck tree, root) | none | top-level |
| Deck detail | `deckId` | Library |
| Starter library | none | Library |
| Library search | none (query, debounced) | Library |
| Card list of a deck | `deckId` | Deck detail |
| Card editor create | `deckId` | Card list |
| Card editor edit | `deckId, cardId` | Card list |
| Card import | `deckId` | Card list |
| Card export (no route) | triggered from card list menu / selection bar (`card_list_menu_widget.dart`, `card_selection_bar_widget.dart`) | Card list |
| Tag catalog | none (top-level; a tag belongs to no deck, BR-93) | Library |
| Card detail + history | `deckId, cardId` | Card list |
| Trash | none | Library |
| Study home (tab) | none | top-level |
| Study entry for a deck | `deckId` (two route names for one screen: `studyDeck` under Study tab, `deckStudy` under Library tab — branch determines Back target) | Study / Library |
| Study options for a deck | pushed from entry, mounted twice (`studyDeckOptions`, `deckStudyOptions`) | Study entry |
| Study session | `sessionId` implicit | Study entry |
| Progress overview | none | top-level |
| Progress by deck (drill-down) | `deckId` | Progress overview |
| Settings | none | top-level |
| Reminder settings | none | Settings |

## 2. Per-area contracts

### Library / Deck tree (UC-06)
One screen models both root and inside-a-deck (`DeckListSnapshot`, `lib/features/deck/domain/models/deck_list_snapshot_model.dart`).
- **Contract `watchDeckListUseCase`**: input optional `deckId`; output `DeckListSnapshot`:
  - `parent: DeckEntity?` — null at root
  - `decks: List<DeckSummary>` — direct children (or all roots)
  - `ancestors: List<DeckPathSegment>` — root-first breadcrumb, `{id, name}`
  - `nextDueAt: DateTime?` — next instant a card becomes due, null = nothing to wait for
  - `nextOverdueTickAt: DateTime?` — next local midnight when a due badge should re-tick
  - derived: `levelDueCardCount`, `levelNewCardCount`, `levelOverdueCardCount`, `levelDueTodayCardCount`, `levelScheduledCardCount`, `levelOverdueDayCount`, `levelScheduleStatus`
- **`DeckSummary`** (one row): `deck: DeckEntity`, `totalCardCount`, `newCardCount`, `dueCardCount`, `overdueCardCount` (int, BR-162 partition), `overdueDayCount`, `learnedCardCount`, `subDeckCount`, `schedulerType: SchedulerType` (resolved from root). Derived getters: `learnedFraction`, `isFullyLearned`, `hasNewCards`, `dueTodayCardCount`, `scheduledCardCount`, `hasDueCards`, `scheduleStatus: DeckScheduleStatus`, `hasStudyableCards`.
- **`DeckEntity`**: `id, name, parentDeckId?, rootDeckId, contentType: DeckContentType, schedulerType?: SchedulerType (root only), schedulerGeneration?: int (root only), firstAnsweredAt?: DateTime (root only), createdAt, updatedAt`. `maxTreeDepth = 10` (root = level 1).
- **`DeckContentType`** enum: presumably `unset | deck | card` (DERIVED from BR-58/BR-61/BR-62 prose; file not read in full this pass — see Unknowns).
- **User actions → use cases**: create root deck (`create_root_deck_use_case`, needs name + scheduler), create sub-deck (`create_sub_deck_use_case`), rename (`rename_deck_use_case`), delete → soft-delete to Trash (`delete_deck_use_case.call` and `.forUndo`), move (`move_deck_use_case`), reorder siblings (`reorder_deck_use_case`), reset learning progress (`reset_learning_progress_use_case`), change unlocked scheduler (`change_unlocked_scheduler_use_case`), get deletion impact preview (`get_deck_deletion_impact_use_case` → `DeckDeletionImpact{descendantDeckCount, cardCount}`), install starter template(s), watch move targets (`watch_deck_move_targets_use_case` → `List<DeckMoveTarget>`).
- **Move picker contract `DeckMoveTarget`**: `deck, depth (root=1), rejection: DeckMoveRejection?`; `isEligible = rejection == null`. Rejection reasons (`deck_move_failure.dart`): `sourceIsRoot, itself, ownDescendant, holdsCards, differentScheduler, differentGeneration, tooDeep, alreadyParent`.
- **Refusals** (`deck_validation_failure.dart`): `nameEmpty, nameTooLong (max 200, `kDeckNameMaxLength`), schedulerMissing`. Conflicts (`deck_conflict_failure.dart`): `parentHoldsCards, parentAtMaxDepth, resetNeedsRootDeck, resetSchedulerUnknown, schedulerNeedsRootDeck, schedulerLocked, unknownContentType, deckDepthUnknowable, subtreeHeightUnknowable`.
- **States**: `DeckListFilter {all, due}`, `DeckListSort {manual, dateAdded, name, ...}` (5 values, sheet-driven — `deck_list_view_state.dart`; full enum not fully enumerated, see Unknowns for remaining 2 values). Empty states from ARB: `decksEmptyTitle/Message` (no decks), `decksLoadErrorTitle/Message`, `decksNoDueTitle` ("Nothing due right now"), `deckDetailEmptyUnsetTitle/Message` (empty unset deck), `deckDetailEmptyDeckTitle/Message`, `deckDetailEmptyCardTitle/Message`, `deckDetailNotFoundTitle/Message`, `deckDetailLoadErrorTitle`.

### Starter library (UC-01)
Installs a `DeckTemplate` (already-validated tree, no ids) as a user's own copy (BR-33/34/35). Contract: `templateId, version, locale, title: DeckName, contentSource, defaultSchedulerType, children: List<DeckTemplateNode>` (branch or leaf; leaf holds `DeckTemplateCard{front, back, example?}` as `CardText`/`CardDetailText`). `get_installed_template_keys_use_case` → set of `(templateId, version)` already installed (idempotency, BR-37). Two shipped templates: `eight_box_starter.json`, `sm2_starter.json` — bilingual EN front / VI back sample content, tagged `content_source: "memox-fixture"` with an explicit non-production notice.

### Library search (UC-20)
`LibrarySearchPage{decks: List<DeckSearchHit>, cards: List<CardSearchHit>, cursor: LibrarySearchCursor}`. Query normalized via `SearchQuery{raw, folded}`. Hits are a sealed `LibrarySearchHit` union: `DeckSearchHit{deckId, name, deckPath, rank, isCardDeck}`, `CardSearchHit{cardId, deckId, front, back, deckPath, rank}`. `SearchMatchRank {exact(0), prefix(1), contains(2)}` — best-of across front/back/tags. States (`LibrarySearchPhase`): `initial, debouncing, loading, ready, failed`. Empty state from ARB: `cardSearchEmptyTitle/Message` pattern reused; deck-side equivalent likely exists (not confirmed).

### Card list of a deck (UC-04, D3/D5)
- **Contract `watchCardListItemsUseCase`** → `List<CardListItemModel>{card: CardEntity, studyState: CardStudyStateEntity, tagNames: List<String>}`; derived `state: CardState`, `dueAt: DateTime?`.
- **`CardEntity`**: `id, deckId, front, back, isFlagged: bool, example?, hint?, pronunciation?, createdAt, updatedAt`. Front max 60 chars, back max 240, each optional detail max 240 (`kCardFrontMaxLength=60, kCardBackMaxLength=240, kCardDetailMaxLength=240`).
- **`CardStudyStateEntity`**: `cardId, schedulerType, schedulerVersion, schedulerGeneration, learnedAt?, dueAt?, lastAnsweredAt?, answerCount, lapseCount, currentBox? (eight_box), easeFactor?/intervalDays?/repetitions? (sm2)`.
- **`CardState` enum** (derived, never stored): `isNew, beginning (interval <8d), reviewing (≥8d, <mastered), mastered (box 8 / sm2 ≥128d)`.
- **Filter/sort**: `CardListFilter {all, due, isNew, flagged}`; `CardListSort {newest (default), dueFirst}`.
- **Tags**: `TagFilter` (set of tag ids, toggled/retained), `TagCatalogEntry{id, name, cardCount (active only), linkedCardCount (incl. trashed)}`.
- **Selection/bulk**: `CardSelectionState`. Bulk actions → use cases: `delete_cards_use_case` (bulk soft-delete), `move_cards_use_case`, `add_tag_to_cards_use_case`, `set_cards_flag_use_case`.
- **Single-card actions**: create (`create_card_use_case`), update (`update_card_use_case`), delete/undo (`delete_card_use_case`), flag toggle (`set_card_flag_use_case`), tag add/remove (`add_card_tag_use_case`, `remove_card_tag_use_case`), rename/merge/delete tag (`rename_tag_use_case → TagRenameOutcome{renamed|merged}`, `delete_tag_use_case`).
- **Card move target** `CardMoveTarget{deckId, name, parentName?}` — legal targets pre-filtered by query.
- **Refusals**: `CardValidationProblem {frontEmpty, frontTooLong, backEmpty, backTooLong, exampleTooLong, hintTooLong, pronunciationTooLong}`; `CardConflictReason {parentIsRoot, deckHoldsDecks, unknownContentType, moveTargetIsSameDeck, moveTargetIsRoot, moveTargetHoldsDecks, moveCrossRoot, rootSchedulerMissing, unknownScheduler}`; `CardNotFoundReason {deckGone, cardGone}`; Tag: `TagValidationProblem {nameEmpty, nameTooLong (max 50, kTagNameMaxLength), nameTaken, tooManyTags (max 10, kMaxTagsPerCard), nameHasControlCharacter}`.
- **States/ARB**: `cardListEmptyTitle/Message/Action`, `cardListNoMatchTitle`, `cardListError`, `cardSearchEmptyTitle/Message`, `cardBulkDeleteTitle/ConfirmAction` (pluralized count), `cardMoveTargetTitle`, `cardMoveEmptyTitle/Message`.

### Card editor (UC create/edit, M4.9-4.11)
Fields: front (≤60), back (≤240), example/hint/pronunciation (≤240 each, optional), flag (bool), tags. Draft state `CardContentDraftState`, submit lifecycle `CardSubmitState`. ARB: `cardEditorCreateTitle`, `cardEditorEditTitle`, `cardEditorDiscardTitle/Confirm`, `cardEditorTrashTitle`, `cardDetailTooLongError`, `cardTagEmptyError/TooLongError/TooManyError/ControlCharacterError`.

### Card import (UC-10)
Wizard: `CardImportStep {source, preview, confirm}`; source kind `{upload, paste}`. `CardTransferFormat {csv, tsv, xlsx}` — file extension + MIME; `.tab` alias accepted on read. `CardTransferField {front, back, example, hint, pronunciation, tags}` with alias auto-map (e.g. `term/word/question → front`); tags cell separator `;`. Preview: `CardImportRowPreview{sourceRowNumber, status: CardImportRowStatus, front, back, cardProblems, tagProblems}`; `CardImportRowStatus {ready, invalid, duplicateExisting, duplicateInFile, blank}` (BR-169/170 — duplicate = same folded front+back). `CardImportPreview{rows, records, totalRows, readyCount, duplicateCount, invalidCount, blankCount}`. Commit → `CardImportResult{imported, duplicatesSkipped}`. Presentation phase (`CardImportPhase`): `source, parsing, preview, confirm, submitting, completed, completedWithSkips, noCardsAdded` (+ likely an error phase, not fully read). Failures (`card_transfer_failure.dart`): `unsupportedFile, invalidEncoding, emptySource, emptySheet, unreadableFile`.

### Card export (no route — UC-11, sheet from Card list menu / selection bar)
Scope: sealed `CardExportScope` = `CardExportWholeDeckScope` or `CardExportSelectionScope(cardIds)`. Request: `CardExportRequest{deckId, scope, format: CardTransferFormat}`. Result: `CardExportResult {shared, dismissed}` — app never claims "saved", only "handed to OS" (BR-181); dismiss = cancel, not failure. Presentation phase `CardExportPhase {initial, generating, shared, retryableError, invalidScope}`. Failures (`card_export_failure.dart`): `emptyScope, staleSelection, deckMissing, readFailed, encodeFailed, shareUnavailable, sharePlatformError`.

### Tag catalog (UC-18)
`TagCatalogEntry{id, name, cardCount (active), linkedCardCount (incl. trashed)}`. Actions: rename (outcome `renamed` or `merged` if collides with existing tag), delete (impact = `linkedCardCount`). Failures: `TagCatalogProblem` incl. `tagMissing`.

### Card detail + review history (UC-19, BR-240/241/244)
`CardDetailModel{card, studyState, tagNames}` — content + tags + current schedule in one read; derived `state: CardState`. History is a **separate, paginated** stream (`CardHistoryPageModel{events, hasMore, nextCursor}`), never in the same read. `CardHistoryEventModel`: `id, answeredAt, schedulerType, schedulerGeneration, kind: StudyAnswerKind, mode: StudyMode, action: StudyAction, outcomeReason?: StudyOutcomeReason, usedHint?: bool, nextDueAt?, previousBox?/nextBox?, previousEaseFactor?/nextEaseFactor?, previousIntervalDays?/nextIntervalDays?`; derived `hasScheduleChange`. History states (`CardHistoryStatus`): `loadingInitial, loaded, loadingMore, pageError`; derived `isEmpty` (no reviews ever), `isComplete` (all pages read).

### Trash (UC-21, BR-256/259/264/266)
`TrashBatchEntity{batchId, itemType: TrashItemType (card|deck), itemName, deletedAt, originDeckId?, originDeckName?, originPath: List<TrashPathSegment>, deckCount, cardCount}`; derived `isRootDeck`, `expiresAt = deletedAt + 30 days`. Retention: `TrashRetention.window = 30 days`, `daysLeft()` floors-at-0/ceils-remaining. Filter `TrashFilter {all, cards, decks}`. Restore target: sealed `TrashRestoreTarget` = `TrashTopLevelTarget` or `TrashDeckTarget{deckId, name, parentName?}`; eligibility candidates carry `rejection`. Actions: restore (`restore_trash_batch_use_case`), undo a just-performed delete (`undo_delete_use_case`), purge selected (`purge_trash_batches_use_case`), auto-purge expired (`purge_expired_trash_use_case`). Conflicts (`trash_conflict_failure.dart`): `targetNoLongerValid, targetLevelMismatch, undoOriginUnavailable, purgeWouldTakeAnotherBatch, unknownItemType, batchHeightUnknowable`.

### Study home (tab, UC-14)
`StudyHomeModel{resume?: StudyHomeResumeModel, decks: List<StudyHomeDeckModel>, nextDueAt?, nextOverdueTickAt?}`; derived `isLibraryEmpty`, `hasNoCards`. `StudyHomeResumeModel{sessionId, deckId, deckName, kind: StudySessionKind, currentMode: StudyMode, ...}` — an in-progress session the user can resume. `StudyHomeDeckModel{deckId, deckName, schedulerType, totalCardCount, overdueCount, dueTodayCount, newCount}`; derived `dueCount, hasWorkload, isStudiable`.

### Study entry for a deck (UC-14/15)
`StudyEntrySummaryModel{newCount, dueCount, fillableCount (due cards with an example), distinctMeanings (for guess mode's 5 options)}` — one read for badge + mode chooser. `StudyReviewOptionsModel{modes: List<StudyMode> (never contains browse), schedulerType}`; `isDirectionChoiceRequiredFor(mode)` decides if BR-203's direction picker must show. `StudyDeckContextModel{deckId, deckName, rootDeckId, schedulerType, schedulerGeneration}`.

### Study options for a deck (UC-15, BR-147/148/212)
`StudyOptionsModel{cardLimit: int (1-200, kMinCardLimit/kMaxCardLimit, default 20), newCardOrder: NewCardOrder (created default | random), isRootOverride: bool}`. Two-tier resolve: app defaults vs root-deck override; sub-decks MUST NOT override. `StudyCardLimit` parse errors: `notANumber, tooSmall, tooLarge`.

### Study session (browse / self_assess / match / guess / recall / fill, UC-16/BR-97-BR-154)
Two session kinds: `learning` (`learned_at IS NULL`, walks the algorithm's whole stage sequence) vs `reviewing` (`learned_at NOT NULL AND due_at<=now`, one chosen mode) — never mixed. `StudyMode {browse, selfAssess, match, guess, recall, fill, unknown}` — the algorithm (eight_box: 5 modes; sm2: 2) declares its own sequence, not the screen. `StudyAction`: eight_box uses `{forgotten, remembered}`; sm2 uses `{again, hard, good, easy}` — buttons must come from `scheduler.supportedActions`, never hardcoded 4. `StudyAnswerKind {learning, scheduled (moves schedule), relearning}` — stored, never inferred. `StudyOutcomeReason {timeout}` (recall only, 20s limit `kRecallTurnLimit`). Session entity `StudySessionEntity{id, deckId, rootDeckId, schedulerGeneration, kind, currentMode, status, endReason?, cursor, cardLimit, direction?: StudySessionDirection, startedAt, endedAt?}`. `StudySessionStatus {inProgress, completed, abandoned, invalidated, failed}` paired with `StudySessionEndReason {userExit, interrupted, schedulerReset, schedulerChanged, staleGeneration, contentDeleted, persistenceError}` — legal pairs enforced by `isValidWith`. Direction: `StudyRecallDirection {koreanToMeaning, meaningToKorean, unknown}` per-turn face; `StudySessionDirection` locked per-session. Turn model `StudyTurnModel{item: StudyQueueItemEntity, card: StudyCardModel, progress: StudyStageProgressModel}`; `StudyCardModel{id, front, back, example?, hint?, pronunciation?, frontFolded, backFolded}`. Queue item status `{pending, completed}`. Lapse policy per mode (`StudyLapsePolicy {noAnswer, spacedRetry, completeAndEnrollNextRound, retainAndEnrollNextRound}`) governs whether a wrong answer keeps the card on screen (match) or re-queues it (self_assess). Mode-specific structures: `FillOutcome{isCorrect, comparisonVersion, hasUsedHint}`; `GuessQuestion{term, options: List<GuessOption>}` (5 options, exactly one correct, BR-121); `MatchBoard{terms: List<MatchTile>, meanings: List<MatchTile>}`; `RecallOutcome {remembered, forgotten-ish via timeout}` derived from `RecallPhase {countdownRunning, selfAssessment, submittingAssessment, ...}` (phase ≠ outcome, deliberately split). Refusals (`study_refusal_failure.dart`): `nothingDueToReview, nothingLeftToLearn, modeHasNoContent, modeNotSupportedByScheduler, staleGeneration, sessionNotOpen`. Summary: `StudySessionSummaryModel{kind, status, endReason?, finishedCards, answeredCards, wrongTurns, totalTurns}`; derived `hasCompleted`.

### Progress overview (UC-12)
`ProgressOverview{lastSevenDays: List<ProgressActivityDay>, currentStreakDays, hasLifetimeActivity, nextLocalMidnight}`; derived `today = lastSevenDays.last`, `isStreakHeldFromYesterday`. `ProgressActivityDay{localDate, totalCards, learningCards}`; derived `reviewingCards`, `isActive`.

### Progress by deck / drill-down (UC-13)
`DeckActivitySnapshot{scopeDeckId?, scopeName?, scopePath: List<ProgressPathSegment>, decks: List<DeckActivity>, scopeLast7Days: DeckActivityMetrics, scopeLast30Days: DeckActivityMetrics, nextDayBoundaryAt}`; `isTopLevel = scopeDeckId==null`. `DeckActivity{deckId, name, path, last7Days, last30Days}`. `DeckActivityMetrics{activeCardCount, activeDayCount, learningCardDayCount, reviewingCardDayCount}`; derived `cardDayCount, hasActivity`. `ProgressRange {last7Days(7), last30Days(30)}` — fixed windows, no free date picker (design decision recorded in comments, not a BR).

### Settings
`AppSettingsModel{cardLimit, newCardOrder: NewCardOrder (shared with Study), themeMode: AppThemeMode {system, light, dark}, language: AppLanguage {system, en, vi}}`. Actions: `save_language_use_case`, `save_theme_mode_use_case`, `save_study_defaults_use_case`, `reset_app_settings_use_case` (reset to defaults). NOTE product.md still calls Settings "placeholder"/scaffold, but AD-19 says both Progress and Settings have since graduated (M99.28) — see Conflicts.

### Reminder settings (UC-17)
`ReminderSettingsModel{isEnabled, time: ReminderTime{hour,minute}, lastDeliveredAt?}`. `ReminderCapability {supported, unsupported}` (platform: unsupported on Web/iOS). `ReminderPermission {granted, denied, notRequested}` — three values so "never asked" ≠ "refused" (re-prompting after OS denial is a dead end on Android). `ReminderOverviewModel{settings, capability}`; `isChangeable`. `ReminderSummaryModel{totalDueCount, leadDeckName, otherDeckCount}` (what the notification body says). `ReminderWorkloadModel{deckId, deckName, overdueCount, dueTodayCount, overdueDayCount}`. Failures (`reminder_failure.dart`): `platformUnavailable, permissionDenied, scheduleFailed, cancelFailed, settingsWriteFailed`. `ReminderTimeProblem {outOfRange}`.

## 3. Shared value types / enums

- `SchedulerType {eightBox, sm2, unknown}` — root-deck-only; `unknown` = forward-compat read tolerance, never written.
- `CardState {isNew, beginning, reviewing, mastered}` — display-only, derived, never stored.
- `DeckScheduleStatus {notDue, dueToday, overdue}` — derived from due count + overdue-day count at local midnight boundary.
- `NewCardOrder {created (default), random}` — shared between Study options and Settings.
- Name/text length limits: deck name ≤200 (`kDeckNameMaxLength`); card front ≤60, back ≤240, each optional detail (example/hint/pronunciation) ≤240; tag name ≤50 (`kTagNameMaxLength`), max 10 tags/card (`kMaxTagsPerCard`); study card limit 1-200, default 20.
- Locales: `en`, `vi`. Deck-tree depth ceiling: 10 (root = level 1).

## 4. Derived values used across areas

- `dueTodayCardCount = dueCardCount - overdueCardCount` (BR-162 partition).
- `scheduledCardCount = totalCardCount - newCardCount - dueCardCount` (the "resting" set).
- `learnedFraction`, `isFullyLearned` — progress bar math, 0 for empty deck (not div/0).
- `CardState` from `learnedAt`/`currentBox`/`intervalDays` — never a stored column.
- `DeckScheduleStatus`/`levelScheduleStatus` — single function (`deckScheduleStatusOf`) used at both single-deck and level-aggregate scope so they cannot disagree.
- Trash `daysLeft` — ceiling of remaining time, floored at 0, never shows 0 while still restorable.

## 5. Error / refusal catalogue

See per-area sections above for the full enum lists. Cross-cutting pattern: **conflict vs validation vs not-found** are three separate failure families per feature (never one generic "error" state); a screen distinguishes retryable failures (network/db write errors, ARB "couldn't load / please try again" copy) from structural refusals (a rule was actually broken, e.g. `deckHoldsDecks`, `schedulerLocked`, `nothingDueToReview`) which get specific, named copy rather than a generic error banner.

## 6. Sample-data scenarios

Per-entity edge cases a designer needs, with exact field names/limits so sample data doesn't invent fields:

- **DeckEntity/DeckSummary**: empty deck (`totalCardCount=0`, `contentType=unset`), a deck exactly at depth 10 (`maxTreeDepth`), root deck vs deep sub-deck (scheduler fields null on non-root), `learnedFraction` at 0%, 50%, 100%; `overdueDayCount` = 0/1/30+; deck name at 1 char, at 200 chars (max), Vietnamese diacritics (`"Từ vựng"`), Korean (`"단어"`), mixed scripts; `subDeckCount`/`totalCardCount` at 0 and at ~10,000 (large library).
- **CardEntity**: front at 1 char and at 60 (max); back at 1 and 240 (max); example/hint/pronunciation null vs at 240 max; `isFlagged` true/false; content in en/vi/ko (repo ships NotoSansKR — Korean front terms are the expected real content per templates and BR-08 comment "the Korean term").
- **CardStudyStateEntity**: `isNew` (`learnedAt=null`), `beginning`, `reviewing`, `mastered` for both `eight_box` (`currentBox` 1-8) and `sm2` (`intervalDays` crossing 8 and 128); `dueAt` null vs a future date vs overdue by 1/7/30+ days.
- **StudySessionSummaryModel**: `status` × every value (`inProgress, completed, abandoned, invalidated, failed`) paired only with its legal `endReason` per `isValidWith`.
- **TagCatalogEntry**: `cardCount=0` (orphan tag, candidate for deletion), tag name at 50 chars max, up to 10 tags shown on one card row.
- **CardImportPreview**: zero rows, all-ready, all-duplicate, all-invalid, a mixed batch; a row at exactly the front/back char limit; a large import (hundreds/thousands of rows).
- **TrashBatchEntity**: `deletedAt` today vs 29 days vs exactly 30 days (`daysLeft=0` boundary); deck batch vs card batch; a deck batch whose `originDeckId` is null (root-level).
- **ProgressOverview**: `currentStreakDays=0` vs a long streak; `hasLifetimeActivity=false` (brand-new install, empty state); 7-day and 30-day windows with zero and with dense activity.
- **DeckMoveTarget / TrashDeckCandidate**: eligible vs each rejection reason at least once, at varying `depth`.
- **Deep path**: a 10-level deck chain for breadcrumb/ancestor rendering (`ancestors: List<DeckPathSegment>`).
- **StudyCardModel in `guess` mode**: exactly the minimum 5 distinct meanings (BR-121) and a case with too few (mode unavailable, `modeHasNoContent`).
- **ReminderSettingsModel**: `isEnabled=false`; `capability=unsupported` (iOS/Web); `permission=notRequested/denied/granted`.

## 7. Docs vs code conflicts

- **CONFLICT — Settings placeholder status.** `docs/product.md:174-176` (Vietnamese) states "Settings vẫn chỉ là scaffold/placeholder... tùy chọn ứng dụng chưa có nghiệp vụ nào được chốt" (Settings is still only a scaffold/placeholder; no app-option business rules are settled). But `docs/architecture.md` AD-19 (`lib/…architecture.md:1205-1222` and its header table, `Updated by task M99.28`) states Settings graduated from placeholder in M99.28 and "không còn branch nào là placeholder" (no branch remains a placeholder). Code confirms a real `AppSettingsModel` with theme/language/study-default fields and five settings use cases exist (`lib/features/settings/domain/`). **product.md appears stale here** — this matches the task brief's own warning that product.md is "partly stale." DERIVED conclusion: Settings is a real, implemented feature; treat product.md's placeholder language as outdated.

## 8. Unknowns — needs product confirmation

- `DeckContentType` enum's exact member spelling (`unset`/`deck`/`card` assumed from BR-58/61/62 prose and ARB keys `deckDetailEmptyUnsetTitle`/`deckDetailEmptyDeckTitle`/`deckDetailEmptyCardTitle`, but the enum source file itself was not opened this pass) — UNKNOWN, needs the file `deck_content_type_model.dart` confirmed.
- `DeckListSort` full 5-value list: `manual, dateAdded, name` confirmed; remaining 2 values not read (file truncated in this pass) — UNKNOWN.
- Whether Library Search has a distinct deck-side empty-state string vs the card-side `cardSearchEmptyTitle` — UNKNOWN.
- `CardImportPhase`'s failure/error phase (list ended at `noCardsAdded` in the excerpt) — likely one more value for a hard import failure; not confirmed — UNKNOWN.
- Exact `AppLanguage`/`AppThemeMode` UI copy and whether Settings screen currently exposes reminder settings entry point directly or only via a route — UNKNOWN (route confirmed, UI entry not traced).

## 9. Coordinator reconciliation

Added by the coordinator after reading the model files directly; the handoff
files follow these corrections.

- **Unknowns resolved.** `DeckContentType` = `unset` · `card` · `deck` · `unknown`
  (read tolerance). `DeckListSort` = `manual` · `dateAdded` · `name` · `cardsDue` ·
  `progress` (`deck_list_view_state.dart`). `CardImportPhase` ends with
  `commitFailure`. Library search has its own no-results copy
  (`librarySearchNoResultsTitle/Message`).
- **Path semantics** — `DeckListSnapshot.ancestors`: decks above the listed
  parent, root first, parent excluded (`queries/deck.drift` ancestry CTE starts at
  the parent's parent; `deck_mapper.dart` sorts by distance). `DeckSearchHit.deckPath`
  excludes the deck (`deck_search_ranking_model.dart:98` builds from
  `parentDeckId`); `CardSearchHit.deckPath` includes the card's deck
  (`library_search_mapper.dart:67`). `TrashBatchEntity.originPath`: decks above
  the origin deck (`queries/trash.drift` `trashBatchRows`). `DeckActivity.path`
  at a deck level = scope path + scope (`progress_mapper.dart:137`).
- **`DeckSummary.subDeckCount`** counts direct sub-decks; **`learnedCardCount`**
  counts mastered cards.
- **`ReminderPermission`** is not part of `ReminderOverviewModel`; a refusal
  surfaces as `ReminderSetupRejection.permissionDenied`.
- **`InstallDeckTemplateUseCase`** takes `allowDuplicate` for the explicit second copy.
- **`CardStudyStateEntity` of a new card** carries its algorithm's seed values
  (box 1; or ease 2.5 / interval 0 / repetitions 0) with `learnedAt` null.
- **Settings conflict** is confirmed: `docs/product.md` is stale, AD-19 and code agree.
