package com.memox.migration;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

@SpringBootTest(properties = "spring.profiles.active=local")
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
}
