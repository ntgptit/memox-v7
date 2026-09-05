package com.memox.deck.persistence;

import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import com.memox.common.mybatis.AbstractStringValueEnumTypeHandler;
import com.memox.deck.domain.DeckContentType;

@MappedTypes(DeckContentType.class)
@MappedJdbcTypes(JdbcType.VARCHAR)
public final class DeckContentTypeTypeHandler extends AbstractStringValueEnumTypeHandler<DeckContentType> {

	public DeckContentTypeTypeHandler() {
		super(DeckContentType.class);
	}
}
