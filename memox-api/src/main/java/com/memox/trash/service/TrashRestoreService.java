package com.memox.trash.service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.service.BulkMoveCommand;
import com.memox.card.service.CardBulkService;
import com.memox.common.error.ApiErrorCode;
import com.memox.deck.service.DeckMoveService;
import com.memox.deck.service.MoveDeckCommand;
import com.memox.trash.entity.DeleteBatch;
import com.memox.trash.entity.TrashBatchRow;
import com.memox.trash.enums.TrashItemType;
import com.memox.trash.exception.TrashConflictException;
import com.memox.trash.exception.TrashNotFoundException;
import com.memox.trash.persistence.TrashMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Reading Trash, and putting one batch back.
 *
 * <p><strong>A restore is a move, and it runs the move to prove it.</strong> BR-261 says the target
 * of a restored sub-deck must satisfy <em>exactly</em> the move's rules — depth, content type,
 * scheduler and generation of the root — and forbids a second rule set written for restore. So this
 * clears the batch's tombstones first and then calls {@code DeckMoveService.move} or
 * {@code CardBulkService.move} on rows that are active again. The rules are not re-implemented,
 * re-listed or translated; they are executed. A refusal rolls the whole transaction back, so the
 * rows go straight back to being tombstones and the failure reads as "nothing happened".
 *
 * <p>That also settles what the plan called an open question. A restored deck takes a fresh
 * {@code sibling_position} at the end of its new group — not because its old slot was taken, which
 * cannot happen (a tombstone keeps its position, and {@code nextSiblingPosition} counts tombstones),
 * but because a move always takes a fresh slot and a restore is a move.
 *
 * <p>Nothing here logs a deck name or a card face (BR-267). The list carries both to the owner in a
 * response; the log lines carry ids and counts.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TrashRestoreService {

	private final TrashMapper trashMapper;
	private final DeckMoveService deckMoveService;
	private final CardBulkService cardBulkService;
	private final Clock clock;

	/**
	 * Every deletion still in Trash, newest first.
	 *
	 * <p>A batch whose item root has vanished yields no name — neither exclusive join matched — and
	 * is dropped rather than drawn as a ghost row the user cannot act on.
	 */
	@Transactional(readOnly = true)
	public List<TrashBatchRow> list() {
		final var rows = trashMapper.findTrashBatchRows().stream()
				.filter(row -> row.itemName() != null).toList();
		log.debug("Listed {} batch(es) in Trash", rows.size());
		return rows;
	}

	/**
	 * Puts one batch back, into the target the user chose.
	 *
	 * @throws TrashNotFoundException when the batch is gone — restored elsewhere, or purged
	 * @throws TrashConflictException when the target is the wrong <em>level</em> for the item
	 * @throws com.memox.deck.exception.DeckConflictException when a move rule refuses the target
	 * @throws com.memox.card.exception.CardConflictException when a card rule refuses the target
	 */
	@Transactional
	public void restore(RestoreBatchCommand command) {
		final var batch = trashMapper.findBatchById(command.batchId());
		if (batch == null) {
			throw new TrashNotFoundException(command.batchId());
		}
		final var now = Instant.now(clock);
		if (batch.itemType() == TrashItemType.CARD) {
			restoreCard(batch, command.targetDeckId(), now);
		}
		if (batch.itemType() == TrashItemType.DECK) {
			restoreDeck(batch, command.targetDeckId(), now);
		}
		// Only once the rows are clear. Both tombstone columns cascade from this table, so deleting
		// the batch while its rows still name it would take them with it — a restore that hard-deletes
		// what it was restoring.
		trashMapper.deleteBatch(batch.id());
		log.info("Restored batch {} into target {}", batch.id(), command.targetDeckId());
	}

	private void restoreCard(DeleteBatch batch, String targetDeckId, Instant now) {
		if (targetDeckId == null) {
			// The top level holds decks, never cards (BR-58).
			throw new TrashConflictException(ApiErrorCode.RESTORE_TARGET_INVALID, batch.rootItemId());
		}
		final var cardId = trashMapper.findTombstoneCardIdInBatch(batch.rootItemId(), batch.id());
		if (cardId == null) {
			throw new TrashNotFoundException(batch.id());
		}
		trashMapper.restoreCardsInBatch(batch.id(), now);
		cardBulkService.move(new BulkMoveCommand(List.of(cardId), targetDeckId));
	}

	private void restoreDeck(DeleteBatch batch, String targetDeckId, Instant now) {
		final var deck = trashMapper.findTombstoneDeckInBatch(batch.rootItemId(), batch.id());
		if (deck == null) {
			throw new TrashNotFoundException(batch.id());
		}
		if (deck.parentDeckId() == null) {
			restoreRootDeck(batch, targetDeckId, now);
			return;
		}
		if (targetDeckId == null) {
			// Only a root may land at the top level; promoting a sub-deck would need a scheduler of
			// its own, which is a decision and not a restore.
			throw new TrashConflictException(ApiErrorCode.RESTORE_TARGET_INVALID, deck.id());
		}
		clearBatchRows(batch.id(), now);
		deckMoveService.move(new MoveDeckCommand(deck.id(), targetDeckId));
	}

	/**
	 * A root deck goes back to being a root, and there is nothing to re-parent (BR-261).
	 *
	 * <p>{@code parent_deck_id} is already null and {@code root_deck_id} already points at itself, so
	 * clearing the tombstones is the whole operation. Writing either column again would give a fact
	 * that never changed a second owner.
	 */
	private void restoreRootDeck(DeleteBatch batch, String targetDeckId, Instant now) {
		if (targetDeckId != null) {
			throw new TrashConflictException(ApiErrorCode.RESTORE_TARGET_INVALID, batch.rootItemId());
		}
		clearBatchRows(batch.id(), now);
	}

	private void clearBatchRows(String batchId, Instant now) {
		trashMapper.restoreDecksInBatch(batchId, now);
		trashMapper.restoreCardsInBatch(batchId, now);
	}
}
