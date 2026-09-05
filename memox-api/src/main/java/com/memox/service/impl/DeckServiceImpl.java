package com.memox.service.impl;

import java.time.Clock;
import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.application.CreateSubDeckCommand;
import com.memox.deck.domain.Deck;
import com.memox.deck.domain.DeckContentType;
import com.memox.deck.persistence.DeckRow;
import com.memox.exception.DeckValidationException;
import com.memox.exception.DeckConflictException;
import com.memox.exception.DeckNotFoundException;
import com.memox.repository.DeckRepository;
import com.memox.service.DeckService;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class DeckServiceImpl implements DeckService {

	private static final int INITIAL_SCHEDULER_VERSION = 1;
	private static final int INITIAL_SCHEDULER_GENERATION = 1;
	private static final int MAX_TREE_DEPTH = 10;

	private final DeckRepository deckRepository;
	private final Clock clock;

	@Override
	@Transactional
	public Deck createRootDeck(CreateRootDeckCommand command) {
		final var name = validateName(command.name());

		final var now = Instant.now(clock);
		final var deck = DeckRow.builder()
				.id(command.id())
				.name(name)
				.rootDeckId(command.id())
				.contentType(DeckContentType.DECK.getValue())
				.schedulerType(command.schedulerType().getValue())
				.schedulerVersion(INITIAL_SCHEDULER_VERSION)
				.schedulerGeneration(INITIAL_SCHEDULER_GENERATION)
				.siblingPosition(deckRepository.nextRootSiblingPosition())
				.createdAt(now)
				.updatedAt(now)
				.build();
		deckRepository.insertRootDeck(deck);

		return deck.toDomain();
	}

	@Override
	@Transactional
	public Deck createSubDeck(CreateSubDeckCommand command) {
		final var parent = requireActiveDeck(command.parentDeckId());
		if (DeckContentType.fromValue(parent.getContentType()) == DeckContentType.CARD) {
			throw new DeckConflictException("PARENT_HOLDS_CARDS", "A card deck cannot contain child decks.");
		}
		if (depthOf(parent) >= MAX_TREE_DEPTH) {
			throw new DeckConflictException("DECK_DEPTH_EXCEEDED", "A deck tree cannot exceed 10 levels.");
		}

		final var now = Instant.now(clock);
		if (DeckContentType.fromValue(parent.getContentType()) == DeckContentType.UNSET) {
			deckRepository.updateContentType(parent.getId(), DeckContentType.DECK.getValue(), now);
		}

		final var deck = DeckRow.builder()
				.id(command.id())
				.name(validateName(command.name()))
				.parentDeckId(parent.getId())
				.rootDeckId(parent.getRootDeckId())
				.contentType(DeckContentType.UNSET.getValue())
				.siblingPosition(deckRepository.nextChildSiblingPosition(parent.getId()))
				.createdAt(now)
				.updatedAt(now)
				.build();
		deckRepository.insertSubDeck(deck);

		return deck.toDomain();
	}

	@Override
	@Transactional(readOnly = true)
	public List<Deck> listRootDecks() {
		return deckRepository.findRootDecks().stream().map(DeckRow::toDomain).toList();
	}

	@Override
	@Transactional(readOnly = true)
	public Deck getDeck(String deckId) {
		return requireActiveDeck(deckId).toDomain();
	}

	private String validateName(String rawName) {
		final var name = rawName.trim();
		if (name.isEmpty()) {
			throw new DeckValidationException("name", "DECK_NAME_REQUIRED", "Deck name must not be blank.");
		}
		if (name.length() > 200) {
			throw new DeckValidationException("name", "DECK_NAME_TOO_LONG", "Deck name must be at most 200 characters.");
		}
		return name;
	}

	private DeckRow requireActiveDeck(String deckId) {
		final var deck = deckRepository.findActiveDeckById(deckId);
		if (deck == null) {
			throw new DeckNotFoundException(deckId);
		}
		return deck;
	}

	private int depthOf(DeckRow deck) {
		var current = deck;
		var depth = 1;
		while (current.getParentDeckId() != null) {
			if (depth >= MAX_TREE_DEPTH) {
				return depth;
			}
			current = requireActiveDeck(current.getParentDeckId());
			depth++;
		}
		return depth;
	}

}
