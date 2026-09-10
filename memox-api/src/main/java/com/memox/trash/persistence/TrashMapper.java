package com.memox.trash.persistence;

import java.time.Instant;
import java.util.Collection;
import java.util.List;

import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import com.memox.trash.entity.DeleteBatch;
import com.memox.trash.entity.TombstoneDeck;
import com.memox.trash.entity.TrashBatchRow;

/**
 * The tombstone columns on {@code decks} and {@code cards}, plus {@code delete_batches}.
 *
 * <p>This mapper reads and writes two other modules' tables, and that is the design rather than a
 * shortcut: a tombstone is not deck state or card state, it is the delete batch's claim on a row.
 * Keeping every statement that can see a tombstone in one file is what makes AD-22's allowlist
 * short enough to audit.
 */
@Mapper
public interface TrashMapper {

	void insertDeleteBatch(DeleteBatch batch);

	List<String> findActiveSubtreeDeckIds(@Param("deckId") String deckId);

	List<String> findActiveCardIdsInDecks(@Param("deckIds") Collection<String> deckIds);

	List<String> findActiveCardIds(@Param("cardIds") Collection<String> cardIds);

	List<String> findSourceDeckIdsOfActiveCards(@Param("cardIds") Collection<String> cardIds);

	int markDecksDeleted(
			@Param("deckIds") Collection<String> deckIds,
			@Param("batchId") String batchId,
			@Param("updatedAt") Instant updatedAt);

	int markCardsDeleted(
			@Param("cardIds") Collection<String> cardIds,
			@Param("batchId") String batchId,
			@Param("updatedAt") Instant updatedAt);

	List<TrashBatchRow> findTrashBatchRows();

	/** @return the batch, or {@code null} when it has been restored or purged */
	DeleteBatch findBatchById(@Param("batchId") String batchId);

	TombstoneDeck findTombstoneDeckInBatch(
			@Param("deckId") String deckId, @Param("batchId") String batchId);

	String findTombstoneCardIdInBatch(
			@Param("cardId") String cardId, @Param("batchId") String batchId);

	int restoreDecksInBatch(@Param("batchId") String batchId, @Param("updatedAt") Instant updatedAt);

	int restoreCardsInBatch(@Param("batchId") String batchId, @Param("updatedAt") Instant updatedAt);

	int deleteBatch(@Param("batchId") String batchId);
}
