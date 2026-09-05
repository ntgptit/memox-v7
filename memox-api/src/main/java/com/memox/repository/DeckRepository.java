package com.memox.repository;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.deck.domain.DeckContentType;
import com.memox.deck.persistence.DeckRow;

@Mapper
public interface DeckRepository {

	String readSchemaVersion();

	List<DeckRow> findRootDecks();

	DeckRow findActiveDeckById(@Param("deckId") String deckId);

	int nextRootSiblingPosition();

	int nextChildSiblingPosition(@Param("parentDeckId") String parentDeckId);

	void insertRootDeck(DeckRow deck);

	void insertSubDeck(DeckRow deck);

	void updateContentType(
			@Param("deckId") String deckId,
			@Param("contentType") DeckContentType contentType,
			@Param("updatedAt") java.time.Instant updatedAt);
}
