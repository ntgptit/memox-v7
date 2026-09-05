package com.memox.repository;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.card.persistence.CardRow;
import com.memox.card.persistence.CardPageQuery;

@Mapper
public interface CardRepository {

	void insertCard(CardRow card);

	void insertInitialStudyState(
			@Param("cardId") String cardId,
			@Param("schedulerType") String schedulerType,
			@Param("schedulerVersion") int schedulerVersion,
			@Param("schedulerGeneration") int schedulerGeneration);

	List<CardRow> findActiveCardsByDeck(CardPageQuery query);
}
