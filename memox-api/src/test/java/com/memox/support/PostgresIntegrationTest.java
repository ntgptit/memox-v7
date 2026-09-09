package com.memox.support;

import javax.sql.DataSource;

import org.junit.jupiter.api.BeforeEach;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

/**
 * Base class for every integration test: one Spring context, one database, emptied between tests.
 *
 * <p>Both backend configurations are imported unconditionally; exactly one of them activates,
 * decided by {@code memox.test.database}. Importing both from here rather than from each subclass
 * is what keeps the suite on a single context cache key.
 *
 * <p>{@code @AutoConfigureMockMvc} lives here rather than on the three subclasses that used to
 * carry it. Two different sets of annotations meant two context cache keys, therefore two context
 * boots, therefore two PostgreSQL containers for one test run.
 */
@ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
@Import({ PostgresTestcontainersConfiguration.class, LocalPostgresConfiguration.class })
public abstract class PostgresIntegrationTest {

	@Autowired
	protected JdbcTemplate jdbcTemplate;

	@Autowired
	private DataSource dataSource;

	private MemoxTestDataReset reset;

	@BeforeEach
	void clearMemoxData() {
		resetMemoxData();
	}

	/**
	 * Empties every MemoX table and reseeds the singleton settings row.
	 *
	 * <p>{@code protected} so a subclass in another package can call it mid-test — a trash or tag
	 * test that needs a second clean slate inside one method.
	 */
	protected void resetMemoxData() {
		if (this.reset == null) {
			this.reset = new MemoxTestDataReset(this.jdbcTemplate, this.dataSource);
		}
		this.reset.reset();
	}
}
