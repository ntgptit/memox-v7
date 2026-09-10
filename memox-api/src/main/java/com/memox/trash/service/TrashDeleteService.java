package com.memox.trash.service;

import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.exception.CardNotFoundException;
import com.memox.common.persistence.IdCollections;
import com.memox.deck.entity.Deck;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.service.DeckService;
import com.memox.deck.service.DeckStructureService;
import com.memox.study.service.StudySessionInvalidationService;
import com.memox.trash.entity.DeleteBatch;
import com.memox.trash.enums.TrashItemType;
import com.memox.trash.persistence.TrashMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Soft-delete: a deck subtree, or a batch of cards.
 *
 * <p>Nothing is ever hard-deleted here (BR-256). Every row keeps its id, its content, its study
 * state, its history and its tag links; what changes is that it leaves every active surface in the
 * same instant (BR-257, BR-259), and the user gets thirty days to change their mind.
 *
 * <p><strong>The order inside each method is load-bearing.</strong> Read the ids first, because a
 * tombstone is invisible to the reads that gather them; count the emptied parent afterwards,
 * because that count has to describe the tree the deletion leaves behind. Split across two
 * transactions they would describe two different databases.
 *
 * <p><strong>BR-259's session invalidation runs here, and where it sits in the method is the
 * rule.</strong> A session in progress that touches deleted content is closed with
 * {@code status = invalidated} and {@code end_reason = content_deleted}, inside this transaction and
 * <em>before</em> the rows are marked — the lookups take the id sets this deletion has already
 * decided on, and those ids have to still describe live rows. The write itself belongs to the study
 * module, because the status × end-reason pair is that module's invariant and Trash may not write it
 * behind its back; Trash asks for a verb and the verb owns both columns.
 *
 * <p>Nothing here logs a deck name or a card face, on any path (BR-267).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TrashDeleteService {

	private static final String CARD_IDS = "cardIds";

	private final TrashMapper trashMapper;
	private final StudySessionInvalidationService studySessionInvalidationService;
	private final DeckService deckService;
	private final DeckStructureService deckStructureService;
	private final Clock clock;

	/**
	 * Moves a deck and every active descendant into one batch (BR-258).
	 *
	 * <p>A descendant already in Trash under an older batch keeps that batch and is not absorbed, so
	 * restoring this one leaves it exactly where it is. That is a property of the statements — both
	 * the subtree read and the marking filter on {@code delete_batch_id IS NULL} — rather than of a
	 * check somewhere above them.
	 *
	 * @throws com.memox.deck.exception.DeckNotFoundException when no active deck carries the id
	 */
	@Transactional
	public DeleteBatch deleteDeck(DeleteDeckCommand command) {
		final var deck = deckService.lockActiveDeck(command.deckId());
		final var deckIds = trashMapper.findActiveSubtreeDeckIds(command.deckId());
		final var cardIds = trashMapper.findActiveCardIdsInDecks(deckIds);

		// BR-259, before the marking and on the same instant the batch will carry. Both id sets: a
		// session opened on one of these decks, and a session reviewing the whole root whose queue
		// happens to hold one of these cards.
		final var now = Instant.now(clock);
		studySessionInvalidationService.invalidateForDeletedContent(deckIds, cardIds, now);

		final var batch = openBatch(TrashItemType.DECK, command.deckId(), now);
		requireMarkedAll(trashMapper.markDecksDeleted(deckIds, batch.id(), batch.deletedAt()),
				deckIds, "decks");
		markCardsIfAny(cardIds, batch);

		unsetIfEmptied(deck.parentDeckId());
		log.info("Deleted deck {} into batch {}: {} deck(s), {} card(s)",
				command.deckId(), batch.id(), deckIds.size(), cardIds.size());
		return batch;
	}

	/**
	 * Moves a batch of cards into one batch <em>each</em> (BR-256).
	 *
	 * <p>The item root is singular. Someone who deletes fifty cards may want three of them back, and
	 * a shared batch could only offer that through a partial restore that BR-262 does not have — it
	 * revives exactly the rows carrying the batch id. One action, one instant, many batches.
	 *
	 * @throws CardNotFoundException when an id names no active card; nothing is written
	 */
	@Transactional
	public List<DeleteBatch> deleteCards(DeleteCardsCommand command) {
		final var cardIds = IdCollections.requireUsableBatch(command.cardIds(), CARD_IDS);
		requireAllActive(cardIds);
		final var sourceDeckIds = trashMapper.findSourceDeckIdsOfActiveCards(cardIds);

		final var now = Instant.now(clock);
		// Once for the whole selection, before the first batch is opened (BR-259). Fifty cards is
		// one lookup and however many sessions it touches, not fifty of each — and moving it after
		// the loop would break the close-before-mark order for every card but the last.
		studySessionInvalidationService.invalidateForDeletedContent(List.of(), cardIds, now);

		final var batches = new ArrayList<DeleteBatch>(cardIds.size());
		for (final var cardId : cardIds) {
			final var batch = new DeleteBatch(
					UUID.randomUUID().toString(), TrashItemType.CARD, cardId, now);
			trashMapper.insertDeleteBatch(batch);
			requireMarkedAll(trashMapper.markCardsDeleted(List.of(cardId), batch.id(), now),
					List.of(cardId), "cards");
			batches.add(batch);
		}

		sourceDeckIds.forEach(this::unsetIfEmptied);
		log.info("Deleted {} card(s) into {} batch(es)", cardIds.size(), batches.size());
		return batches;
	}

	private DeleteBatch openBatch(TrashItemType itemType, String rootItemId, Instant now) {
		final var batch = new DeleteBatch(UUID.randomUUID().toString(), itemType, rootItemId, now);
		trashMapper.insertDeleteBatch(batch);
		return batch;
	}

	private void markCardsIfAny(List<String> cardIds, DeleteBatch batch) {
		if (cardIds.isEmpty()) {
			return;
		}
		requireMarkedAll(trashMapper.markCardsDeleted(cardIds, batch.id(), batch.deletedAt()),
				cardIds, "cards");
	}

	/**
	 * A short count is a bug, not a race.
	 *
	 * <p>The ids were read inside this transaction from rows that were active then, so a row that
	 * refuses the stamp means the batch would claim rows it does not hold — a Trash entry whose
	 * restore brings back less than it says. Rolling back is the only honest answer.
	 */
	private void requireMarkedAll(int marked, Collection<String> ids, String table) {
		if (marked == ids.size()) {
			return;
		}
		throw new IllegalStateException("a deletion marked " + marked + " of " + ids.size()
				+ " " + table + " it had already read as active");
	}

	private void requireAllActive(List<String> cardIds) {
		final var active = new HashSet<>(trashMapper.findActiveCardIds(cardIds));
		final var missing = cardIds.stream().filter(id -> !active.contains(id)).findFirst();
		if (missing.isEmpty()) {
			return;
		}
		throw new CardNotFoundException(missing.get());
	}

	/**
	 * BR-260: a non-root deck that just lost its last <em>active</em> direct child drops to unset.
	 *
	 * <p>A tombstone still sitting in the deck is not content, which is why both counts filter it
	 * out. The root is exempt: it holds sub-decks forever, even when it holds none right now
	 * (BR-58).
	 */
	private void unsetIfEmptied(String deckId) {
		if (deckId == null) {
			return;
		}
		final var parent = deckService.lockActiveDeck(deckId);
		if (isRoot(parent) || parent.contentType() == DeckContentType.UNSET) {
			return;
		}
		if (deckStructureService.directChildDeckCount(deckId) > 0
				|| deckStructureService.directCardCount(deckId) > 0) {
			return;
		}
		deckService.markContentType(deckId, DeckContentType.UNSET);
	}

	private boolean isRoot(Deck deck) {
		return deck.parentDeckId() == null;
	}
}
