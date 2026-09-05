package com.memox.deck.api;

import java.net.URI;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.application.CreateSubDeckCommand;
import com.memox.deck.domain.SchedulerType;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.pagination.PaginationConstants;
import com.memox.config.PaginationProperties;
import com.memox.service.DeckService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import lombok.RequiredArgsConstructor;

@Validated
@RestController
@RequestMapping("/api/v1/decks")
@RequiredArgsConstructor
@Tag(name = "Decks")
public class DeckController {

	private final DeckService deckService;
	private final PaginationProperties paginationProperties;

	@PostMapping
	@Operation(summary = "Create a root deck")
	@ApiResponses({
			@ApiResponse(responseCode = "201", description = "Root deck created"),
			@ApiResponse(responseCode = "400", description = "Invalid request"),
			@ApiResponse(responseCode = "409", description = "Data conflict")
	})
	public ResponseEntity<DeckResponse> createRootDeck(@Valid @RequestBody CreateRootDeckRequest request) {
		final var deck = deckService.createRootDeck(
				new CreateRootDeckCommand(request.id(), request.name(), SchedulerType.fromValue(request.schedulerType())));
		final var response = DeckResponse.from(deck);
		return ResponseEntity.created(URI.create("/api/v1/decks/" + deck.id())).body(response);
	}

	@PostMapping("/{parentDeckId}/children")
	@Operation(summary = "Create a child deck")
	@ApiResponses({
			@ApiResponse(responseCode = "201", description = "Child deck created"),
			@ApiResponse(responseCode = "404", description = "Parent deck not found"),
			@ApiResponse(responseCode = "409", description = "Deck content or depth conflict")
	})
	public ResponseEntity<DeckResponse> createSubDeck(
			@PathVariable String parentDeckId,
			@Valid @RequestBody CreateSubDeckRequest request) {
		final var deck = deckService.createSubDeck(
				new CreateSubDeckCommand(request.id(), request.name(), parentDeckId));
		final var response = DeckResponse.from(deck);
		return ResponseEntity.created(URI.create("/api/v1/decks/" + deck.id())).body(response);
	}

	@GetMapping
	@Operation(summary = "List root decks")
	public PagingResponse<DeckResponse> listRootDecks(
			@RequestParam(required = false) @Min(PaginationConstants.MIN_LIMIT) @Max(PaginationConstants.MAX_LIMIT) Integer limit,
			@RequestParam(required = false) @Min(PaginationConstants.MIN_OFFSET) Integer offset) {
		final var pageQuery = PageQuery.builder()
				.limit(limit == null ? paginationProperties.getDefaultLimit() : limit)
				.offset(offset == null ? paginationProperties.getDefaultOffset() : offset)
				.build();
		return deckService.listRootDecks(pageQuery).map(DeckResponse::from);
	}

	@GetMapping("/{deckId}")
	@Operation(summary = "Get a deck")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Deck found"),
			@ApiResponse(responseCode = "404", description = "Deck not found")
	})
	public DeckResponse getDeck(@PathVariable String deckId) {
		return DeckResponse.from(deckService.getDeck(deckId));
	}
}
