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
}
