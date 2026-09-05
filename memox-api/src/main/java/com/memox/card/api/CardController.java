package com.memox.card.api;

import java.net.URI;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.memox.card.application.CreateCardCommand;
import com.memox.service.CardService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/decks/{deckId}/cards")
public class CardController {

	private final CardService cardService;

	public CardController(CardService cardService) {
		this.cardService = cardService;
	}

	@PostMapping
	public ResponseEntity<CardResponse> createCard(
			@PathVariable String deckId,
			@Valid @RequestBody CreateCardRequest request) {
		final var card = cardService.createCard(new CreateCardCommand(request.id(), deckId, request.front(),
				request.back(), request.example(), request.hint(), request.pronunciation()));
		return ResponseEntity.created(URI.create("/api/v1/cards/" + card.id())).body(CardResponse.from(card));
	}
}
