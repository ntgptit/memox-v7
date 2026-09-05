package com.memox.service.impl;

import java.time.Clock;
import java.time.Instant;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.domain.Deck;
import com.memox.deck.persistence.DeckRow;
import com.memox.exception.DeckValidationException;
import com.memox.repository.DeckRepository;
import com.memox.service.DeckService;

import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
public class DeckServiceImpl implements DeckService {

	private static final int INITIAL_SCHEDULER_VERSION = 1;
	private static final int INITIAL_SCHEDULER_GENERATION = 1;

	private final DeckRepository deckRepository;
	private final Clock clock;

	public DeckServiceImpl(DeckRepository deckRepository, Clock clock) {
		this.deckRepository = deckRepository;
		this.clock = clock;
	}

	@Override
	@Transactional
	public Deck createRootDeck(CreateRootDeckCommand command) {
		final var name = command.name().trim();
		if (name.isEmpty()) {
			throw new DeckValidationException("name", "DECK_NAME_REQUIRED", "Deck name must not be blank.");
		}
		if (name.length() > 200) {
			throw new DeckValidationException("name", "DECK_NAME_TOO_LONG", "Deck name must be at most 200 characters.");
		}

		final var now = Instant.now(clock);
		final var deck = new DeckRow();
		deck.setId(command.id());
		deck.setName(name);
		deck.setRootDeckId(command.id());
		deck.setContentType("deck");
		deck.setSchedulerType(command.schedulerType());
		deck.setSchedulerVersion(INITIAL_SCHEDULER_VERSION);
		deck.setSchedulerGeneration(INITIAL_SCHEDULER_GENERATION);
		deck.setSiblingPosition(deckRepository.nextRootSiblingPosition());
		deck.setCreatedAt(now);
		deck.setUpdatedAt(now);
		deckRepository.insertRootDeck(deck);

		return deck.toDomain();
	}

	@Override
	@Transactional(readOnly = true)
	public List<Deck> listRootDecks() {
		return deckRepository.findRootDecks().stream().map(DeckRow::toDomain).toList();
	}

}
