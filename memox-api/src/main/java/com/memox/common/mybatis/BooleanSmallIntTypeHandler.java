package com.memox.common.mybatis;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

/**
 * Maps Java {@code boolean} to the SMALLINT 0/1 columns this schema uses for flags.
 *
 * <p>The schema stores booleans as {@code SMALLINT NOT NULL CHECK (x IN (0, 1))} — the shape the
 * SQLite original had — for {@code is_flagged}, {@code used_hint}, {@code is_revealed} and
 * {@code reminder_enabled}. The two directions are not symmetric without this handler: reading
 * works by accident, because PostgreSQL's driver lets {@code getBoolean} read a smallint, while
 * writing fails outright with <em>column "is_flagged" is of type smallint but expression is of type
 * boolean</em>. So the module could read a flag it could never write, and would have discovered
 * that at the first flag-toggle rather than here.
 *
 * <p>{@code @MappedTypes} names BOTH {@code Boolean.class} and {@code boolean.class}. MyBatis keys
 * its registry on the exact class, and the primitive and the wrapper are different keys — the same
 * distinction that made {@code javaType="int"} silently mean {@code Integer} and turned every deck
 * creation into an HTTP 500. Registering one and assuming the other is covered is that bug again.
 *
 * <p><strong>It is bound to SMALLINT only, deliberately.</strong> The obvious-looking
 * {@code includeNullJdbcType = true} would also make this the handler for every boolean with no
 * JDBC type stated — including {@code activeDeckExists}, whose {@code SELECT EXISTS (...)} returns
 * a real PostgreSQL BOOLEAN. That column would then be read with {@code getShort}, and this
 * handler would have quietly taken over a mapping it is wrong for. Statements that want it say so:
 * either {@code typeHandler=} on the result-map argument, or {@code jdbcType=SMALLINT} on the bind.
 */
@MappedTypes({ Boolean.class, boolean.class })
@MappedJdbcTypes(JdbcType.SMALLINT)
public class BooleanSmallIntTypeHandler extends BaseTypeHandler<Boolean> {

	private static final short TRUE_VALUE = 1;
	private static final short FALSE_VALUE = 0;

	@Override
	public void setNonNullParameter(PreparedStatement statement, int index, Boolean parameter, JdbcType jdbcType)
			throws SQLException {
		statement.setShort(index, Boolean.TRUE.equals(parameter) ? TRUE_VALUE : FALSE_VALUE);
	}

	@Override
	public Boolean getNullableResult(ResultSet resultSet, String columnName) throws SQLException {
		final var value = resultSet.getShort(columnName);
		return resultSet.wasNull() ? null : value != FALSE_VALUE;
	}

	@Override
	public Boolean getNullableResult(ResultSet resultSet, int columnIndex) throws SQLException {
		final var value = resultSet.getShort(columnIndex);
		return resultSet.wasNull() ? null : value != FALSE_VALUE;
	}

	@Override
	public Boolean getNullableResult(CallableStatement statement, int columnIndex) throws SQLException {
		final var value = statement.getShort(columnIndex);
		return statement.wasNull() ? null : value != FALSE_VALUE;
	}
}
