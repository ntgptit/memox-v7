package com.memox.card.persistence;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.card.entity.Card;
import com.memox.common.pagination.PageSlice;

@Mapper
public interface CardMapper {

	void insertCard(Card card);

	void insertInitialStudyState(
			@Param("cardId") String cardId,
			@Param("schedulerType") String schedulerType,
			@Param("schedulerVersion") int schedulerVersion,
			@Param("schedulerGeneration") int schedulerGeneration);

	boolean activeDeckExists(@Param("deckId") String deckId);

	List<Card> findActiveCardsByDeck(@Param("deckId") String deckId, @Param("slice") PageSlice slice);

	long countActiveCardsByDeck(@Param("deckId") String deckId);
}
