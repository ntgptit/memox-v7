package com.memox.support;

import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.jdbc.core.JdbcTemplate;

@ActiveProfiles("test")
@SpringBootTest
@Import(PostgresTestcontainersConfiguration.class)
public abstract class PostgresIntegrationTest {

	@Autowired
	protected JdbcTemplate jdbcTemplate;

	@BeforeEach
	void clearMemoXData() {
		jdbcTemplate.execute("TRUNCATE TABLE decks CASCADE");
	}
}
