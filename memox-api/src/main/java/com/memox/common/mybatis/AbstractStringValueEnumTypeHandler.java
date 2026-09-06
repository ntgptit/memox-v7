package com.memox.common.mybatis;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Arrays;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;

public abstract class AbstractStringValueEnumTypeHandler<E extends Enum<E> & PersistableEnum>
		extends BaseTypeHandler<E> {

	private final Class<E> enumType;
	private final Map<String, E> valuesByPersistenceValue;

	protected AbstractStringValueEnumTypeHandler(Class<E> enumType) {
		this.enumType = enumType;
		this.valuesByPersistenceValue = Arrays.stream(enumType.getEnumConstants())
				.collect(Collectors.toUnmodifiableMap(PersistableEnum::getValue, Function.identity()));
	}

	@Override
	public void setNonNullParameter(PreparedStatement statement, int index, E parameter, JdbcType jdbcType)
			throws SQLException {
		statement.setString(index, parameter.getValue());
	}

	@Override
	public E getNullableResult(ResultSet resultSet, String columnName) throws SQLException {
		return readValue(resultSet.getString(columnName));
	}

	@Override
	public E getNullableResult(ResultSet resultSet, int columnIndex) throws SQLException {
		return readValue(resultSet.getString(columnIndex));
	}

	@Override
	public E getNullableResult(CallableStatement statement, int columnIndex) throws SQLException {
		return readValue(statement.getString(columnIndex));
	}

	private E readValue(String value) throws SQLException {
		if (value == null) {
			return null;
		}
		final var enumValue = valuesByPersistenceValue.get(value);
		if (enumValue == null) {
			throw new SQLException("Unsupported %s persistence value: %s".formatted(enumType.getSimpleName(), value));
		}
		return enumValue;
	}
}
