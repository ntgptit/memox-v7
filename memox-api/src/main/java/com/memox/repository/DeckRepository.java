package com.memox.repository;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.deck.domain.DeckContentType;
import com.memox.deck.persistence.DeckRow;
import com.memox.common.pagination.PageQuery;

@Mapper
public interface DeckRepository {

	String readSchemaVersion();

	List<DeckRow> findRootDecks(PageQuery pageQuery);

	long countActiveRootDecks();

	DeckRow findActiveDeckById(@Param("deckId") String deckId);

	DeckRow findActiveDeckByIdForUpdate(@Param("deckId") String deckId);

	int lockRootDeckCreation();

	int nextSiblingPosition(@Param("siblingScopeId") String siblingScopeId);

	void insertRootDeck(DeckRow deck);

	void insertSubDeck(DeckRow deck);

	int updateContentType(
			@Param("deckId") String deckId,
			@Param("contentType") DeckContentType contentType,
			@Param("updatedAt") java.time.Instant updatedAt);
}
