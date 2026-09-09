package com.memox.migration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.support.TransactionTemplate;

import com.memox.support.PostgresIntegrationTest;

class FlywayMigrationTest extends PostgresIntegrationTest {

	private static final String FIRST_DECK_ID = "11111111-1111-4111-8111-111111111111";
	private static final String SECOND_DECK_ID = "22222222-2222-4222-8222-222222222222";
	private static final String ROOT_SCOPE = "00000000-0000-0000-0000-000000000000";

	private static final String INSERT_ROOT_DECK_AT = """
			INSERT INTO decks (id, name, sibling_position, sibling_scope_id, root_deck_id,
			                   content_type, scheduler_type, scheduler_version,
			                   scheduler_generation, created_at, updated_at)
			VALUES (?, ?, ?, ?, ?, 'deck', 'sm2', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)""";

	@Autowired
	private TransactionTemplate transactionTemplate;

	@Test
	void migratesApiMetadataTable() {
		final var tableCount = this.jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'api_metadata'",
				Integer.class);

		assertThat(tableCount).isEqualTo(1);
	}

	@Test
	void migratesTheCompleteMemoXSchemaAndSeedsSettings() {
		final var expectedTables = List.of(
				"decks",
				"cards",
				"card_study_states",
				"tags",
				"card_tags",
				"app_settings",
				"delete_batches",
				"study_sessions",
				"study_answers",
				"study_queue_items");

		final var tables = this.jdbcTemplate.queryForList(
				"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
				String.class);
		final var settingsRows = this.jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM app_settings WHERE id = 1",
				Integer.class);

		assertThat(tables).containsAll(expectedTables);
		assertThat(settingsRows).isEqualTo(1);
	}

	/**
	 * Deferred is not disabled: a duplicate that survives to commit is still rejected.
	 *
	 * <p>Each {@code jdbcTemplate.update} commits on its own, so the second insert's collision
	 * reaches the constraint check even though V5 moved that check to commit time.
	 */
	@Test
	void enforcesSiblingPositionsWithinTheSameScope() {
		insertRootDeckAt(FIRST_DECK_ID, "First", 99);

		assertThatThrownBy(() -> insertRootDeckAt(SECOND_DECK_ID, "Second", 99))
				.isInstanceOf(DataIntegrityViolationException.class);
	}

	@Test
	void rejectsNegativeSiblingPositions() {
		assertThatThrownBy(() -> insertRootDeckAt(FIRST_DECK_ID, "Invalid", -1))
				.isInstanceOf(DataIntegrityViolationException.class);
	}

	/**
	 * The constraint still exists and is now deferrable.
	 *
	 * <p>Asserting the flag is {@code true} rather than "not false" is deliberate: a constraint that
	 * had been dropped and never re-added would make this query return no row, and an assertion
	 * written loosely enough would pass on that.
	 */
	@Test
	void defersTheSiblingPositionConstraintSoAReorderCanShiftARun() {
		final var deferrable = this.jdbcTemplate.queryForObject(
				"SELECT condeferrable FROM pg_constraint WHERE conname = 'uq_decks_sibling_scope_position'",
				Boolean.class);

		assertThat(deferrable).isTrue();
	}

	/**
	 * The reorder V5 exists for, performed for real.
	 *
	 * <p>Swapping two siblings must pass through a state where both hold the same position — no
	 * ordering of the two UPDATEs avoids it, and the usual escape of parking a row at a negative
	 * position is closed by {@code ck_decks_sibling_position_non_negative}. Before V5 this
	 * transaction failed on its second statement.
	 *
	 * <p>Asserting {@code condeferrable} alone would not have covered this. That checks the flag;
	 * this checks that PostgreSQL then behaves the way the flag promises.
	 */
	@Test
	void allowsASiblingSwapToCollideInsideOneTransaction() {
		insertRootDeck("root", "Root");
		insertSubDeckAt("a", "A", "root", "root", 0);
		insertSubDeckAt("b", "B", "root", "root", 1);

		this.transactionTemplate.executeWithoutResult(status -> {
			this.jdbcTemplate.update("UPDATE decks SET sibling_position = 1 WHERE id = 'a'");
			this.jdbcTemplate.update("UPDATE decks SET sibling_position = 0 WHERE id = 'b'");
		});

		assertThat(siblingPositionOf("a")).isEqualTo(1);
		assertThat(siblingPositionOf("b")).isZero();
	}

	private void insertRootDeckAt(String deckId, String name, int siblingPosition) {
		this.jdbcTemplate.update(INSERT_ROOT_DECK_AT, deckId, name, siblingPosition, ROOT_SCOPE, deckId);
	}
}
