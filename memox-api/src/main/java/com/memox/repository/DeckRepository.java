package com.memox.repository;

import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface DeckRepository {

	String readSchemaVersion();
}
