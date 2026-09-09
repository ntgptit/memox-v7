package com.memox.deck.service;

import java.time.Clock;
import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.common.pagination.PageHelper;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.deck.entity.Deck;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.entity.DeckSchedulerState;
import com.memox.deck.persistence.DeckMapper;
import com.memox.deck.persistence.DeckPositionScope;
import com.memox.common.error.ApiErrorCode;
import com.memox.deck.exception.DeckConflictException;
import com.memox.deck.exception.DeckNotFoundException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DeckService {

	private static final int INITIAL_SCHEDULER_VERSION = 1;
	private static final int INITIAL_SCHEDULER_GENERATION = 1;
	private static final int MAX_TREE_DEPTH = 10;

	private final DeckMapper deckMapper;
	private final Clock clock;

	@Transactional
	public Deck createRootDeck(CreateRootDeckCommand command) {
		deckMapper.lockRootDeckCreation();

		final var now = Instant.now(clock);
		final var deck = new Deck(command.id(), normalizeName(command.name()), null, command.id(),
				DeckContentType.DECK, command.schedulerType(), INITIAL_SCHEDULER_VERSION,
				INITIAL_SCHEDULER_GENERATION, deckMapper.nextSiblingPosition(DeckPositionScope.ROOT_DECKS), now, now);
		deckMapper.insertRootDeck(deck);
		return deck;
	}

	@Transactional
	public Deck createSubDeck(CreateSubDeckCommand command) {
		final var parent = requireActiveDeckForUpdate(command.parentDeckId());
		if (parent.contentType() == DeckContentType.CARD) {
			throw new DeckConflictException(ApiErrorCode.PARENT_HOLDS_CARDS);
		}
		if (depthOf(parent) >= MAX_TREE_DEPTH) {
			throw new DeckConflictException(ApiErrorCode.DECK_DEPTH_EXCEEDED);
		}

		final var now = Instant.now(clock);
		if (parent.contentType() == DeckContentType.UNSET) {
			deckMapper.updateContentType(parent.id(), DeckContentType.DECK, now);
		}

		final var deck = new Deck(command.id(), normalizeName(command.name()), parent.id(), parent.rootDeckId(),
				DeckContentType.UNSET, null, null, null, deckMapper.nextSiblingPosition(parent.id()), now, now);
		deckMapper.insertSubDeck(deck);
		return deck;
	}

	@Transactional(readOnly = true)
	public PagingResponse<Deck> listRootDecks(PageQuery pageQuery) {
		return PageHelper.create(pageQuery, deckMapper.findRootDecks(pageQuery), deckMapper.countRootDecks());
	}

	@Transactional(readOnly = true)
	public Deck getDeck(String deckId) {
		return requireActiveDeck(deckId);
	}

	@Transactional
	public DeckSchedulerState prepareCardCreation(String deckId) {
		final var deck = requireActiveDeckForUpdate(deckId);
		if (deck.parentDeckId() == null) {
			throw new DeckConflictException(ApiErrorCode.ROOT_CANNOT_HOLD_CARDS);
		}
		if (deck.contentType() == DeckContentType.DECK) {
			throw new DeckConflictException(ApiErrorCode.DECK_HOLDS_CHILDREN);
		}

		final var root = requireActiveDeck(deck.rootDeckId());
		if (root.schedulerType() == null || root.schedulerVersion() == null || root.schedulerGeneration() == null) {
			throw new DeckConflictException(ApiErrorCode.ROOT_SCHEDULER_INVALID);
		}
		if (deck.contentType() == DeckContentType.UNSET) {
			deckMapper.updateContentType(deck.id(), DeckContentType.CARD, Instant.now(clock));
		}
		return new DeckSchedulerState(root.schedulerType(), root.schedulerVersion(), root.schedulerGeneration());
	}

	private Deck requireActiveDeck(String deckId) {
		final var deck = deckMapper.findActiveDeckById(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}

	private Deck requireActiveDeckForUpdate(String deckId) {
		final var deck = deckMapper.findActiveDeckByIdForUpdate(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}

	private int depthOf(Deck deck) {
		int depth = 1;
		var current = deck;
		while (current.parentDeckId() != null) {
			if (depth >= MAX_TREE_DEPTH) {
				return depth;
			}
			current = requireActiveDeck(current.parentDeckId());
			depth++;
		}
		return depth;
	}

	private String normalizeName(String name) {
		return name.trim();
	}
}
