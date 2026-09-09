package com.memox.common.mybatis;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.junit.jupiter.api.Test;

/**
 * The write direction is the reason this handler exists, so it is the direction tested hardest.
 *
 * <p>Reading a SMALLINT as a boolean already worked through the driver; binding a Java boolean into
 * one never did. A test that only read would pass against no handler at all.
 */
class BooleanSmallIntTypeHandlerTest {

	private final BooleanSmallIntTypeHandler handler = new BooleanSmallIntTypeHandler();

	@Test
	void writesTrueAsOneAndFalseAsZeroRatherThanAsABoolean() throws SQLException {
		final var statement = mock(PreparedStatement.class);

		handler.setNonNullParameter(statement, 1, true, null);
		handler.setNonNullParameter(statement, 2, false, null);

		verify(statement).setShort(1, (short) 1);
		verify(statement).setShort(2, (short) 0);
	}

	@Test
	void readsOneAsTrueAndZeroAsFalseByColumnName() throws SQLException {
		final var resultSet = mock(ResultSet.class);
		given(resultSet.getShort("is_flagged")).willReturn((short) 1, (short) 0);
		given(resultSet.wasNull()).willReturn(false);

		assertThat(handler.getNullableResult(resultSet, "is_flagged")).isTrue();
		assertThat(handler.getNullableResult(resultSet, "is_flagged")).isFalse();
	}

	@Test
	void readsOneAsTrueAndZeroAsFalseByColumnIndex() throws SQLException {
		final var resultSet = mock(ResultSet.class);
		given(resultSet.getShort(3)).willReturn((short) 1, (short) 0);
		given(resultSet.wasNull()).willReturn(false);

		assertThat(handler.getNullableResult(resultSet, 3)).isTrue();
		assertThat(handler.getNullableResult(resultSet, 3)).isFalse();
	}

	/**
	 * {@code used_hint} is the nullable one. {@code getShort} answers 0 for SQL NULL, so without the
	 * {@code wasNull} check a null hint would read as "the user did not use a hint" — a different
	 * claim from "we do not know".
	 */
	@Test
	void distinguishesSqlNullFromFalse() throws SQLException {
		final var resultSet = mock(ResultSet.class);
		given(resultSet.getShort(anyString())).willReturn((short) 0);
		given(resultSet.getShort(anyInt())).willReturn((short) 0);
		given(resultSet.wasNull()).willReturn(true);

		assertThat(handler.getNullableResult(resultSet, "used_hint")).isNull();
		assertThat(handler.getNullableResult(resultSet, 1)).isNull();
	}

	/**
	 * {@link java.sql.CallableStatement} is the overload nothing in this module calls yet.
	 *
	 * <p>{@link org.apache.ibatis.type.BaseTypeHandler} makes it abstract, so it has to exist, and
	 * an implementation that exists without a test is the shape a copy-paste error hides in — the
	 * three {@code getNullableResult} bodies are near-identical, which is exactly when one of them
	 * quietly loses its {@code wasNull} check.
	 */
	@Test
	void readsThroughACallableStatementOnTheSameTerms() throws SQLException {
		final var statement = mock(CallableStatement.class);
		given(statement.getShort(1)).willReturn((short) 1, (short) 0);
		given(statement.wasNull()).willReturn(false);

		assertThat(handler.getNullableResult(statement, 1)).isTrue();
		assertThat(handler.getNullableResult(statement, 1)).isFalse();
	}

	@Test
	void distinguishesSqlNullFromFalseThroughACallableStatement() throws SQLException {
		final var statement = mock(CallableStatement.class);
		given(statement.getShort(1)).willReturn((short) 0);
		given(statement.wasNull()).willReturn(true);

		assertThat(handler.getNullableResult(statement, 1)).isNull();
	}

	/**
	 * The CHECK constraint restricts the columns to 0 and 1, but a handler that only recognised 1
	 * would turn any other truthy value into false. Anything not zero is true.
	 */
	@Test
	void treatsAnyNonZeroAsTrue() throws SQLException {
		final var resultSet = mock(ResultSet.class);
		given(resultSet.getShort("x")).willReturn((short) 2);
		given(resultSet.wasNull()).willReturn(false);

		assertThat(handler.getNullableResult(resultSet, "x")).isTrue();
	}
}
