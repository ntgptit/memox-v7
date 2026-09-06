package com.memox.card.persistence;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.card.domain.Card;

@Mapper
public interface CardMapper {

	void insertCard(Card card);

	void insertInitialStudyState(
			@Param("cardId") String cardId,
			@Param("schedulerType") String schedulerType,
			@Param("schedulerVersion") int schedulerVersion,
			@Param("schedulerGeneration") int schedulerGeneration);

	List<CardPageRow> findActiveCardsByDeck(CardPageQuery query);
}
