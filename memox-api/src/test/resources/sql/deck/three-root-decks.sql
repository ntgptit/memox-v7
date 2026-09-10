-- Three root decks, created at the same instant, in three different sibling positions.
--
-- See no-decks.sql for why every script here starts by emptying the two tables.
DELETE FROM decks;
DELETE FROM delete_batches;

-- scheduler_version, scheduler_generation and sibling_position hold three DIFFERENT numbers on
-- purpose — 1, 3 and the row's own position. A result map that binds one of them to a neighbour's
-- field is caught by the field-by-field assertions in DeckMapperTest; it would not be if the three
-- carried the same value.
--
-- created_at is identical across all three rows, which is what
-- `breaksTiesByIdSoConsecutivePagesDoNotOverlap` needs: ordering by created_at alone leaves
-- PostgreSQL free to break the tie differently on each execution.
--
-- sibling_scope_id is the same for all three because they are siblings — they are all roots. The
-- unique constraint over (sibling_scope_id, sibling_position) is why their positions differ.
INSERT INTO decks (id, name, parent_deck_id, sibling_scope_id, sibling_position,
                   root_deck_id, content_type, scheduler_type, scheduler_version,
                   scheduler_generation, created_at, updated_at)
VALUES
    ('11111111-1111-4111-8111-111111111111', 'Korean', NULL,
     '00000000-0000-0000-0000-000000000000', 7,
     '11111111-1111-4111-8111-111111111111', 'deck', 'eight_box', 1, 3,
     TIMESTAMPTZ '1970-01-01 00:00:00+00', TIMESTAMPTZ '1970-01-01 00:00:00+00'),
    ('33333333-3333-4333-8333-333333333333', 'Japanese', NULL,
     '00000000-0000-0000-0000-000000000000', 3,
     '33333333-3333-4333-8333-333333333333', 'deck', 'eight_box', 1, 3,
     TIMESTAMPTZ '1970-01-01 00:00:00+00', TIMESTAMPTZ '1970-01-01 00:00:00+00'),
    ('44444444-4444-4444-8444-444444444444', 'Vietnamese', NULL,
     '00000000-0000-0000-0000-000000000000', 5,
     '44444444-4444-4444-8444-444444444444', 'deck', 'eight_box', 1, 3,
     TIMESTAMPTZ '1970-01-01 00:00:00+00', TIMESTAMPTZ '1970-01-01 00:00:00+00');
