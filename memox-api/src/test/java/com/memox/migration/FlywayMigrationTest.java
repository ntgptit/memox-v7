package com.memox.migration;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(properties = "spring.profiles.active=test")
class FlywayMigrationTest {

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Test
	void migratesApiMetadataTable() {
		final var tableCount = jdbcTemplate.queryForObject(
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

		final var tables = jdbcTemplate.queryForList(
				"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'",
				String.class);
		final var settingsRows = jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM app_settings WHERE id = 1",
				Integer.class);

		assertThat(tables).containsAll(expectedTables);
		assertThat(settingsRows).isEqualTo(1);
	}

	@Test
	void enforcesSiblingPositionsWithinTheSameScope() {
		final var firstDeckId = "11111111-1111-4111-8111-111111111111";
		final var secondDeckId = "22222222-2222-4222-8222-222222222222";
		final var rootScope = "00000000-0000-0000-0000-000000000000";
		jdbcTemplate.update("""
				INSERT INTO decks (id, name, sibling_position, sibling_scope_id, root_deck_id, content_type,
				                   scheduler_type, scheduler_version, scheduler_generation, created_at, updated_at)
				VALUES (?, 'First', 99, ?, ?, 'deck', 'sm2', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
				""", firstDeckId, rootScope, firstDeckId);

		org.assertj.core.api.Assertions.assertThatThrownBy(() -> jdbcTemplate.update("""
					INSERT INTO decks (id, name, sibling_position, sibling_scope_id, root_deck_id, content_type,
					                   scheduler_type, scheduler_version, scheduler_generation, created_at, updated_at)
					VALUES (?, 'Second', 99, ?, ?, 'deck', 'sm2', 1, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
					""", secondDeckId, rootScope, secondDeckId))
				.isInstanceOf(org.springframework.dao.DataIntegrityViolationException.class);
	}
}
