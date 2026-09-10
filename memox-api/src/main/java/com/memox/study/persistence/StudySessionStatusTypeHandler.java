package com.memox.study.persistence;

import org.apache.ibatis.type.JdbcType;
import org.apache.ibatis.type.MappedJdbcTypes;
import org.apache.ibatis.type.MappedTypes;

import com.memox.common.mybatis.AbstractStringValueEnumTypeHandler;
import com.memox.study.enums.StudySessionStatus;

@MappedTypes(StudySessionStatus.class)
@MappedJdbcTypes(JdbcType.VARCHAR)
public final class StudySessionStatusTypeHandler
		extends AbstractStringValueEnumTypeHandler<StudySessionStatus> {

	public StudySessionStatusTypeHandler() {
		super(StudySessionStatus.class);
	}
}
