package com.memox.card.api;

import java.net.URI;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.validation.annotation.Validated;

import com.memox.card.application.CreateCardCommand;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.pagination.PaginationConstants;
import com.memox.config.PaginationProperties;
import com.memox.service.CardService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import lombok.RequiredArgsConstructor;

@RestController
@Validated
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
	@Operation(summary = "List cards using limit and offset pagination")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Cards page returned"),
			@ApiResponse(responseCode = "400", description = "Invalid pagination parameters"),
			@ApiResponse(responseCode = "404", description = "Deck not found")
	})
	public PagingResponse<CardResponse> listCards(
			@PathVariable String deckId,
			@RequestParam(required = false) @Min(PaginationConstants.MIN_LIMIT) @Max(PaginationConstants.MAX_LIMIT) Integer limit,
			@RequestParam(required = false) @Min(PaginationConstants.MIN_OFFSET) Integer offset) {
		final var pageQuery = PageQuery.builder()
				.limit(limit == null ? paginationProperties.getDefaultLimit() : limit)
				.offset(offset == null ? paginationProperties.getDefaultOffset() : offset)
				.build();
		return cardService.listCards(deckId, pageQuery).map(CardResponse::from);
	}
}
