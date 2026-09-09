package com.memox.card.persistence;

import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.card.entity.Card;
import com.memox.card.entity.CardFilter;
import com.memox.card.entity.CardHistoryCursor;
import com.memox.card.entity.CardHistoryEntry;
import com.memox.card.entity.CardListItem;
import com.memox.card.entity.CardStateCounts;
import com.memox.card.entity.StageThresholds;
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

	List<CardListItem> findCardListItems(
			@Param("filter") CardFilter filter,
			@Param("slice") PageSlice slice);

	long countCardListItems(@Param("filter") CardFilter filter);

	List<String> findCardIdsMatching(
			@Param("filter") CardFilter filter,
			@Param("slice") PageSlice slice);

	CardStateCounts countCardStatesByDeck(
			@Param("deckId") String deckId,
			@Param("thresholds") StageThresholds thresholds);

	CardListItem findCardDetailById(@Param("cardId") String cardId);

	List<CardHistoryEntry> findCardHistoryFirstPage(
			@Param("cardId") String cardId,
			@Param("limit") int limit);

	List<CardHistoryEntry> findCardHistoryAfter(
			@Param("cardId") String cardId,
			@Param("cursor") CardHistoryCursor cursor,
			@Param("limit") int limit);

	long countActiveCardsByDeck(@Param("deckId") String deckId);
}
