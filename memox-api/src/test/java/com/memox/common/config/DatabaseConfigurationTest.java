package com.memox.common.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.SQLException;

import javax.sql.DataSource;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.support.PostgresIntegrationTest;

class DatabaseConfigurationTest extends PostgresIntegrationTest {

	@Autowired
	private DataSource dataSource;

	@Test
	void connectsToPostgreSQL() throws SQLException {
		try (var connection = dataSource.getConnection()) {
			assertThat(connection.getMetaData().getDatabaseProductName()).isEqualTo("PostgreSQL");
		}
	}
}
