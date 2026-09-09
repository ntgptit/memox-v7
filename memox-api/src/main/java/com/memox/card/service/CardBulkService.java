package com.memox.card.service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.card.entity.CardDeckContext;
import com.memox.card.exception.CardConflictException;
import com.memox.card.exception.CardNotFoundException;
import com.memox.card.persistence.CardMapper;
import com.memox.common.error.ApiErrorCode;
import com.memox.common.persistence.IdCollections;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.entity.Deck;
import com.memox.deck.service.DeckService;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Batch operations over cards: move them, or set their flag.
 *
 * <p>Nothing here logs a card face (BR-51, BR-52) — batches are reported by count and by deck id.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class CardBulkService {

	private static final String CARD_IDS = "cardIds";

	private final CardMapper cardMapper;
	private final DeckService deckService;

	private final Clock clock;

	/**
	 * Moves a batch of cards into one deck, or moves none of them.
	 *
	 * <p>All the rules run inside this transaction on rows the target read locked, because each of
	 * them depends on the tree as it stands at the moment of writing:
	 *
	 * <ul>
	 *   <li>the target must exist, must not be a root, and must not already hold sub-decks — a root
	 *       never holds cards, and a deck holds one kind of thing (BR-165);</li>
	 *   <li>every card must exist and be active — a trashed card simply does not come back from the
	 *       context read, which is how one hiding in the batch is noticed;</li>
	 *   <li>every card must share the target's root (BR-166). One that does not rolls the whole
	 *       batch back rather than moving the rest, because a half-applied move is a state the user
	 *       never asked for and cannot see.</li>
	 * </ul>
	 *
	 * <p>Content types are then maintained for <em>every</em> source deck the batch emptied, not
	 * just one: a selection can span several decks, and each of them falls back to {@code unset}
	 * when its last card leaves (BR-163).
	 *
	 * @return how many cards moved
	 */
	@Transactional
	public int move(BulkMoveCommand command) {
		final var cardIds = IdCollections.requireUsableBatch(command.cardIds(), CARD_IDS);
		final var target = deckService.lockActiveDeck(command.targetDeckId());
		if (target.parentDeckId() == null || target.contentType() == DeckContentType.DECK) {
			throw new CardConflictException(ApiErrorCode.MOVE_TARGET_INVALID, target.id());
		}

		final var contexts = requireEveryCard(cardIds);
		for (final CardDeckContext context : contexts) {
			if (!Objects.equals(context.rootDeckId(), target.rootDeckId())) {
				throw new CardConflictException(ApiErrorCode.CARD_CROSS_ROOT_MOVE, context.cardId());
			}
		}

		final var now = Instant.now(clock);
		final var moved = cardMapper.moveCardsToDeck(cardIds, target.id(), now);
		maintainContentTypes(sourceDeckIds(contexts, target.id()), target);
		log.info("Moved {} card(s) into deck {}", moved, target.id());
		return moved;
	}

	/**
	 * Sets the flag on a batch of cards to one state.
	 *
	 * <p>No deck rules apply: flagging does not move a card and does not change what a deck holds.
	 *
	 * @return how many cards were written
	 */
	@Transactional
	public int setFlag(BulkFlagCommand command) {
		final var cardIds = IdCollections.requireUsableBatch(command.cardIds(), CARD_IDS);
		final var written = cardMapper.setCardsFlagByIds(cardIds, command.flagged(), Instant.now(clock));
		log.info("Set the flag to {} on {} card(s)", command.flagged(), written);
		return written;
	}

	/**
	 * Reads the whole batch's context and refuses the request if any card is missing.
	 *
	 * <p>A trashed card does not come back from the statement, so comparing what returned against
	 * what was asked for is the same check for "never existed" and "is in Trash" — which is what
	 * BR-245 wants them to look like from outside.
	 */
	private List<CardDeckContext> requireEveryCard(List<String> cardIds) {
		final var contexts = cardMapper.findCardDeckContextForIds(cardIds);
		if (contexts.size() == cardIds.size()) {
			return contexts;
		}
		final var found = contexts.stream().map(CardDeckContext::cardId).collect(Collectors.toSet());
		final var missing = cardIds.stream().filter(id -> !found.contains(id)).findFirst();
		throw new CardNotFoundException(missing.orElse(CARD_IDS));
	}

	private Set<String> sourceDeckIds(List<CardDeckContext> contexts, String targetDeckId) {
		return contexts.stream()
				.map(CardDeckContext::deckId)
				.filter(deckId -> !deckId.equals(targetDeckId))
				.collect(Collectors.toUnmodifiableSet());
	}

	/**
	 * Whether a deck just lost its last card is a fact only this module can count; writing what a
	 * deck holds belongs to the deck module. So the count happens here and the write goes through
	 * DeckService, rather than this service reaching into deck persistence.
	 */
	private void maintainContentTypes(Set<String> sourceDeckIds, Deck target) {
		for (final String sourceDeckId : sourceDeckIds) {
			if (cardMapper.countActiveCardsByDeck(sourceDeckId) == 0) {
				deckService.markContentType(sourceDeckId, DeckContentType.UNSET);
			}
		}
		if (target.contentType() == DeckContentType.UNSET) {
			deckService.markContentType(target.id(), DeckContentType.CARD);
		}
	}
}
