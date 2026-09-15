# Database Findings

| | |
|---|---|
| **Status** | draft |
| **Purpose** | Research note behind the Claude Design handoff — data model and derived values as found at base commit de1e862c |
| **Scope** | Tables, columns, constraints, relationships, enums, derived/aggregate values, soft-delete/trash model, starter-template mechanism. Out of scope: current Flutter UI layout, widgets, theme, state-management mechanics |
| **Source of truth for** | — (derived research; docs/ and lib/ remain the sources) |
| **Depends on** | docs/data-model.md, docs/business-rules.md, docs/business-rules/study-mode.md |
| **Updated by task** | claude-design-handoff (no WBS id) |
| **Last updated** | 2026-09-16 |

## 1. Canonical schema sources

SOURCE-CONFIRMED, schema v13 (`lib/core/database/app_database.dart:49`):
- `lib/core/database/tables/decks.drift`, `cards.drift`, `study.drift`, `tags.drift`, `trash.drift`, `settings.drift`
- Named queries: `lib/core/database/queries/{deck,card,study,progress,reminder,search,settings,tag,trash}.drift`
- Migrations: `app_database_migrations.dart` (v1-v10 history, inline) + separate files for v5, v11, v12, v13

## 2. Entities / tables

### `decks`
| Column | Type/semantic | Null | Constraint | Class | Meaning |
|---|---|---|---|---|---|
| id | TEXT, client UUID | NOT NULL PK | — | STORED | decks.drift:17 |
| name | TEXT | NOT NULL | — | STORED, USER-RELEVANT | deck title |
| parent_deck_id | TEXT | NULL=root | FK decks.id ON DELETE CASCADE | STORED, USER-RELEVANT | tree parent; NULL marks a root deck |
| sibling_position | INTEGER default 0 | NOT NULL | — | STORED, USER-RELEVANT | manual order among same-parent decks (v13, BR-268); separate from created_at |
| root_deck_id | TEXT | NOT NULL | not a FK by design | STORED, INTERNAL | every deck carries its root's id (root carries its own); resolved once per row, never derived by walking parent (BR-56/57) |
| content_type | TEXT | NOT NULL | CHECK IN ('unset','card','deck') | STORED, USER-RELEVANT | what kind of child the deck currently holds; root is fixed 'deck' forever; sub-deck starts 'unset', auto-set by first child, auto-reset to 'unset' when last child removed (BR-60..66, BR-163) |
| owner_id | TEXT | NULL=local profile | — | STORED, INTERNAL | auth-ready, unused (no auth yet) |
| scheduler_type | TEXT | NULL | CHECK NULL OR IN ('eight_box','sm2') | STORED, USER-RELEVANT | **ROOT ONLY**; sub-decks leave NULL and resolve via root_deck_id (BR-06) |
| scheduler_version | INTEGER | NULL | — | STORED, INTERNAL | root only; algorithm version |
| scheduler_config | TEXT (JSON) | NULL | — | STORED, INTERNAL — **appears unused**: grep of `lib/` found no reader of this column outside the .drift declaration; candidate dead field |
| scheduler_generation | INTEGER | NULL | — | STORED, USER-RELEVANT | root only; starts at 1, +1 on every Reset (BR-40) |
| first_answered_at | DATETIME/UTC | NULL | — | STORED, DERIVED-ISH | NULL = scheduler choice still unlocked for this generation; set once by the first completed learning-chain card, only Reset clears it (AD-06) |
| study_config | TEXT (JSON) | NULL | — | STORED, USER-RELEVANT | root only; per-deck override of app-wide study options; NULL = use app_settings (BR-147) |
| source_template_id | TEXT | NULL=user-created | — | STORED, INTERNAL | which starter template this deck was copied from |
| source_template_version | INTEGER | NULL | — | STORED, INTERNAL | template version at copy time |
| delete_batch_id | TEXT | NULL=live | FK delete_batches.id ON DELETE CASCADE | STORED, USER-RELEVANT | soft-delete marker; non-NULL = tombstone belonging to that deletion (BR-256/258) |
| created_at, updated_at | DATETIME/UTC | NOT NULL | — | STORED, USER-RELEVANT | |

