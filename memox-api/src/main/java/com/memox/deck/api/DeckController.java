package com.memox.deck.api;

import java.net.URI;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.application.CreateSubDeckCommand;
import com.memox.service.DeckService;

import jakarta.validation.Valid;

import lombok.RequiredArgsConstructor;

@Validated
@RestController
@RequestMapping("/api/v1/decks")
@RequiredArgsConstructor
public class DeckController {

	private final DeckService deckService;

	@PostMapping
	public ResponseEntity<DeckResponse> createRootDeck(@Valid @RequestBody CreateRootDeckRequest request) {
		final var deck = deckService.createRootDeck(
				new CreateRootDeckCommand(request.id(), request.name(), request.schedulerType()));
		final var response = DeckResponse.from(deck);
		return ResponseEntity.created(URI.create("/api/v1/decks/" + deck.id())).body(response);
	}

	@PostMapping("/{parentDeckId}/children")
	public ResponseEntity<DeckResponse> createSubDeck(
			@PathVariable String parentDeckId,
			@Valid @RequestBody CreateSubDeckRequest request) {
		final var deck = deckService.createSubDeck(
				new CreateSubDeckCommand(request.id(), request.name(), parentDeckId));
		final var response = DeckResponse.from(deck);
		return ResponseEntity.created(URI.create("/api/v1/decks/" + deck.id())).body(response);
	}

	@GetMapping
	public List<DeckResponse> listRootDecks() {
		return deckService.listRootDecks().stream().map(DeckResponse::from).toList();
	}

	@GetMapping("/{deckId}")
	public DeckResponse getDeck(@PathVariable String deckId) {
		return DeckResponse.from(deckService.getDeck(deckId));
	}
}
