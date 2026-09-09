package com.memox.support;

import java.sql.SQLException;
import java.util.Locale;

import javax.sql.DataSource;

import lombok.experimental.UtilityClass;

/**
 * The one rule that stands between this suite and someone's real database.
 *
 * <p>The guard lives with the destructive operations rather than with the backend switch,
 * because the switch is not exhaustive: {@code memox.test.database} is matched by value, so a
 * typo, a stray trailing space, or a variable set for another tool selects neither backend and
 * would leave the suite pointed at whatever {@code spring.datasource.url} happens to say.
 *
 * <p>That is not hypothetical here. {@code application-local.properties} already points the
 * application at {@code jdbc:postgresql://localhost:5432/memox} — same host, same port, same
 * role, one character away from {@code memox_test}.
 */
@UtilityClass
public class DisposableTestDatabase {

	/**
	 * Throws unless the connected database is disposable, i.e. its name ends in {@code _test}.
	 *
	 * @return the database name, so callers can name it in their own messages
	 */
	public String require(DataSource dataSource) {
		final var databaseName = readName(dataSource);
		if (databaseName.toLowerCase(Locale.ROOT).endsWith(TestDatabaseBackends.REQUIRED_DATABASE_SUFFIX)) {
			return databaseName;
		}
		throw new IllegalStateException(
				("Refusing to modify database '%s': the test suite cleans and truncates, so it only runs "
						+ "against a database whose name ends in '%s'. Point MEMOX_TEST_DB_URL at a disposable "
						+ "database — never at the application's own.")
						.formatted(databaseName, TestDatabaseBackends.REQUIRED_DATABASE_SUFFIX));
	}

	private String readName(DataSource dataSource) {
		try (var connection = dataSource.getConnection()) {
			return connection.getCatalog();
		} catch (SQLException exception) {
			throw new IllegalStateException("Could not read the connected database name.", exception);
		}
	}
}