Indexes: `(parent_deck_id, sibling_position, id)`, `(root_deck_id, sibling_position, id)`, `(delete_batch_id)`.

### `cards`
| Column | Type | Null | Constraint | Class | Meaning |
|---|---|---|---|---|---|
| id | TEXT UUID | PK | — | STORED | |
| deck_id | TEXT | NOT NULL | FK decks.id CASCADE | STORED, USER-RELEVANT | only a deck with content_type='card' may hold cards (BR-63) |
| front, back | TEXT | NOT NULL | — | STORED, USER-RELEVANT | card content, limits BR-08 (60/240 chars, enforced above SQL) |
| front_folded, back_folded | TEXT default '' | NOT NULL | — | INTERNAL | trim+case-fold (full Unicode, done in Dart) of front/back, used only by search comparisons; never diacritic-stripped |
| is_flagged | INTEGER 0/1 (bool-as-int) | NOT NULL default 0 | CHECK IN (0,1) | STORED, USER-RELEVANT | user's own "come back to this" flag on content; survives Reset (BR-92) |
| example, hint, pronunciation | TEXT | NULL (never '') | — | STORED, USER-RELEVANT | optional supporting text; NULL="never filled", domain folds '' to NULL |
| delete_batch_id | TEXT | NULL=live | FK delete_batches.id CASCADE | STORED, USER-RELEVANT | soft delete, same contract as decks |
| created_at, updated_at | DATETIME/UTC | NOT NULL | — | STORED | |

Index: `(deck_id, created_at, id)` — measured 1193µs→102µs for keyset pagination; `(delete_batch_id)`.

### `card_study_states` (1–1 with cards; content vs schedule are deliberately separate tables — BR-10)
| Column | Type | Null | Class | Meaning |
|---|---|---|---|---|
| card_id | TEXT PK | FK cards.id CASCADE | STORED | |
| scheduler_type | TEXT | NOT NULL, CHECK IN ('eight_box','sm2') | STORED, INTERNAL | denormalized copy of root's value — turns an AD-09 invariant into a checkable query |
| scheduler_version, scheduler_generation | INTEGER | NOT NULL | STORED, INTERNAL | must equal the root's current generation (BR-49) or the row is stale |
| learned_at | DATETIME | NULL=not finished learning chain | STORED, USER-RELEVANT | **this column, not answer_count, is what "new" means** (BR-90); set once at chain completion, cleared only by Reset |
| due_at | DATETIME | NULL until learned | STORED, USER-RELEVANT | travels with learned_at — never a schedule without one and vice versa (BR-149) |
| last_answered_at | DATETIME | NULL | STORED, DERIVED-display | updated by both `scheduled` and `relearning` answers |
| answer_count | INTEGER default 0 | NOT NULL | STORED | counts `scheduled` reviews only (BR-20) |
| lapse_count | INTEGER default 0 | NOT NULL | STORED, USER-RELEVANT | |
| current_box | INTEGER | NULL, eight_box only | STORED, USER-RELEVANT | 1..8 |
| ease_factor | REAL | NULL, sm2 only | STORED, USER-RELEVANT | default 2.5, floor 1.3 |
| interval_days | INTEGER | NULL, sm2 only | STORED, USER-RELEVANT | |
| repetitions | INTEGER | NULL, sm2 only | STORED, INTERNAL | |

Index: `(due_at)` — described as the app's hottest query.

