package com.memox.study.persistence;

import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import com.memox.common.mybatis.AbstractStringValueEnumTypeHandler;
import com.memox.study.enums.StudySessionEndReason;

@MappedTypes(StudySessionEndReason.class)
@MappedJdbcTypes(JdbcType.VARCHAR)
public final class StudySessionEndReasonTypeHandler
		extends AbstractStringValueEnumTypeHandler<StudySessionEndReason> {

	public StudySessionEndReasonTypeHandler() {
		super(StudySessionEndReason.class);
	}
}
