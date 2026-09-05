CREATE TABLE delete_batches (
    id VARCHAR(36) PRIMARY KEY,
    item_type VARCHAR(10) NOT NULL CHECK (item_type IN ('card', 'deck')),
    root_item_id VARCHAR(36) NOT NULL,
    deleted_at TIMESTAMP WITH TIME ZONE NOT NULL,
    owner_id VARCHAR(36) NULL
);

CREATE INDEX idx_delete_batches_deleted ON delete_batches (deleted_at, id);

CREATE TABLE decks (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    parent_deck_id VARCHAR(36) NULL REFERENCES decks (id) ON DELETE CASCADE,
    sibling_position INTEGER NOT NULL DEFAULT 0,
    root_deck_id VARCHAR(36) NOT NULL,
    content_type VARCHAR(10) NOT NULL CHECK (content_type IN ('unset', 'card', 'deck')),
    owner_id VARCHAR(36) NULL,
    scheduler_type VARCHAR(10) NULL CHECK (scheduler_type IS NULL OR scheduler_type IN ('eight_box', 'sm2')),
    scheduler_version INTEGER NULL,
    scheduler_config TEXT NULL,
    scheduler_generation INTEGER NULL,
    first_answered_at TIMESTAMP WITH TIME ZONE NULL,
    study_config TEXT NULL,
    source_template_id VARCHAR(36) NULL,
    source_template_version INTEGER NULL,
    delete_batch_id VARCHAR(36) NULL REFERENCES delete_batches (id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_decks_parent_position ON decks (parent_deck_id, sibling_position, id);
CREATE INDEX idx_decks_root_position ON decks (root_deck_id, sibling_position, id);
CREATE INDEX idx_decks_delete_batch ON decks (delete_batch_id);

CREATE TABLE cards (
    id VARCHAR(36) PRIMARY KEY,
    deck_id VARCHAR(36) NOT NULL REFERENCES decks (id) ON DELETE CASCADE,
    front TEXT NOT NULL,
    back TEXT NOT NULL,
    front_folded TEXT NOT NULL DEFAULT '',
    back_folded TEXT NOT NULL DEFAULT '',
    is_flagged SMALLINT NOT NULL DEFAULT 0 CHECK (is_flagged IN (0, 1)),
    example TEXT NULL,
    hint TEXT NULL,
    pronunciation TEXT NULL,
    delete_batch_id VARCHAR(36) NULL REFERENCES delete_batches (id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_cards_deck_created ON cards (deck_id, created_at, id);
CREATE INDEX idx_cards_delete_batch ON cards (delete_batch_id);

CREATE TABLE card_study_states (
    card_id VARCHAR(36) PRIMARY KEY REFERENCES cards (id) ON DELETE CASCADE,
    scheduler_type VARCHAR(10) NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
    scheduler_version INTEGER NOT NULL,
    scheduler_generation INTEGER NOT NULL,
    learned_at TIMESTAMP WITH TIME ZONE NULL,
    due_at TIMESTAMP WITH TIME ZONE NULL,
    last_answered_at TIMESTAMP WITH TIME ZONE NULL,
    answer_count INTEGER NOT NULL DEFAULT 0,
    lapse_count INTEGER NOT NULL DEFAULT 0,
    current_box INTEGER NULL,
    ease_factor DOUBLE PRECISION NULL,
    interval_days INTEGER NULL,
    repetitions INTEGER NULL
);

CREATE INDEX idx_card_study_states_due ON card_study_states (due_at);

CREATE TABLE tags (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    name_folded VARCHAR(200) NOT NULL,
    owner_id VARCHAR(36) NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE UNIQUE INDEX idx_tags_owner_folded ON tags (owner_id, name_folded);

CREATE TABLE card_tags (
    card_id VARCHAR(36) NOT NULL REFERENCES cards (id) ON DELETE CASCADE,
    tag_id VARCHAR(36) NOT NULL REFERENCES tags (id) ON DELETE CASCADE,
    PRIMARY KEY (card_id, tag_id)
);

CREATE INDEX idx_card_tags_tag ON card_tags (tag_id, card_id);

CREATE TABLE app_settings (
    id SMALLINT PRIMARY KEY CHECK (id = 1),
    card_limit INTEGER NOT NULL DEFAULT 20,
    new_card_order VARCHAR(10) NOT NULL DEFAULT 'created' CHECK (new_card_order IN ('created', 'random')),
    theme_mode VARCHAR(10) NOT NULL DEFAULT 'system' CHECK (theme_mode IN ('system', 'light', 'dark')),
    language VARCHAR(10) NOT NULL DEFAULT 'system' CHECK (language IN ('system', 'en', 'vi')),
    reminder_enabled SMALLINT NOT NULL DEFAULT 0 CHECK (reminder_enabled IN (0, 1)),
    reminder_minute_of_day INTEGER NOT NULL DEFAULT 1200 CHECK (reminder_minute_of_day BETWEEN 0 AND 1439),
    reminder_last_delivered_at TIMESTAMP WITH TIME ZONE NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

INSERT INTO app_settings (id, updated_at) VALUES (1, CURRENT_TIMESTAMP);

CREATE TABLE study_sessions (
    id VARCHAR(36) PRIMARY KEY,
    deck_id VARCHAR(36) NOT NULL REFERENCES decks (id) ON DELETE CASCADE,
    root_deck_id VARCHAR(36) NOT NULL,
    scheduler_generation INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('in_progress', 'completed', 'abandoned', 'invalidated', 'failed')),
    end_reason VARCHAR(20) NULL CHECK (end_reason IS NULL OR end_reason IN ('user_exit', 'scheduler_reset', 'scheduler_changed', 'stale_generation', 'persistence_error', 'interrupted', 'content_deleted')),
    session_kind VARCHAR(10) NOT NULL CHECK (session_kind IN ('learning', 'reviewing')),
    current_mode VARCHAR(20) NOT NULL CHECK (current_mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
    cursor INTEGER NOT NULL DEFAULT 0,
    card_limit INTEGER NOT NULL,
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at TIMESTAMP WITH TIME ZONE NULL,
    direction VARCHAR(30) NULL CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean', 'mixed'))
);

CREATE TABLE study_answers (
    id VARCHAR(36) PRIMARY KEY,
    card_id VARCHAR(36) NOT NULL REFERENCES cards (id) ON DELETE CASCADE,
    session_id VARCHAR(36) NOT NULL REFERENCES study_sessions (id),
    scheduler_type VARCHAR(10) NOT NULL CHECK (scheduler_type IN ('eight_box', 'sm2')),
    scheduler_generation INTEGER NOT NULL,
    kind VARCHAR(20) NOT NULL CHECK (kind IN ('learning', 'scheduled', 'relearning')),
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('self_assess', 'match', 'guess', 'recall', 'fill')),
    outcome_reason VARCHAR(10) NULL CHECK (outcome_reason IS NULL OR outcome_reason IN ('timeout')),
    comparison_version INTEGER NULL,
    used_hint SMALLINT NULL CHECK (used_hint IS NULL OR used_hint IN (0, 1)),
    "action" VARCHAR(20) NOT NULL CHECK ("action" IN ('forgotten', 'remembered', 'again', 'hard', 'good', 'easy')),
    answered_at TIMESTAMP WITH TIME ZONE NOT NULL,
    next_due_at TIMESTAMP WITH TIME ZONE NULL,
    previous_box INTEGER NULL,
    next_box INTEGER NULL,
    previous_ease_factor DOUBLE PRECISION NULL,
    next_ease_factor DOUBLE PRECISION NULL,
    previous_interval_days INTEGER NULL,
    next_interval_days INTEGER NULL,
    direction VARCHAR(30) NULL CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean'))
);

CREATE INDEX idx_study_answers_card ON study_answers (card_id, answered_at);
CREATE INDEX idx_study_answers_session ON study_answers (session_id);

CREATE TABLE study_queue_items (
    session_id VARCHAR(36) NOT NULL REFERENCES study_sessions (id) ON DELETE CASCADE,
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('browse', 'self_assess', 'match', 'guess', 'recall', 'fill')),
    round INTEGER NOT NULL DEFAULT 1,
    card_id VARCHAR(36) NOT NULL REFERENCES cards (id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    status VARCHAR(10) NOT NULL CHECK (status IN ('pending', 'completed')),
    available_at INTEGER NOT NULL DEFAULT 0,
    answers_in_session INTEGER NOT NULL DEFAULT 0,
    remaining_ms INTEGER NULL,
    is_revealed SMALLINT NOT NULL DEFAULT 0,
    direction VARCHAR(30) NULL CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')),
    PRIMARY KEY (session_id, mode, round, card_id)
);

CREATE INDEX idx_study_queue_serving
    ON study_queue_items (session_id, mode, round, status, available_at, position);
