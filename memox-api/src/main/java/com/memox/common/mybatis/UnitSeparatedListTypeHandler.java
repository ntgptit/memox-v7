package com.memox.common.mybatis;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;

/**
 * Splits a column aggregated with {@code chr(31)} back into a list.
 *
 * <p>ASCII 31 is the unit separator, and that is why it is the delimiter: it cannot occur in a tag
 * name, so no escaping is needed and no name can split itself in two. A comma would have to be
 * escaped, and the escaping would be the bug.
 *
 * <p>Empty and null both become an empty list. PostgreSQL's {@code string_agg} returns NULL for a
 * card with no tags, and {@code "".split(...)} in Java yields one empty element rather than none —
 * two different ways to arrive at a list that must be empty.
 */
public class UnitSeparatedListTypeHandler extends BaseTypeHandler<List<String>> {

	private static final String UNIT_SEPARATOR = "\u001f";

	@Override
	public void setNonNullParameter(
			PreparedStatement statement, int index, List<String> parameter, JdbcType jdbcType)
			throws SQLException {
		statement.setString(index, String.join(UNIT_SEPARATOR, parameter));
	}

	@Override
	public List<String> getNullableResult(ResultSet resultSet, String columnName) throws SQLException {
		return split(resultSet.getString(columnName));
	}

	@Override
	public List<String> getNullableResult(ResultSet resultSet, int columnIndex) throws SQLException {
		return split(resultSet.getString(columnIndex));
	}

	@Override
	public List<String> getNullableResult(CallableStatement statement, int columnIndex) throws SQLException {
		return split(statement.getString(columnIndex));
	}

	private List<String> split(String joined) {
		if (joined == null || joined.isEmpty()) {
			return List.of();
		}
		return List.of(joined.split(UNIT_SEPARATOR, -1));
	}
}
