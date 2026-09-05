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
import com.memox.service.CardService;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import lombok.RequiredArgsConstructor;

@RestController
@Validated
@RequestMapping("/api/v1/decks/{deckId}/cards")
@RequiredArgsConstructor
public class CardController {

	private final CardService cardService;

	@PostMapping
	public ResponseEntity<CardResponse> createCard(
			@PathVariable String deckId,
			@Valid @RequestBody CreateCardRequest request) {
		final var card = cardService.createCard(new CreateCardCommand(request.id(), deckId, request.front(),
				request.back(), request.example(), request.hint(), request.pronunciation()));
		return ResponseEntity.created(URI.create("/api/v1/cards/" + card.id())).body(CardResponse.from(card));
	}

	@GetMapping
	public PagingResponse<CardResponse> listCards(
			@PathVariable String deckId,
			@RequestParam(defaultValue = "${memox.pagination.default-limit}")
			@Min(PaginationConstants.MIN_LIMIT) @Max(PaginationConstants.MAX_LIMIT) int limit,
			@RequestParam(defaultValue = "${memox.pagination.default-offset}")
			@Min(PaginationConstants.MIN_OFFSET) int offset) {
		final var pageQuery = PageQuery.builder().limit(limit).offset(offset).build();
		return cardService.listCards(deckId, pageQuery).map(CardResponse::from);
	}
}
