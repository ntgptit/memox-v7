package com.memox.deck.api;

import java.net.URI;
import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.service.DeckService;

import jakarta.validation.Valid;

@Validated
@RestController
@RequestMapping("/api/v1/decks")
public class DeckController {

	private final DeckService deckService;

	public DeckController(DeckService deckService) {
		this.deckService = deckService;
	}

	@PostMapping
	public ResponseEntity<DeckResponse> createRootDeck(@Valid @RequestBody CreateRootDeckRequest request) {
		final var deck = deckService.createRootDeck(
				new CreateRootDeckCommand(request.id(), request.name(), request.schedulerType()));
		final var response = DeckResponse.from(deck);
		return ResponseEntity.created(URI.create("/api/v1/decks/" + deck.id())).body(response);
	}

	@GetMapping
	public List<DeckResponse> listRootDecks() {
		return deckService.listRootDecks().stream().map(DeckResponse::from).toList();
	}
}
