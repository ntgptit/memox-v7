-- An empty deck table, for the statements whose answer is "nothing".
--
-- Every script in this directory starts with these two deletes rather than assuming the table is
-- already empty, because on the `local` backend this tier shares one database with the
-- @SpringBootTest suite, and that suite truncates BEFORE each of its tests rather than after — so
-- whatever its last test inserted is still committed when a mapper test starts. On the
-- `testcontainers` backend the slice gets its own container and the deletes match nothing. Running
-- them on both is what keeps the two backends the same run, which is the rule memox-api/README.md
-- states for the pair.
--
-- They are ordinary DML inside the test's own transaction, and @MybatisTest rolls that transaction
-- back, so nothing another test committed is actually lost.
--
-- Order matters: decks first. `decks.delete_batch_id` references `delete_batches` ON DELETE
-- CASCADE, so emptying the batches first would take the decks with it and leave the second
-- statement describing something that had already happened.
DELETE FROM decks;
DELETE FROM delete_batches;
