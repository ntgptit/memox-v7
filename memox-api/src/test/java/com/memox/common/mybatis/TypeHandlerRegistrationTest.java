package com.memox.common.mybatis;

import static org.assertj.core.api.Assertions.assertThat;

import org.apache.ibatis.session.SqlSessionFactory;
import org.apache.ibatis.type.JdbcType;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.support.PostgresIntegrationTest;

/**
 * What the running MyBatis configuration actually resolved, rather than what the annotations say.
 *
 * <p>A type handler that is written correctly and registered for the wrong key is invisible: every
 * statement keeps using the default, every test stays green, and the handler is discovered to be
 * inert only when a column it was meant to own behaves oddly. That is not hypothetical here — the
 * primitive/wrapper split in MyBatis's registry is exactly what made {@code javaType="int"} mean
 * {@code Integer} and turned every deck creation into an HTTP 500.
 */
class TypeHandlerRegistrationTest extends PostgresIntegrationTest {

	@Autowired
	private SqlSessionFactory sqlSessionFactory;

	@Test
	void resolvesTheSmallIntBooleanHandlerForBothThePrimitiveAndTheWrapper() {
		final var registry = this.sqlSessionFactory.getConfiguration().getTypeHandlerRegistry();

		assertThat(registry.getTypeHandler(Boolean.class, JdbcType.SMALLINT))
				.isInstanceOf(BooleanSmallIntTypeHandler.class);
		assertThat(registry.getTypeHandler(boolean.class, JdbcType.SMALLINT))
				.isInstanceOf(BooleanSmallIntTypeHandler.class);
	}

	/**
	 * The other half of the contract, and the reason {@code includeNullJdbcType} is off.
	 *
	 * <p>{@code activeDeckExists} returns a real PostgreSQL BOOLEAN from {@code SELECT EXISTS (...)}
	 * with no JDBC type stated. If the SMALLINT handler had claimed that key too, that statement
	 * would be read with {@code getShort} against a bool column. This asserts the takeover did not
	 * happen — a guard that costs one line and would otherwise be found by a broken card list.
	 */
	@Test
	void leavesPlainBooleansToTheDefaultHandler() {
		final var registry = this.sqlSessionFactory.getConfiguration().getTypeHandlerRegistry();

		assertThat(registry.getTypeHandler(Boolean.class, (JdbcType) null))
				.isNotInstanceOf(BooleanSmallIntTypeHandler.class);
		assertThat(registry.getTypeHandler(boolean.class, (JdbcType) null))
				.isNotInstanceOf(BooleanSmallIntTypeHandler.class);
	}
}
