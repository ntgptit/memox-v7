-- =============================================================================
-- MemoX — persistent schema, as documentation
-- =============================================================================
--
-- Status:            draft
-- Purpose:           Handoff for Claude Design — what MemoX stores on the device
-- Scope:             Local SQLite schema v13 (Drift) at base commit de1e862c,
--                    transcribed from lib/core/database/tables/*.drift.
--                    Documentation only: do NOT run as a migration.
-- Source of truth:   — (derived; the .drift files and docs/data-model.md win)
-- Last updated:      2026-09-16
--
-- How to read the comments
--   USER-RELEVANT  a value a person could meaningfully see or act on
--   DERIVED        not a column — computed at read time (listed where relevant)
--   INTERNAL       integrity, search, queue or future-proofing metadata;
--                  not normally shown to a user
--
-- Types
--   TEXT ids       client-generated UUID strings
--   DATETIME       an instant, always UTC. Day logic (due, overdue, streak)
--                  converts to the LOCAL day when read.
--   INTEGER 0/1    boolean
--
-- Deletion model
--   Decks and cards are never hard-deleted by a user action. Deleting sets
--   delete_batch_id (a Trash entry). Every normal read excludes rows where
--   delete_batch_id IS NOT NULL. Permanent deletion removes the batch row and
--   the ON DELETE CASCADE chain removes everything that hangs off it.
--
-- Not a table
--   Starter deck templates are JSON assets bundled with the app, not rows.
--   A copied deck remembers its template in decks.source_template_*.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- delete_batches — one row per deletion the user performed (Trash entry)
-- -----------------------------------------------------------------------------
CREATE TABLE delete_batches (
    id              TEXT     NOT NULL PRIMARY KEY,           -- INTERNAL
    -- USER-RELEVANT: what the user deleted. A deck batch also carries the
    -- deck's descendant decks and cards.
    item_type       TEXT     NOT NULL CHECK (item_type IN ('card', 'deck')),
    -- INTERNAL: id of the card or deck the user deleted. Deliberately not a FK
    -- (it points at one of two tables).
    root_item_id    TEXT     NOT NULL,
    -- USER-RELEVANT: retention (30 x 24 h) is measured from here.
    -- DERIVED: expires_at = deleted_at + 30 days; days_left.
    deleted_at      DATETIME NOT NULL,
    owner_id        TEXT     NULL                            -- INTERNAL: always NULL (no accounts)
);

-- Trash lists newest first; auto-purge sweeps oldest first.
CREATE INDEX idx_delete_batches_deleted ON delete_batches (deleted_at, id);


-- -----------------------------------------------------------------------------
-- decks — the deck tree (max depth 10, root = level 1)
-- -----------------------------------------------------------------------------
CREATE TABLE decks (
    id                       TEXT     NOT NULL PRIMARY KEY,  -- INTERNAL
    name                     TEXT     NOT NULL,              -- USER-RELEVANT: 1..200 chars after trim
    -- USER-RELEVANT: NULL marks a root deck.
    parent_deck_id           TEXT     NULL REFERENCES decks (id) ON DELETE CASCADE,
    -- USER-RELEVANT: manual order among siblings with the same parent.
    sibling_position         INTEGER  NOT NULL DEFAULT 0,
    -- INTERNAL: the root of this deck's tree (a root stores its own id).
    -- Deliberately not a FK; rewritten for a whole subtree when it moves.
    root_deck_id             TEXT     NOT NULL,
    -- USER-RELEVANT: what the deck holds. Root = 'deck' forever. A sub-deck
    -- starts 'unset'; its first child sets 'card' or 'deck'; it returns to
    -- 'unset' when its last active child leaves. Maintained by the system only.
    content_type             TEXT     NOT NULL CHECK (content_type IN ('unset', 'card', 'deck')),
    owner_id                 TEXT     NULL,                  -- INTERNAL: always NULL (no accounts)

    -- Review algorithm: ROOT ONLY. Sub-decks leave all four NULL and use their
    -- root's values.
    scheduler_type           TEXT     NULL
        CHECK (scheduler_type IS NULL OR scheduler_type IN ('eight_box', 'sm2')),  -- USER-RELEVANT
    scheduler_version        INTEGER  NULL,                  -- INTERNAL
    scheduler_config         TEXT     NULL,                  -- INTERNAL: JSON; no reader exists today
    -- USER-RELEVANT: starts at 1, +1 on every "Reset learning progress".
    scheduler_generation     INTEGER  NULL,
    -- INTERNAL: NULL = algorithm unlocked. Set when the first card of the
    -- current generation finishes learning; cleared only by reset.
    -- DERIVED: is_locked = first_answered_at IS NOT NULL.
    first_answered_at        DATETIME NULL,
    -- USER-RELEVANT: ROOT ONLY. JSON override of study options
    -- ({card limit, new card order}); NULL = follow app_settings.
    study_config             TEXT     NULL,

    -- INTERNAL: set when the deck was copied from a starter template;
    -- used only to detect "already added".
    source_template_id       TEXT     NULL,
    source_template_version  INTEGER  NULL,

    -- USER-RELEVANT (indirectly): NULL = live; otherwise the Trash entry it
    -- belongs to.
    delete_batch_id          TEXT     NULL REFERENCES delete_batches (id) ON DELETE CASCADE,

    created_at               DATETIME NOT NULL,              -- USER-RELEVANT: "date added" sort
    updated_at               DATETIME NOT NULL               -- USER-RELEVANT
);

CREATE INDEX idx_decks_parent_position ON decks (parent_deck_id, sibling_position, id);
CREATE INDEX idx_decks_root_position   ON decks (root_deck_id, sibling_position, id);
CREATE INDEX idx_decks_delete_batch    ON decks (delete_batch_id);

-- DERIVED per deck (never stored), always over the deck's whole active subtree:
--   total cards, new cards, due cards (= overdue + due today), overdue cards,
--   overdue day count, mastered cards ("learnedCardCount" in the read model),
--   sub-deck count, schedule status (notDue | dueToday | overdue),
--   next due instant.


-- -----------------------------------------------------------------------------
-- cards — card content. No schedule columns: content survives every reset.
-- -----------------------------------------------------------------------------
CREATE TABLE cards (
    id               TEXT     NOT NULL PRIMARY KEY,          -- INTERNAL
    -- USER-RELEVANT: only a deck whose content_type is 'card' holds cards.
    deck_id          TEXT     NOT NULL REFERENCES decks (id) ON DELETE CASCADE,
    front            TEXT     NOT NULL,                      -- USER-RELEVANT: the term, 1..60 chars after trim
    back             TEXT     NOT NULL,                      -- USER-RELEVANT: the meaning, 1..240 chars after trim
    -- INTERNAL: trim + Unicode lower-case of front/back. Used for search,
    -- import duplicate detection and fill grading. Accents are kept.
    front_folded     TEXT     NOT NULL DEFAULT '',
    back_folded      TEXT     NOT NULL DEFAULT '',
    -- USER-RELEVANT: the user's own mark. Survives edit and reset. The system
    -- may turn it on (self_assess repeat cap) but never off.
    is_flagged       INTEGER  NOT NULL DEFAULT 0 CHECK (is_flagged IN (0, 1)),
    -- USER-RELEVANT: optional, <=240 chars each. NULL, never empty string.
    example          TEXT     NULL,
    hint             TEXT     NULL,
    pronunciation    TEXT     NULL,
    delete_batch_id  TEXT     NULL REFERENCES delete_batches (id) ON DELETE CASCADE,  -- NULL = live
    created_at       DATETIME NOT NULL,                      -- USER-RELEVANT: "newest" sort, export order
    updated_at       DATETIME NOT NULL
);

CREATE INDEX idx_cards_deck_created  ON cards (deck_id, created_at, id);
CREATE INDEX idx_cards_delete_batch  ON cards (delete_batch_id);


-- -----------------------------------------------------------------------------
-- card_study_states — the schedule of one card (1–1 with cards)
-- Created with the card; recreated by reset and by an unlocked algorithm change.
-- -----------------------------------------------------------------------------
CREATE TABLE card_study_states (
    card_id               TEXT     NOT NULL PRIMARY KEY REFERENCES cards (id) ON DELETE CASCADE,
    -- INTERNAL: copied from the root deck so integrity checks need no join.
    scheduler_type        TEXT     NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
    scheduler_version     INTEGER  NOT NULL,                 -- INTERNAL
    scheduler_generation  INTEGER  NOT NULL,                 -- INTERNAL: must equal the root's generation
    -- USER-RELEVANT: NULL = the card has not finished its learning sequence
    -- ("new"). Set once when it finishes; back to NULL only on reset.
    learned_at            DATETIME NULL,
    -- USER-RELEVANT: NULL exactly when learned_at is NULL. Lands on local
    -- midnight, stored as UTC.
    due_at                DATETIME NULL,
    last_answered_at      DATETIME NULL,                     -- USER-RELEVANT: scheduled and relearning answers
    answer_count          INTEGER  NOT NULL DEFAULT 0,       -- USER-RELEVANT: counts 'scheduled' answers only
    lapse_count           INTEGER  NOT NULL DEFAULT 0,       -- USER-RELEVANT
    -- eight_box only (NULL otherwise). USER-RELEVANT: 1..8
    current_box           INTEGER  NULL,
    -- sm2 only (NULL otherwise). USER-RELEVANT: ease >= 1.3; interval in days
    ease_factor           REAL     NULL,
    interval_days         INTEGER  NULL,
    repetitions           INTEGER  NULL
);

CREATE INDEX idx_card_study_states_due ON card_study_states (due_at);

-- DERIVED per card (never stored):
--   display state  new       : learned_at IS NULL
--                  beginning : eight_box box 1-3   | sm2 interval < 8
--                  reviewing : eight_box box 4-7   | sm2 interval 8..127
--                  mastered  : eight_box box 8     | sm2 interval >= 128
--   due            learned_at IS NOT NULL AND due_at <= now
--   overdue        due AND due_at < start of local today
--   scheduled      learned_at IS NOT NULL AND due_at > now


-- -----------------------------------------------------------------------------
-- tags / card_tags — library-wide labels, many-to-many with cards
-- -----------------------------------------------------------------------------
CREATE TABLE tags (
    id           TEXT     NOT NULL PRIMARY KEY,              -- INTERNAL
    name         TEXT     NOT NULL,                          -- USER-RELEVANT: as typed, 1..50 chars
    name_folded  TEXT     NOT NULL,                          -- INTERNAL: trim + Unicode lower-case; uniqueness key
    owner_id     TEXT     NULL,                              -- INTERNAL: always NULL (no accounts)
    created_at   DATETIME NOT NULL
);

-- One tag per case-folded name per owner. COALESCE is required because every
-- owner_id is NULL today and SQLite treats NULLs as distinct.
CREATE UNIQUE INDEX idx_tags_owner_folded ON tags (COALESCE(owner_id, ''), name_folded);

CREATE TABLE card_tags (
    card_id  TEXT NOT NULL REFERENCES cards (id) ON DELETE CASCADE,
    tag_id   TEXT NOT NULL REFERENCES tags (id)  ON DELETE CASCADE,
    PRIMARY KEY (card_id, tag_id)
);

CREATE INDEX idx_card_tags_tag ON card_tags (tag_id, card_id);

-- Application rule (not a constraint): at most 10 tags per card.
-- DERIVED per tag: active card count (excludes cards in Trash),
--                  linked card count (includes cards in Trash).


-- -----------------------------------------------------------------------------
-- study_sessions — one study session
-- -----------------------------------------------------------------------------
CREATE TABLE study_sessions (
    id                    TEXT     NOT NULL PRIMARY KEY,     -- INTERNAL
    -- USER-RELEVANT: the deck studied — a root or a sub-deck.
    deck_id               TEXT     NOT NULL REFERENCES decks (id) ON DELETE CASCADE,
    root_deck_id          TEXT     NOT NULL,                 -- INTERNAL: root at open time
    scheduler_generation  INTEGER  NOT NULL,                 -- INTERNAL: writes are refused when stale
    -- USER-RELEVANT
    status                TEXT     NOT NULL CHECK (
        status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')
    ),
    -- USER-RELEVANT. Valid pairs with status (enforced by the application):
    --   in_progress, completed -> NULL
    --   abandoned              -> user_exit | interrupted
    --   invalidated            -> scheduler_reset | scheduler_changed |
    --                             stale_generation | content_deleted
    --   failed                 -> persistence_error
    end_reason            TEXT     NULL CHECK (
        end_reason IS NULL OR end_reason IN (
            'user_exit', 'scheduler_reset', 'scheduler_changed',
            'stale_generation', 'persistence_error', 'interrupted',
            'content_deleted'
        )
    ),
    -- USER-RELEVANT: learning = not-yet-learned cards through the stage
    -- sequence; reviewing = learned and due cards in one chosen mode.
    session_kind          TEXT     NOT NULL CHECK (session_kind IN ('learning', 'reviewing')),
    -- USER-RELEVANT: the stage running now.
    current_mode          TEXT     NOT NULL CHECK (
        current_mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')
    ),
    cursor                INTEGER  NOT NULL DEFAULT 0,       -- INTERNAL: turns served
    card_limit            INTEGER  NOT NULL,                 -- USER-RELEVANT: fixed when the session opened
    started_at            DATETIME NOT NULL,                 -- USER-RELEVANT: "today's session" for resume
    ended_at              DATETIME NULL,
    -- USER-RELEVANT: question direction. Only for a reviewing session of an
    -- sm2 deck in self_assess; NULL otherwise.
    direction             TEXT     NULL CHECK (
        direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean', 'mixed')
    )
);


-- -----------------------------------------------------------------------------
-- study_answers — review history. APPEND-ONLY: never updated, never deleted,
-- not even by reset. Removed only by cascade when its card is purged.
-- -----------------------------------------------------------------------------
CREATE TABLE study_answers (
    id                      TEXT     NOT NULL PRIMARY KEY,   -- INTERNAL
    card_id                 TEXT     NOT NULL REFERENCES cards (id) ON DELETE CASCADE,
    session_id              TEXT     NOT NULL REFERENCES study_sessions (id),
    -- USER-RELEVANT: the algorithm and generation AT THE TIME of the answer.
    scheduler_type          TEXT     NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
    scheduler_generation    INTEGER  NOT NULL,
    -- USER-RELEVANT, stored (never inferred):
    --   learning   : part of the learning sequence; history only, no schedule change
    --   scheduled  : first review answer of a card in a session; moves the schedule
    --   relearning : a repeat after a wrong answer; no schedule change
    kind                    TEXT     NOT NULL CHECK (kind IN ('learning', 'scheduled', 'relearning')),
    -- USER-RELEVANT: never 'browse' (browse writes no answer).
    mode                    TEXT     NOT NULL CHECK (mode IN ('self_assess', 'match', 'guess', 'recall', 'fill')),
    -- USER-RELEVANT: 'timeout' only for a recall turn that ran out of time.
    outcome_reason          TEXT     NULL CHECK (outcome_reason IS NULL OR outcome_reason IN ('timeout')),
    comparison_version      INTEGER  NULL,                   -- INTERNAL: fill grading policy version
    used_hint               INTEGER  NULL CHECK (used_hint IS NULL OR used_hint IN (0, 1)),  -- USER-RELEVANT: fill only
    -- USER-RELEVANT: eight_box -> forgotten | remembered;
    --                sm2       -> again | hard | good | easy
    "action"                TEXT     NOT NULL CHECK (
        "action" IN ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')
    ),
    answered_at             DATETIME NOT NULL,               -- USER-RELEVANT
    next_due_at             DATETIME NULL,                   -- USER-RELEVANT: when the schedule moved
    -- USER-RELEVANT: before -> after, only for the row's own algorithm.
    previous_box            INTEGER  NULL,
    next_box                INTEGER  NULL,
    previous_ease_factor    REAL     NULL,
    next_ease_factor        REAL     NULL,
    previous_interval_days  INTEGER  NULL,
    next_interval_days      INTEGER  NULL,
    -- INTERNAL today (stored, not exposed by the history read model):
    -- the direction this turn was asked in; never 'mixed'.
    direction               TEXT     NULL CHECK (
        direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')
    )
);

CREATE INDEX idx_study_answers_card    ON study_answers (card_id, answered_at);
CREATE INDEX idx_study_answers_session ON study_answers (session_id);

-- DERIVED from study_answers (never stored):
--   card-day        distinct (card, local day) with at least one answer
--   learning day    a card-day with at least one kind = 'learning'
--   reviewing day   every other card-day
--   streak, active cards, active days, 7/30-day windows


-- -----------------------------------------------------------------------------
-- study_queue_items — INTERNAL: the persisted queue of a session.
-- One row per card per stage per round. Lets a session survive the OS killing
-- the app and resume exactly.
-- -----------------------------------------------------------------------------
CREATE TABLE study_queue_items (
    session_id          TEXT    NOT NULL REFERENCES study_sessions (id) ON DELETE CASCADE,
    mode                TEXT    NOT NULL CHECK (
        mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')
    ),
    round               INTEGER NOT NULL DEFAULT 1,  -- rounds for match/guess/recall/fill
    card_id             TEXT    NOT NULL REFERENCES cards (id) ON DELETE CASCADE,
    position            INTEGER NOT NULL,            -- order inside the round, fixed once built
    status              TEXT    NOT NULL CHECK (status IN ('pending', 'completed')),
    available_at        INTEGER NOT NULL DEFAULT 0,  -- self_assess: a forgotten card returns after 3 others
    answers_in_session  INTEGER NOT NULL DEFAULT 0,  -- self_assess repeat cap is 3
    remaining_ms        INTEGER NULL,                -- recall only: 0..20000
    is_revealed         INTEGER NOT NULL DEFAULT 0,  -- recall only
    direction           TEXT    NULL CHECK (         -- the direction decided for this card
        direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')
    ),
    PRIMARY KEY (session_id, mode, round, card_id)
);

CREATE INDEX idx_study_queue_serving
    ON study_queue_items (session_id, mode, round, status, available_at, position);


-- -----------------------------------------------------------------------------
-- app_settings — app-wide options. Exactly one row (id = 1).
-- -----------------------------------------------------------------------------
CREATE TABLE app_settings (
    id                          INTEGER  NOT NULL PRIMARY KEY CHECK (id = 1),
    card_limit                  INTEGER  NOT NULL DEFAULT 20,         -- USER-RELEVANT: 1..200, per session
    new_card_order              TEXT     NOT NULL DEFAULT 'created'
        CHECK (new_card_order IN ('created', 'random')),              -- USER-RELEVANT
    theme_mode                  TEXT     NOT NULL DEFAULT 'system'
        CHECK (theme_mode IN ('system', 'light', 'dark')),            -- USER-RELEVANT: the choice, not the resolved brightness
    language                    TEXT     NOT NULL DEFAULT 'system'
        CHECK (language IN ('system', 'en', 'vi')),                   -- USER-RELEVANT
    reminder_enabled            INTEGER  NOT NULL DEFAULT 0
        CHECK (reminder_enabled IN (0, 1)),                           -- USER-RELEVANT: off by default
    -- USER-RELEVANT: LOCAL minute of day, deliberately not UTC. 1200 = 20:00.
    reminder_minute_of_day      INTEGER  NOT NULL DEFAULT 1200
        CHECK (reminder_minute_of_day BETWEEN 0 AND 1439),
    reminder_last_delivered_at  DATETIME NULL,                        -- INTERNAL: one notification per local day
    updated_at                  DATETIME NOT NULL
);

-- Not persisted: notification permission and platform capability are read from
-- the operating system each time.


-- =============================================================================
-- Relationships (summary)
--   decks.parent_deck_id         -> decks.id            CASCADE   (tree)
--   decks.delete_batch_id        -> delete_batches.id   CASCADE
--   cards.deck_id                -> decks.id            CASCADE
--   cards.delete_batch_id        -> delete_batches.id   CASCADE
--   card_study_states.card_id    -> cards.id            CASCADE   (1-1)
--   card_tags.card_id / tag_id   -> cards.id / tags.id  CASCADE   (M-N)
--   study_sessions.deck_id       -> decks.id            CASCADE
--   study_answers.card_id        -> cards.id            CASCADE
--   study_answers.session_id     -> study_sessions.id
--   study_queue_items.session_id -> study_sessions.id   CASCADE
--   study_queue_items.card_id    -> cards.id            CASCADE
--   decks.root_deck_id, delete_batches.root_item_id: references by design, not FKs
--
-- Key invariants (checked by the application and its tests)
--   - A root deck holds no cards; a deck never holds cards and sub-decks at once.
--   - Every deck's root_deck_id is its real root; the tree has no cycles; depth <= 10.
--   - Only root decks carry scheduler_* and study_config.
--   - Every card schedule in a tree shares the root's algorithm and generation.
--   - learned_at and due_at are NULL together.
--   - status / end_reason follow the pairs listed on study_sessions.
--
-- Standalone backend (memox-api, not used by the app): PostgreSQL mirror of this
-- schema with the same tables and CHECKs, plus positivity checks and a
-- uniqueness constraint on sibling order. Not relevant to design.
-- =============================================================================
