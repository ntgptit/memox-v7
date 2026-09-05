package com.memox.config;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.SQLException;

import javax.sql.DataSource;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "spring.profiles.active=local")
class DatabaseConfigurationTest {

	@Autowired
	private DataSource dataSource;

	@Test
	void connectsToPostgreSql() throws SQLException {
		try (var connection = dataSource.getConnection()) {
			assertThat(connection.getMetaData().getDatabaseProductName()).isEqualTo("PostgreSQL");
		}
	}
}
