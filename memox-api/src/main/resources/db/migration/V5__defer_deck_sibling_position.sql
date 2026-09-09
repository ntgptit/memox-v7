-- Reordering siblings needs the uniqueness of (sibling_scope_id, sibling_position) to hold at the
-- END of the transaction, not after every row.
--
-- Moving deck A from position 0 to position 2 means shifting B and C down by one. Any order of
-- those three UPDATEs passes through a state where two siblings share a position, so an immediate
-- unique check rejects the reorder half-way through. The usual escape -- park the moved row at a
-- negative position while the others shift -- is closed by ck_decks_sibling_position_non_negative.
--
-- ALTER TABLE ... ALTER CONSTRAINT can only re-arm foreign keys, so the constraint is dropped and
-- re-added rather than modified.
--
-- The cost, stated because it is easy to trip over later: a DEFERRABLE unique constraint cannot
-- serve as the arbiter of an ON CONFLICT clause. Nothing targets deck positions that way today,
-- and the tags uniqueness that DOES back an upsert is a separate, still-immediate index.

ALTER TABLE decks DROP CONSTRAINT uq_decks_sibling_scope_position;

ALTER TABLE decks
    ADD CONSTRAINT uq_decks_sibling_scope_position
    UNIQUE (sibling_scope_id, sibling_position) DEFERRABLE INITIALLY DEFERRED;