### `study_sessions`
Columns: id, deck_id (FK CASCADE), root_deck_id (root at session-open time), scheduler_generation (generation at open time, compared on every write — BR-45/84), status (CHECK: in_progress/completed/abandoned/invalidated/failed), end_reason (CHECK: NULL or user_exit/scheduler_reset/scheduler_changed/stale_generation/persistence_error/interrupted/content_deleted), session_kind (CHECK: learning/reviewing), current_mode (CHECK: browse/self_assess/match/guess/recall/fill), cursor (turns served, default 0), card_limit (fixed at session open, from effective option), started_at/ended_at, direction (CHECK: NULL or korean_to_meaning/meaning_to_korean/mixed — only set for a `reviewing` session of an `sm2` deck running `self_assess`).

The `status`×`end_reason` pairing is a documented invariant, not a CHECK constraint — deliberately, so the invariant test can construct a violation. Valid pairs (SOURCE-CONFIRMED docs/data-model.md:376-395 + study.drift comments):
- in_progress / NULL
- completed / NULL
- abandoned / user_exit (user quit) or interrupted (OS reclaimed the app before user acted)
- invalidated / scheduler_reset (Reset ran mid-session — generation bumped), scheduler_changed (scheduler swapped before first lock, generation unchanged — split from scheduler_reset at schema v12), stale_generation (session tried to write after its generation went stale), content_deleted (its deck/card went to Trash mid-session)
- failed / persistence_error

### `study_answers` (append-only; never updated or deleted, not even by Reset — BR-43)
Columns: id, card_id (FK CASCADE), session_id (FK), scheduler_type/generation AT THE TIME of the review (not looked up from deck), kind (CHECK: learning/scheduled/relearning — a stored fact, never derived by diffing previous/next state, BR-76), mode (CHECK: self_assess/match/guess/recall/fill — never `browse`, which writes no answer at all), outcome_reason (CHECK: NULL or 'timeout' — distinguishes an actual timeout from a blank submitted normally, `recall` only), comparison_version (fill only), used_hint (0/1, fill only, recorded but never affects grading — BR-136), `"action"` (quoted because ACTION is a SQL keyword; CHECK: forgotten/remembered/again/hard/good/easy — eight_box uses the first two, sm2 the other four), answered_at, next_due_at, previous_box/next_box (eight_box), previous/next_ease_factor + previous/next_interval_days (sm2), direction (CHECK: NULL or korean_to_meaning/meaning_to_korean — never `mixed`; a session can be mixed, a turn never is).

Indexes: `(card_id, answered_at)`, `(session_id)`. Noted as the fastest-growing table (one row per graded turn, Reset does not clean it).

### `study_queue_items` (one row per card per round per stage of a session)
PK `(session_id, mode, round, card_id)`. Columns: session_id (FK CASCADE), mode (same 6-value CHECK as current_mode), round (default 1; browse/self_assess stay at 1), card_id (FK CASCADE), position (order within round, immutable once built), status (CHECK: pending/completed), available_at (INTEGER — the session `cursor` value at which this card may be served again; a "forgotten" answer sets it to cursor+3, BR-26), answers_in_session (turns graded so far; 0 means next is `scheduled`, ceiling of 3 for BR-104), remaining_ms (recall only, 0..20000, resume support), is_revealed (0/1, recall only), direction (CHECK: NULL or the two non-mixed directions — decided once when the round was written, stable across comeback/resume).

Index serves ordering: `(session_id, mode, round, status, available_at, position)`.

### `tags`
id (TEXT UUID), name (as user typed it), name_folded (`lower(trim(name))`, full Unicode fold done in Dart — the column the uniqueness is actually enforced on, not `COLLATE NOCASE`, which is ASCII-only), owner_id (NULL=local), created_at. Unique index on `(COALESCE(owner_id,''), name_folded)` — the COALESCE is load-bearing because SQLite treats every NULL as distinct, so with owner_id NULL on every MVP row a plain two-column unique index enforced nothing.

### `card_tags` — pure many-to-many, PK `(card_id, tag_id)`, both FK CASCADE, plus reverse index `(tag_id, card_id)`.

