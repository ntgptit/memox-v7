package com.memox.common.mybatis;

import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import com.memox.common.scheduler.SchedulerType;

@MappedTypes(SchedulerType.class)
@MappedJdbcTypes(JdbcType.VARCHAR)
public final class SchedulerTypeTypeHandler extends AbstractStringValueEnumTypeHandler<SchedulerType> {

	public SchedulerTypeTypeHandler() {
		super(SchedulerType.class);
	}
}
