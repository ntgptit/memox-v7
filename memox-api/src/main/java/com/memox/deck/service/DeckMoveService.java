package com.memox.deck.service;

import java.time.Clock;
import java.time.Instant;
import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.common.error.ApiErrorCode;
import com.memox.common.persistence.AffectedRows;
import com.memox.deck.entity.Deck;
import com.memox.deck.entity.DeckMoveTarget;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.exception.DeckConflictException;
import com.memox.deck.exception.DeckNotFoundException;
import com.memox.deck.persistence.DeckMapper;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

/**
 * Moving a subtree, renaming a deck, and offering the decks a card can be moved into.
 *
 * <p><strong>Every rule here runs inside the write transaction, on rows read FOR UPDATE.</strong>
 * Depth limits, subtree containment and scheduler agreement all depend on the tree as it stands at
 * the moment of writing; checking them above the repository would put the check outside the
 * transaction and turn each one into a race against the write it guards.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DeckMoveService {

	private final DeckMapper deckMapper;
	private final DeckStructureService deckStructureService;
	private final Clock clock;

	/**
	 * Moves a deck, and everything under it, beneath another deck.
	 *
	 * <p>The checks run in a fixed order and the order is observable, so it is stated rather than
	 * left to whichever happens to be written first: <strong>depth before containment</strong>. An
	 * input can break both — moving a deck under its own descendant usually also overflows the
	 * ceiling — and the plan's own test for the depth rule used exactly such an input, which is why
	 * that test was rewritten to break only one.
	 */
	@Transactional
	public Deck move(MoveDeckCommand command) {
		final var deck = requireActiveForUpdate(command.deckId());
		final var target = requireActiveForUpdate(command.targetParentDeckId());
		if (target.contentType() == DeckContentType.CARD) {
			throw new DeckConflictException(ApiErrorCode.PARENT_HOLDS_CARDS, target.id());
		}
		if (deckStructureService.depthOf(target.id())
				+ deckStructureService.subtreeHeight(deck.id()) > DeckLimits.MAX_TREE_DEPTH) {
			throw new DeckConflictException(ApiErrorCode.DECK_DEPTH_EXCEEDED, target.id());
		}
		if (deckStructureService.subtreeDeckIds(deck.id()).contains(target.id())) {
			throw new DeckConflictException(ApiErrorCode.DECK_MOVE_INTO_OWN_SUBTREE, deck.id());
		}
		requireCompatibleRoots(deck, target);

		final var now = Instant.now(clock);
		final var oldParentId = deck.parentDeckId();
		AffectedRows.requireExactlyOne(
				deckMapper.reparentDeck(deck.id(), target.id(),
						deckMapper.nextSiblingPosition(target.id()), now),
				() -> new IllegalStateException("locked deck vanished mid-move: " + deck.id()));
		if (!Objects.equals(deck.rootDeckId(), target.rootDeckId())) {
			deckMapper.updateSubtreeRootDeck(deck.id(), target.rootDeckId(), now);
		}
		maintainContentTypes(oldParentId, target, now);

		log.info("Moved deck {} from {} to {} in root {}",
				deck.id(), oldParentId, target.id(), target.rootDeckId());
		return requireActiveForUpdate(deck.id());
	}

	@Transactional
	public Deck rename(RenameDeckCommand command) {
		final var deck = requireActiveForUpdate(command.deckId());
		final var now = Instant.now(clock);
		AffectedRows.requireExactlyOne(
				deckMapper.updateDeckName(deck.id(), command.name().trim(), now),
				() -> new IllegalStateException("locked deck vanished mid-rename: " + deck.id()));
		log.info("Renamed deck {}", deck.id());
		return requireActiveForUpdate(deck.id());
	}

	@Transactional(readOnly = true)
	public List<DeckMoveTarget> listCardMoveTargets(String rootDeckId, String sourceDeckId) {
		final var targets = deckMapper.findCardMoveTargets(rootDeckId, sourceDeckId);
		log.debug("Offered {} card move target(s) in root {}", targets.size(), rootDeckId);
		return targets;
	}

	/**
	 * BR-73/74: a move across roots is refused when the schedulers disagree, never converted.
	 *
	 * <p>Type, version and generation are three separate answers because they fail for three
	 * different reasons — a different algorithm, a different revision of it, and a reset that
	 * happened on one side only. Silently adopting the destination's scheduler would rewrite every
	 * moved card's schedule without the user asking.
	 */
	private void requireCompatibleRoots(Deck deck, Deck target) {
		if (Objects.equals(deck.rootDeckId(), target.rootDeckId())) {
			return;
		}
		final var sourceRoot = requireActive(deck.rootDeckId());
		final var targetRoot = requireActive(target.rootDeckId());
		if (sourceRoot.schedulerType() != targetRoot.schedulerType()
				|| !Objects.equals(sourceRoot.schedulerVersion(), targetRoot.schedulerVersion())) {
			throw new DeckConflictException(ApiErrorCode.DECK_CROSS_ROOT_MOVE, targetRoot.id());
		}
		if (!Objects.equals(sourceRoot.schedulerGeneration(), targetRoot.schedulerGeneration())) {
			throw new DeckConflictException(ApiErrorCode.SCHEDULER_GENERATION_MISMATCH, targetRoot.id());
		}
	}

	/**
	 * BR-163 and BR-260, both in the same transaction as the move that caused them.
	 *
	 * <p>The old parent falls back to {@code unset} when the move took its last active child, and
	 * the new parent commits to holding decks the moment it receives one. Neither is a manual step;
	 * a deck whose type disagrees with its contents is a state the rules do not allow to exist.
	 */
	private void maintainContentTypes(String oldParentId, Deck target, Instant now) {
		if (oldParentId != null && deckStructureService.directChildDeckCount(oldParentId) == 0) {
			deckMapper.updateContentType(oldParentId, DeckContentType.UNSET, now);
			log.info("Deck {} lost its last sub-deck and is unset again", oldParentId);
		}
		if (target.contentType() == DeckContentType.UNSET) {
			AffectedRows.requireExactlyOne(
					deckMapper.updateContentType(target.id(), DeckContentType.DECK, now),
					() -> new IllegalStateException("locked target vanished mid-move: " + target.id()));
			log.info("Deck {} now holds sub-decks", target.id());
		}
	}

	private Deck requireActive(String deckId) {
		final var deck = deckMapper.findActiveDeckById(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}

	private Deck requireActiveForUpdate(String deckId) {
		final var deck = deckMapper.findActiveDeckByIdForUpdate(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}
}
