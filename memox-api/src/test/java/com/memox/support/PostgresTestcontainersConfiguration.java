package com.memox.support;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.containers.PostgreSQLContainer;

/**
 * The default backend: a throwaway PostgreSQL container. Used by CI and by any machine with Docker.
 *
 * <p>{@code matchIfMissing = true} keeps this the default, so a machine that sets nothing behaves
 * exactly as it did before the local backend existed.
 */
@TestConfiguration(proxyBeanMethods = false)
@ConditionalOnProperty(
		name = TestDatabaseBackends.PROPERTY,
		havingValue = TestDatabaseBackends.TESTCONTAINERS,
		matchIfMissing = true)
public class PostgresTestcontainersConfiguration {

	@Bean
	@ServiceConnection
	PostgreSQLContainer<?> postgresContainer() {
		return new PostgreSQLContainer<>(TestDatabaseBackends.CONTAINER_IMAGE)
				// Renamed from Testcontainers' default `test` so the "_test suffix" rule that
				// protects the local backend covers this one too, with one rule rather than two.
				.withDatabaseName(TestDatabaseBackends.CONTAINER_DATABASE)
				.withEnv("POSTGRES_INITDB_ARGS", TestDatabaseBackends.CONTAINER_INITDB_ARGS);
	}
}
