package com.memox.trash.persistence;

import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import com.memox.common.mybatis.AbstractStringValueEnumTypeHandler;
import com.memox.trash.enums.TrashItemType;

@MappedTypes(TrashItemType.class)
@MappedJdbcTypes(JdbcType.VARCHAR)
public final class TrashItemTypeTypeHandler extends AbstractStringValueEnumTypeHandler<TrashItemType> {

	public TrashItemTypeTypeHandler() {
		super(TrashItemType.class);
	}
}
