package com.memox.deck.persistence;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

import org.apache.ibatis.type.BaseTypeHandler;
import org.apache.ibatis.type.JdbcType;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.memox.deck.entity.DeckAncestor;

/**
 * Reads the ancestry chain that rides along as a JSON scalar.
 *
 * <p>The chain is a scalar and not a join on purpose. Joining it onto the row would multiply a
 * single deck's read by its depth, and a level view already returns one row per child — the
 * breadcrumb would be repeated on every one of them. So the walk is aggregated into one JSON value
 * and decoded here.
 *
 * <p>Null becomes an empty list rather than null. The statements {@code COALESCE} to {@code '[]'}
 * already, so this is the second line of defence: a future caller that forgets the COALESCE gets an
 * empty breadcrumb instead of a NullPointerException three layers up.
 *
 * <p>It is <strong>not</strong> annotated with {@code @MappedTypes}, deliberately. This handler
 * knows one column shape, and registering it against {@code List} would offer it for every list
 * MyBatis ever maps. Statements name it explicitly.
 */
public class AncestryJsonTypeHandler extends BaseTypeHandler<List<DeckAncestor>> {

	private static final ObjectMapper OBJECT_MAPPER = new ObjectMapper();

	private static final TypeReference<List<DeckAncestor>> ANCESTRY = new TypeReference<>() {
	};

	@Override
	public void setNonNullParameter(
			PreparedStatement statement, int index, List<DeckAncestor> parameter, JdbcType jdbcType)
			throws SQLException {
		statement.setString(index, write(parameter));
	}

	@Override
	public List<DeckAncestor> getNullableResult(ResultSet resultSet, String columnName) throws SQLException {
		return read(resultSet.getString(columnName));
	}

	@Override
	public List<DeckAncestor> getNullableResult(ResultSet resultSet, int columnIndex) throws SQLException {
		return read(resultSet.getString(columnIndex));
	}

	@Override
	public List<DeckAncestor> getNullableResult(CallableStatement statement, int columnIndex) throws SQLException {
		return read(statement.getString(columnIndex));
	}

	private List<DeckAncestor> read(String json) throws SQLException {
		if (json == null || json.isBlank()) {
			return List.of();
		}
		try {
			return List.copyOf(OBJECT_MAPPER.readValue(json, ANCESTRY));
		} catch (java.io.IOException exception) {
			throw new SQLException("ancestry column is not a JSON array of {id, name, distance}", exception);
		}
	}

	private String write(List<DeckAncestor> ancestry) throws SQLException {
		try {
			return OBJECT_MAPPER.writeValueAsString(ancestry);
		} catch (com.fasterxml.jackson.core.JsonProcessingException exception) {
			throw new SQLException("could not serialise the ancestry chain", exception);
		}
	}
}