### `delete_batches` (trash / soft-delete root)
id (UUID), item_type (CHECK: card/deck — the type of the item the user actually touched, not every row in the batch), root_item_id (not a FK — points at one of two tables), deleted_at (UTC, the only retention clock, 30 days — BR-264), owner_id. Index `(deleted_at, id)`.

### `app_settings` — singleton row, `id INTEGER PK CHECK (id=1)`
card_limit (default 20, per-session ceiling not per-day — BR-24), new_card_order (CHECK: created/random), theme_mode (CHECK: system/light/dark — the user's choice, not resolved brightness), language (CHECK: system/en/vi), reminder_enabled (0/1, default 0), reminder_minute_of_day (0..1439 LOCAL time, not UTC — deliberately, so the reminder doesn't drift with timezone), reminder_last_delivered_at (UTC, NULL until first send), updated_at.

## 3. Relationships (FK graph, in words)

- `decks.parent_deck_id → decks.id` CASCADE (tree; NULL=root)
- `decks.delete_batch_id → delete_batches.id` CASCADE
- `cards.deck_id → decks.id` CASCADE
- `cards.delete_batch_id → delete_batches.id` CASCADE
- `card_study_states.card_id → cards.id` CASCADE (1–1)
- `study_answers.card_id → cards.id` CASCADE; `study_answers.session_id → study_sessions.id` (no CASCADE stated in .drift for the session FK)
- `study_sessions.deck_id → decks.id` CASCADE
- `study_queue_items.session_id → study_sessions.id` CASCADE; `study_queue_items.card_id → cards.id` CASCADE
- `card_tags.card_id → cards.id` CASCADE; `card_tags.tag_id → tags.id` CASCADE
- `decks.root_deck_id` and `delete_batches.root_item_id` are deliberately NOT foreign keys (documented reasons: recursive resolution can't be a JOIN condition; two possible target tables)

Deleting a root deck cascades through the whole subtree, its cards, study states, answers, queue items and tag links (BR-03).

## 4. Enums and their stored values

| Column | Values |
|---|---|
| decks.content_type | unset, card, deck |
| decks.scheduler_type / card_study_states.scheduler_type / study_answers.scheduler_type | eight_box, sm2 |
| study_sessions.status | in_progress, completed, abandoned, invalidated, failed |
| study_sessions.end_reason | user_exit, scheduler_reset, scheduler_changed, stale_generation, persistence_error, interrupted, content_deleted |
| study_sessions.session_kind | learning, reviewing |
| study_sessions.current_mode / study_queue_items.mode | browse, self_assess, match, guess, recall, fill |
| study_answers.kind | learning, scheduled, relearning |
| study_answers.mode | self_assess, match, guess, recall, fill (never browse) |
| study_answers.outcome_reason | timeout (or NULL) |
| study_answers."action" | forgotten, remembered (eight_box) / again, hard, good, easy (sm2) |
| study_sessions.direction / study_queue_items.direction / study_answers.direction | korean_to_meaning, meaning_to_korean, (+ mixed, session-level only) |
| study_queue_items.status | pending, completed |
| delete_batches.item_type | card, deck |
| app_settings.new_card_order | created, random |
| app_settings.theme_mode | system, light, dark |
| app_settings.language | system, en, vi |

The action set differs by scheduler: eight_box's UI needs 2 buttons, sm2's needs 4 — DERIVED from the CHECK constraint and confirmed by `docs/business-rules.md`'s domain `supportedActions` concept.

## 5. Derived values catalogue

All formulas SOURCE-CONFIRMED against the query files cited.

- **New / learning-chain-unfinished count**: `card_study_states.learned_at IS NULL`. (study.drift:45, card.drift ~cardStateCountsByDeck)
- **Due count**: `learned_at IS NOT NULL AND due_at <= :now`. (study.drift:80, deck.drift rootDeckSummaries)
- **Overdue vs due-today split**: due set partitioned at local midnight: `due_at < :startOfToday` = overdue, else due today (deck.drift rootDeckSummaries, study.drift studyHomeRootWorkload, reminder.drift reminderWorkloadPerRootDeck). `:startOfToday`/`:dayStart` always a caller-supplied local-day boundary, never computed in SQL.
- **Overdue day count (badge)**: `oldestDueAt` (MIN due_at of the due set) minus today, in completed local days (deck_mapper.dart `overdueDaysOf`) — SQL supplies the instant, Dart does the calendar math.
- **Next-due tick**: `MIN(due_at) WHERE due_at > :now` — when a due-count badge would next change; drives when the UI re-measures rather than polling.
- **Mastered / reviewing / beginning tiers** (card.drift `cardStateCountsByDeck`, thresholds passed in as parameters from `card_state_model.dart`, not hardcoded in SQL):
  - beginning: learned, and (eight_box current_box < reviewingBox) or (sm2 interval_days < reviewingDays)
  - reviewing: learned, and box/interval between reviewing and mastered thresholds
  - mastered: learned, and (eight_box current_box ≥ masteredBox) or (sm2 interval_days ≥ masteredDays)
  - deck.drift's simpler `learnedCardCount` (deck-list badge) uses fixed thresholds: eight_box current_box=8, or sm2 interval_days≥128.
- **fillableCount**: due cards that also have a non-blank `example` (study.drift studyEntryCounts) — how many cards the `fill` study mode can actually offer.
- **distinctMeanings**: `COUNT(DISTINCT back_folded)` among due cards — what the `guess` mode needs ≥5 of.
- **Activity / streak (progress.drift)**: unit of counting is one **card-day** (one card, one local day), never a raw answer — six reviews of one card in an evening count as 1. `learningCards` on a card-day = "did any answer on this card-day have kind='learning'" (MAX as boolean-OR); the day is Learning if any of its answers were, remainder is Reviewing. 7-day and 30-day windows come from one statement with a boolean is_recent flag, so they can't describe two different snapshots.
- **Root-deck / per-branch activity rollup** (`rootDeckActivity`, `childDeckActivity`): activeCards, activeDays, learningCardDays, reviewingCardDays per root subtree and per direct child, both windows, plus a scope-wide total row — all from the same card-day CTE.
- **Search rank tiers** (search.drift, BR-250): 0=exact match, 1=prefix match, 2=contains match, 9=no match, taken as MIN across front/back/matching-tag; a hit ranked 9 is filtered out. Matching uses `instr()` on folded columns, never `LIKE` (avoids `%`/`_` wildcard collision) and never bare `lower()` (ASCII-only).
- **Reminder workload** (reminder.drift): per-root-deck overdue/due-today counts + oldest overdue instant, same "learned_at IS NOT NULL" definition of due, grouped through root_deck_id so a card is counted exactly once regardless of nesting depth.
- **Trash list counts**: `batchDeckCount`/`batchCardCount` count only rows carrying that batch id (what a Restore would bring back), not the live subtree size — a descendant already tombstoned under an older batch is excluded.
- **Purge eligibility**: `delete_batches.deleted_at <= now-30days` (BR-264).

## 6. Soft delete / trash / purge model

- One column drives it: `delete_batch_id` on `decks` and `cards`. NULL = live; non-NULL = tombstone belonging to that `delete_batches` row. No row is copied anywhere.
- `delete_batches` owns the identity of the deletion event and the single `deleted_at` timestamp retention (30 days) is measured from. `item_type` says whether the user's original action was on a card or a deck (the batch also carries deck-tree descendants of both kinds).
- Deleting a deck marks its whole active subtree (walked with a cycle-safe recursive `UNION`, `delete_batch_id IS NULL` on the recursive step so a pre-existing tombstone underneath isn't re-batched) plus all cards inside it, in one transaction.
- Restoring a batch is one `UPDATE ... SET delete_batch_id = NULL WHERE delete_batch_id = :batchId` per table — cheap because nothing was ever copied.
- Purge = `DELETE FROM delete_batches WHERE id = :batchId`; the FK cascade from `decks.delete_batch_id`/`cards.delete_batch_id` removes the tombstoned rows, and their own downstream cascades (study state, answers, queue items, tags) clean up the rest. A precondition query (`purgeBlockerCount`) checks BEFORE the delete that no still-active or differently-tombstoned row would be swept along by the ordinary `parent_deck_id` cascade, since that cascade "has never heard of a batch."
- Every ordinary read in the app filters `delete_batch_id IS NULL`; `trash.drift` is the one file allowlisted to read tombstones directly.
- A study session whose material gets trashed mid-session is invalidated with `end_reason='content_deleted'` (BR-259) — trash write and session invalidation are two different repositories cooperating, not one query.

## 7. Templates (starter decks)

**No `deck_templates` table exists in the Drift schema or migrations** — confirmed by grepping `tables/*.drift` (no match) and the app_database migration history. `docs/data-model.md` documents this correctly (§`deck_templates`, explicitly marked "not a runtime table at MVP — AD-07", with a `_sau_` / "later" row in the migration-order table for turning it into one if templates ever come from a server). No CONFLICT here.

Real mechanism:
- Templates are static JSON assets: `assets/templates/manifest.json` (lists template files + a `content_notice` stating the starter content is a **development/test fixture, not production content**, per BR-87) and `assets/templates/{eight_box_starter,sm2_starter}.json`.
- Each template JSON describes a whole deck tree (`template_id`, `version`, `locale`, `title`, `content_source`, `default_scheduler_type`, nested `children`/`cards`) — not a flat card list, because the copy must reconstruct `content_type` and `root_deck_id` correctly.
- Copying is done by `DeckTemplateDao` (`lib/features/deck/data/datasources/deck_template_dao.dart`) inserting rows directly into `decks`/`cards`/`card_study_states` inside one transaction.
- "Already installed" tracking uses the `decks.source_template_id` + `decks.source_template_version` columns already on the `decks` table — `countCopiesOf` and `installedTemplateKeys` query distinct pairs of those two columns; there is no separate installed-templates ledger. A user can deliberately install a second copy (BR-38); the app avoids auto-re-installing a template it already sees a copy of.

## 8. Internal metadata (never surfaced to the user, exists for correctness/perf)

- `decks.root_deck_id`, `card_study_states.scheduler_type/generation` (denormalized from root) — structural, not user-facing.
- `cards.front_folded`/`back_folded`, `tags.name_folded` — search/uniqueness machinery only.
- `study_answers.scheduler_type`/`scheduler_generation` — history bookkeeping (which rule-cycle a row belongs to).
- `decks.scheduler_config` — **STORED but appears unused** by any reader in `lib/` (grep found only the table declaration + the memox-api mirror). UNKNOWN whether this is planned or dead.
- `owner_id` on decks/tags/delete_batches — present for future auth, always NULL today (no auth yet, per AD-03/product decision).
- `decks.sibling_position` — internal ordering key but IS user-relevant (drives manual deck reordering, v13).

## 9. Docs vs code conflicts

None found for the core `.drift` schema vs `docs/data-model.md` — the document appears actively maintained and its own "Cột ... Tồn tại vì" mapping table, migration-order table (v1–v13) and column tables match the `.drift` files column-for-column, including the recent additions (`sibling_position`/v13, `scheduler_changed`/v12, Trash/v11). The `deck_templates` "table" some might expect from the name is explicitly documented as an asset-based, non-runtime concept (see §7) — this is consistent, not a conflict.

One documentation note worth flagging as historical residue rather than a live conflict: `docs/data-model.md` lines ~44-56 list five places in `lib/` still described as implementing a *pre-v5* definition of "new" (`answer_count == 0` instead of `learned_at IS NULL`). SOURCE-CONFIRMED current code (`study.drift`, `card.drift` `cardStateCountsByDeck`) already uses `learned_at IS NULL` throughout — that table in the doc is stale/leftover from the v5 migration write-up and does not reflect current queries. Not acted on; flagged for whoever next edits data-model.md.

## 10. memox-api schema differences (not canonical for the app; standalone Spring Boot/Postgres backend the Flutter app does not call)

- Structurally near-identical to the Drift schema (same tables, columns, enum CHECKs, indexes), translated to Postgres types: `VARCHAR(36)` UUIDs, `TIMESTAMPTZ` instead of epoch-millis DATETIME, `DOUBLE PRECISION` instead of REAL, `SMALLINT` instead of INTEGER-as-bool.
- V3 migration adds a column **not present in Drift at all**: `decks.sibling_scope_id` (defaults to parent_deck_id, `'00000000-...'` for roots) backing a `UNIQUE (sibling_scope_id, sibling_position)` constraint — the app-side schema has no equivalent uniqueness constraint on sibling position, it relies on application code to keep positions distinct.
- V4 adds several positivity CHECK constraints the Drift schema does not declare: `sibling_position >= 0`, `scheduler_version > 0`, `scheduler_generation > 0` (decks and card_study_states), `app_settings.card_limit > 0`.
- V5 makes the sibling-position uniqueness constraint `DEFERRABLE INITIALLY DEFERRED` to allow a multi-row reorder transaction to pass through a transiently-conflicting state — a concern that doesn't arise in SQLite/Drift the same way since the mobile app's own reorder logic is presumably sequenced differently (not verified — UNKNOWN whether the Drift reorder path has an analogous transient-conflict window).
- No card-level backend differences found beyond type mapping in the portion reviewed (V1-V5).

## 11. Unknowns

- Whether `decks.scheduler_config` (JSON override of per-algorithm parameters) is planned for a future UI or is dead schema — UNKNOWN, needs product confirmation.
- Whether the memox-api `sibling_scope_id`/uniqueness-constraint approach reflects an intended future tightening of the mobile schema, or is backend-specific scaffolding with no mobile equivalent planned — UNKNOWN.
- Exact wording/UX of "already installed" template messaging (BR-38 allows a deliberate second copy) — DERIVED only from the DAO's counting logic, not from a UI spec read in this pass.

## 12. Coordinator reconciliation

Added by the coordinator after cross-checking this note against source; the
handoff files follow these corrections.

- **Conflicts this note missed.** `decks.drift:59-60` still says `first_answered_at`
  NULL means "no `scheduled` review", and the state table in
  `docs/business-rules.md` ("Deck — trạng thái khoá scheduler") says the lock
  comes from the first `scheduled` turn. Current BR-13 and code
  (`study_lifecycle_repository_impl.dart:123` writes `firstAnsweredAt: learnedAt`;
  `queries/study.drift:349`) lock at the **first card that finishes the
  learning chain**. The comment and the state table are stale.
- `queries/card.drift:36` says "there is still no card search (S1, deferred)";
  in-deck search exists (`card_list_query_mapper.dart:96` — `instr` on
  `front_folded` / `back_folded`). Stale comment.
- BR-80 lists five `end_reason` values; schema and `StudySessionEndReason` have
  seven (`scheduler_changed`, `content_deleted` added later).
- **Initial study state of a new card** (`card_study_state_seed_mapper.dart:9-12`):
  `eight_box` → `current_box = 1`; `sm2` → `ease_factor = 2.5`,
  `interval_days = 0`, `repetitions = 0`; `learned_at` / `due_at` NULL.
- `subDeckCount` counts **direct** active sub-decks (`queries/deck.drift:166`).
- `learnedCardCount` on deck summaries counts **mastered** cards
  (`queries/deck.drift:154-160`), not `learned_at IS NOT NULL`.
- `study_answers.direction` is stored but not exposed by the history read model
  (`CardHistoryEventModel` has no direction field).
