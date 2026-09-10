-- One root deck, and the delete batch that soft-deletes it. Nothing else exists.
--
-- See no-decks.sql for why every script here starts by emptying the two tables.
DELETE FROM decks;
DELETE FROM delete_batches;

-- The batch is inserted first: decks.delete_batch_id references it, so the other order would
-- violate the foreign key.
INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at)
VALUES ('22222222-2222-4222-8222-222222222222', 'deck',
        '11111111-1111-4111-8111-111111111111', TIMESTAMPTZ '1970-01-01 00:00:00+00');

INSERT INTO decks (id, name, parent_deck_id, sibling_scope_id, sibling_position,
                   root_deck_id, content_type, scheduler_type, scheduler_version,
                   scheduler_generation, delete_batch_id, created_at, updated_at)
VALUES ('11111111-1111-4111-8111-111111111111', 'Korean', NULL,
        '00000000-0000-0000-0000-000000000000', 7,
        '11111111-1111-4111-8111-111111111111', 'deck', 'eight_box', 1, 3,
        '22222222-2222-4222-8222-222222222222',
        TIMESTAMPTZ '1970-01-01 00:00:00+00', TIMESTAMPTZ '1970-01-01 00:00:00+00');
