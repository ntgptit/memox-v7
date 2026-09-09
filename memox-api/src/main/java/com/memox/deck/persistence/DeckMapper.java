package com.memox.deck.persistence;

import java.time.Instant;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.common.pagination.PageSlice;
import com.memox.deck.entity.Deck;
import com.memox.deck.entity.DeckContext;
import com.memox.deck.entity.DeckLevelRow;
import com.memox.deck.entity.DeckSummary;
import com.memox.deck.enums.DeckContentType;

@Mapper
public interface DeckMapper {

	List<Deck> findRootDecks(@Param("slice") PageSlice slice);

	long countRootDecks();

	List<DeckSummary> findRootDeckSummaries(
			@Param("slice") PageSlice slice,
			@Param("now") Instant now,
			@Param("startOfToday") Instant startOfToday);

	List<DeckLevelRow> findChildDeckLevel(
			@Param("deckId") String deckId,
			@Param("now") Instant now,
			@Param("startOfToday") Instant startOfToday,
			@Param("maxWalk") int maxWalk);

	DeckContext findDeckContext(@Param("deckId") String deckId, @Param("maxWalk") int maxWalk);

	List<Deck> findAllActiveDecks();

	List<Deck> findDecksInTree(@Param("rootDeckId") String rootDeckId);

	Deck findActiveDeckById(@Param("deckId") String deckId);

	Deck findActiveDeckByIdForUpdate(@Param("deckId") String deckId);

	int lockRootDeckCreation();

	int nextSiblingPosition(@Param("siblingScopeId") String siblingScopeId);

	void insertRootDeck(Deck deck);

	void insertSubDeck(Deck deck);

	int updateContentType(
			@Param("deckId") String deckId,
			@Param("contentType") DeckContentType contentType,
			@Param("updatedAt") Instant updatedAt);
}
