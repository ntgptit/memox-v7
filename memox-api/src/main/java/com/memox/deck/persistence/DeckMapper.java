package com.memox.deck.persistence;

import java.time.Instant;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.common.pagination.PageQuery;
import com.memox.deck.entity.Deck;
import com.memox.deck.enums.DeckContentType;

@Mapper
public interface DeckMapper {

	String readSchemaVersion();

	List<Deck> findRootDecks(PageQuery pageQuery);

	long countRootDecks();

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
