package com.memox.support;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Timestamp;
import java.time.Instant;

import org.junit.jupiter.api.Test;

/**
 * Proves the reset empties the tables the old one silently left behind.
 *
 * <p>{@code TRUNCATE TABLE decks CASCADE} reached seven tables through the foreign keys and missed
 * {@code tags} and {@code delete_batches}, which have no FK path from {@code decks}. Rows in those
 * two survived into the next test. This test fails against that implementation and passes against
 * the catalog-driven one.
 */
class TestDataResetTest extends PostgresIntegrationTest {

	private static final String TAG_ID = "11111111-1111-4111-8111-111111111111";
	private static final String BATCH_ID = "22222222-2222-4222-8222-222222222222";
	private static final String CARD_ID = "33333333-3333-4333-8333-333333333333";

	@Test
	void removesRowsFromTablesTheCascadeNeverReached() {
		this.jdbcTemplate.update(
				"INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, ?, ?)",
				TAG_ID, "leak", "leak", Timestamp.from(Instant.EPOCH));
		this.jdbcTemplate.update(
				"INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES (?, ?, ?, ?)",
				BATCH_ID, "card", CARD_ID, Timestamp.from(Instant.EPOCH));

		resetMemoxData();

		assertThat(count("tags")).isZero();
		assertThat(count("delete_batches")).isZero();
	}

	@Test
	void keepsExactlyOneSeededSettingsRow() {
		resetMemoxData();

		assertThat(count("app_settings")).isOne();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT card_limit FROM app_settings WHERE id = 1", Integer.class))
				.as("the row is reseeded with the column defaults V2 relies on")
				.isEqualTo(20);
	}

	@Test
	void leavesFlywayAndSchemaMarkerTablesAlone() {
		resetMemoxData();

		assertThat(count("flyway_schema_history"))
				.as("emptying it would make the next run believe the schema is new")
				.isPositive();
		assertThat(count("api_metadata")).isPositive();
	}

	@Test
	void coversEveryMemoxTableRatherThanAHandWrittenList() {
		final var reset = new MemoxTestDataReset(this.jdbcTemplate, dataSourceOfThisTest());

		assertThat(reset.resettableTables())
				.contains("decks", "cards", "card_study_states", "tags", "card_tags",
						"delete_batches", "app_settings", "study_sessions", "study_answers",
						"study_queue_items")
				.doesNotContainAnyElementsOf(MemoxTestDataReset.TABLES_THE_RESET_MUST_NOT_TOUCH);
	}

	private javax.sql.DataSource dataSourceOfThisTest() {
		return this.jdbcTemplate.getDataSource();
	}

	private long count(String table) {
		return this.jdbcTemplate.queryForObject("SELECT COUNT(*) FROM " + table, Long.class);
	}
}
