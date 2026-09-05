package com.memox.repository;

import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.deck.persistence.DeckRow;

@Mapper
public interface DeckRepository {

	String readSchemaVersion();

	List<DeckRow> findRootDecks();

	DeckRow findActiveDeckById(@Param("deckId") String deckId);

	int nextRootSiblingPosition();

	void insertRootDeck(DeckRow deck);
}
