package com.memox.support;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

import javax.sql.DataSource;

import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Empties every MemoX table between tests, derived from the catalog rather than a hand-list.
 *
 * <p>The previous reset was {@code TRUNCATE TABLE decks CASCADE}. Its reach is whatever the
 * foreign keys happen to give it — computed from V2's REFERENCES clauses, that is
 * {decks, cards, study_sessions, card_study_states, card_tags, study_answers, study_queue_items}.
 * {@code tags} and {@code delete_batches} have no FK path from {@code decks} and therefore
 * survived, leaking rows between tests. Both are central to the next phase: 13 tag statements and
 * 17 trash statements are about to be written against them.
 *
 * <p>Reading the catalog instead of naming tables means a table added by a future migration is
 * reset the day it appears, rather than the day someone notices a test is order-dependent.
 */
public class MemoxTestDataReset {

	/**
	 * Tables the reset must never empty.
	 *
	 * <p>{@code flyway_schema_history} is Flyway's own bookkeeping; emptying it would make the next
	 * migration run believe the schema is new. {@code api_metadata} is seeded by V1 and read as a
	 * schema marker.
	 *
	 * <p>{@code app_settings} is deliberately NOT here. It is truncated with everything else and
	 * then reseeded below, exactly as V2 seeds it — listing it as "protected" and deleting from it
	 * two lines later would tell the next reader the opposite of what the code does.
	 */
	static final List<String> TABLES_THE_RESET_MUST_NOT_TOUCH = List.of("flyway_schema_history", "api_metadata");

	/**
	 * {@code pg_catalog.pg_tables}, not {@code information_schema.tables}: the latter is
	 * privilege-filtered and lists only tables the current role holds some privilege on, so a
	 * permission change would silently shrink the reset instead of failing.
	 */
	private static final String LIST_TABLES = """
			SELECT tablename FROM pg_catalog.pg_tables WHERE schemaname = 'public' ORDER BY tablename""";

	private static final Instant SEEDED_AT = Instant.EPOCH;

	private final JdbcTemplate jdbcTemplate;

	public MemoxTestDataReset(JdbcTemplate jdbcTemplate, DataSource dataSource) {
		DisposableTestDatabase.require(dataSource);
		this.jdbcTemplate = jdbcTemplate;
	}

	public void reset() {
		final var tables = resettableTables();
		if (tables.isEmpty()) {
			throw new IllegalStateException(
					"No resettable tables found in schema 'public'. Flyway has not run, or the suite is "
							+ "connected to the wrong database.");
		}
		this.jdbcTemplate.execute(truncateStatement(tables));
		this.jdbcTemplate.update(
				"INSERT INTO app_settings (id, updated_at) VALUES (1, ?)", Timestamp.from(SEEDED_AT));
	}

	List<String> resettableTables() {
		return this.jdbcTemplate.queryForList(LIST_TABLES, String.class).stream()
				.filter(table -> !TABLES_THE_RESET_MUST_NOT_TOUCH.contains(table))
				.toList();
	}

	private String truncateStatement(List<String> tables) {
		return tables.stream()
				.map("\"%s\""::formatted)
				.collect(Collectors.joining(", ", "TRUNCATE TABLE ", " RESTART IDENTITY CASCADE"));
	}
}
