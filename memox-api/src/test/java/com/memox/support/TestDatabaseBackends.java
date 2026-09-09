package com.memox.support;

import lombok.experimental.UtilityClass;

/**
 * The single place the two test-database backends are named and constrained.
 *
 * <p>Every field is a compile-time constant because {@code @ConditionalOnProperty}
 * reads them from annotation attributes, and a non-final field will not compile there.
 */
@UtilityClass
public class TestDatabaseBackends {

	/** Selects the backend. Set by {@code application-test.properties} from {@code MEMOX_TEST_DATABASE}. */
	public static final String PROPERTY = "memox.test.database";

	/** Testcontainers starts a throwaway PostgreSQL. The default, and what CI uses. */
	public static final String TESTCONTAINERS = "testcontainers";

	/** No container: Spring binds {@code spring.datasource.*} to an already-running PostgreSQL. */
	public static final String LOCAL = "local";

	public static final String CONTAINER_IMAGE = "postgres:16-alpine";

	/**
	 * The container's database is renamed so ONE rule — "the name ends in {@code _test}" —
	 * covers both backends. Testcontainers would otherwise call it {@code test}, which fails
	 * that check and would force the destructive-operation guard to be backend-specific.
	 */
	public static final String CONTAINER_DATABASE = "memox_test";

	/**
	 * Encoding is pinned; collation deliberately is NOT.
	 *
	 * <p>Pinning {@code LC_CTYPE=C} was proposed and rejected: PostgreSQL's {@code lower()}
	 * uses LC_CTYPE, so under {@code C} it folds ASCII only and {@code LOWER('ÁNH')} comes back
	 * unchanged. The card mapper folds in SQL ({@code LOWER(#{front})}), and the audit verified
	 * that this matches Dart's {@code raw.trim().toLowerCase()} — an assumption that only holds
	 * while the database ctype is Unicode-aware. A Korean/Vietnamese app cannot fold in C.
	 *
	 * <p>Deterministic ordering, which is what the Drift port actually needs (translation row 8),
	 * is taken per statement with {@code ORDER BY name_folded COLLATE "C", id} instead of from
	 * the cluster.
	 */
	public static final String CONTAINER_INITDB_ARGS = "--encoding=UTF8";

	public static final String EXPECTED_ENCODING = "UTF8";

	/** Only a database whose name ends here may be cleaned or truncated by the suite. */
	public static final String REQUIRED_DATABASE_SUFFIX = "_test";
}
