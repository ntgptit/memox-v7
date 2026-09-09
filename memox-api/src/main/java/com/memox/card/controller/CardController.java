package com.memox.card.controller;

import java.net.URI;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.memox.card.service.CardService;
import com.memox.card.service.CreateCardCommand;
import com.memox.common.config.PaginationProperties;
import com.memox.common.pagination.PagingResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import com.memox.card.dto.request.CardPageRequest;
import com.memox.card.dto.request.CreateCardRequest;
import com.memox.card.dto.response.CardResponse;

@RestController
@RequestMapping("/api/v1/decks/{deckId}/cards")
@RequiredArgsConstructor
@Tag(name = "Cards")
public class CardController {

	private final CardService cardService;
	private final PaginationProperties paginationProperties;

	@PostMapping
	@Operation(summary = "Create a card in a deck")
	@ApiResponses({
		@ApiResponse(responseCode = "201", description = "Card created"),
		@ApiResponse(responseCode = "404", description = "Deck not found"),
		@ApiResponse(responseCode = "409", description = "Deck content conflict")
	})
	public ResponseEntity<CardResponse> createCard(
			@PathVariable String deckId,
			@Valid @RequestBody CreateCardRequest request) {
		final var card = cardService.createCard(new CreateCardCommand(request.id(), deckId, request.front(),
				request.back(), request.example(), request.hint(), request.pronunciation()));
		return ResponseEntity.created(URI.create("/api/v1/cards/" + card.id())).body(CardResponse.from(card));
	}

	@GetMapping
	@Operation(summary = "List cards using zero-based page and size pagination")
	@ApiResponses({
		@ApiResponse(responseCode = "200", description = "Cards page returned"),
		@ApiResponse(responseCode = "400", description = "Invalid pagination or sort parameters"),
		@ApiResponse(responseCode = "404", description = "Deck not found")
	})
	public PagingResponse<CardResponse> listCards(
			@PathVariable String deckId,
			@Valid @ParameterObject CardPageRequest request) {
		final var pageQuery = request.toPageQuery(
				paginationProperties.getDefaultPage(), paginationProperties.getDefaultSize());
		return cardService.listCards(deckId, pageQuery).map(CardResponse::from);
	}
}
