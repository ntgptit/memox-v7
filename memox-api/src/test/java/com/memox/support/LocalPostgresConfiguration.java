package com.memox.support;

import java.util.concurrent.atomic.AtomicBoolean;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.autoconfigure.flyway.FlywayMigrationStrategy;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;

/**
 * The local backend: a PostgreSQL that is already running, cleaned before use.
 *
 * <p>It defines NO {@code DataSource} bean on purpose. A hand-built one would satisfy
 * {@code DataSourceAutoConfiguration}'s {@code @ConditionalOnMissingBean(DataSource.class)} and
 * silently switch off Spring Boot's own pooled configuration — so {@code spring.datasource.hikari.*}
 * would apply on the container backend and be dropped on this one, making the harness itself the
 * difference between the two runs. Instead this class contributes only the migration strategy, and
 * Spring binds {@code spring.datasource.*} the ordinary way.
 */
@TestConfiguration(proxyBeanMethods = false)
@ConditionalOnProperty(name = TestDatabaseBackends.PROPERTY, havingValue = TestDatabaseBackends.LOCAL)
public class LocalPostgresConfiguration {

	/**
	 * Cleaned once per JVM, not once per Spring context.
	 *
	 * <p>{@code FlywayMigrationStrategy} runs on every context refresh, and the Spring TestContext
	 * framework caches contexts rather than closing them — so a second context appearing mid-run
	 * (one test carrying {@code @MockitoBean} or {@code @TestPropertySource} is enough) would clean
	 * the schema out from under the tests already using the first. The flag makes the first context
	 * clean and every later one merely migrate.
	 */
	private static final AtomicBoolean ALREADY_CLEANED = new AtomicBoolean();

	@Bean
	FlywayMigrationStrategy cleanAndMigrateLocalTestDatabase() {
		return flyway -> {
			if (!ALREADY_CLEANED.compareAndSet(false, true)) {
				flyway.migrate();
				return;
			}
			DisposableTestDatabase.require(flyway.getConfiguration().getDataSource());
			flyway.clean();
			flyway.migrate();
		};
	}
}
