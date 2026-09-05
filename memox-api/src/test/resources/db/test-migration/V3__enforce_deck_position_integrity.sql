ALTER TABLE decks ADD COLUMN sibling_scope_id VARCHAR(36) NOT NULL
    DEFAULT '00000000-0000-0000-0000-000000000000';

UPDATE decks
SET sibling_scope_id = parent_deck_id
WHERE parent_deck_id IS NOT NULL;

ALTER TABLE decks
    ADD CONSTRAINT uq_decks_sibling_scope_position UNIQUE (sibling_scope_id, sibling_position);
