package com.memox.deck.controller;

import java.net.URI;
import java.time.Clock;
import java.util.List;

import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.memox.deck.service.CreateRootDeckCommand;
import com.memox.deck.service.CreateSubDeckCommand;
import com.memox.deck.enums.SchedulerType;
import com.memox.common.pagination.PagingResponse;
import com.memox.common.config.PaginationProperties;
import com.memox.common.time.DayWindow;
import com.memox.deck.service.DeckService;
import com.memox.deck.exception.DeckNotFoundException;
import com.memox.deck.service.DeckTreeService;
import com.memox.deck.service.ReorderDeckCommand;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;

import jakarta.validation.Valid;

import lombok.RequiredArgsConstructor;
import com.memox.deck.dto.request.CreateRootDeckRequest;
import com.memox.deck.dto.request.CreateSubDeckRequest;
import com.memox.deck.dto.request.DeckPageRequest;
import com.memox.deck.dto.request.ReorderDeckRequest;
import com.memox.deck.dto.response.DeckResponse;
import com.memox.deck.dto.response.DeckLevelResponse;
import com.memox.deck.dto.response.DeckSummaryResponse;

@RestController
@RequestMapping("/api/v1/decks")
@RequiredArgsConstructor
@Tag(name = "Decks")
public class DeckController {

	private final DeckService deckService;
	private final DeckTreeService deckTreeService;
	private final PaginationProperties paginationProperties;
	private final Clock clock;

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
	@Operation(summary = "List root decks using zero-based page and size pagination")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Root deck page returned"),
			@ApiResponse(responseCode = "400", description = "Invalid pagination or sort parameters")
	})
	public PagingResponse<DeckResponse> listRootDecks(@Valid @ParameterObject DeckPageRequest request) {
		final var pageQuery = request.toPageQuery(
				paginationProperties.getDefaultPage(), paginationProperties.getDefaultSize());
		return deckService.listRootDecks(pageQuery).map(DeckResponse::from);
	}

	@GetMapping("/summaries")
	@Operation(summary = "List root decks with their aggregate card counts")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Root deck summary page returned"),
			@ApiResponse(responseCode = "400", description = "Invalid pagination, sort or UTC offset")
	})
	public PagingResponse<DeckSummaryResponse> listRootSummaries(
			@Valid @ParameterObject DeckPageRequest request,
			@RequestHeader(value = DayWindow.OFFSET_HEADER, required = false, defaultValue = "0")
			int utcOffsetMinutes) {
		final var pageQuery = request.toPageQuery(
				paginationProperties.getDefaultPage(), paginationProperties.getDefaultSize());
		final var window = DayWindow.of(clock, utcOffsetMinutes);
		return deckTreeService.listRootSummaries(pageQuery, window.now(), window.startOfDay())
				.map(DeckSummaryResponse::from);
	}

	@GetMapping("/{rootDeckId}/tree")
	@Operation(summary = "List every deck in one root's tree, the root included")
	@ApiResponses(@ApiResponse(responseCode = "200", description = "Tree returned"))
	public List<DeckResponse> listTree(@PathVariable String rootDeckId) {
		return deckTreeService.listTree(rootDeckId).stream().map(DeckResponse::from).toList();
	}

	/**
	 * PUT rather than POST: a reorder sets a sub-resource to a value, and sending the same target
	 * twice leaves the group in the same order. The plan named the request type but never the
	 * endpoint; this is the choice, recorded there too.
	 */
	@PutMapping("/{deckId}/position")
	@Operation(summary = "Move a deck to a new position among its siblings")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "The sibling group in its new order"),
			@ApiResponse(responseCode = "400", description = "Target position outside the sibling group"),
			@ApiResponse(responseCode = "404", description = "Deck not found")
	})
	public List<DeckResponse> reorderDeck(
			@PathVariable String deckId,
			@Valid @RequestBody ReorderDeckRequest request) {
		return deckService.reorderDeck(new ReorderDeckCommand(deckId, request.targetPosition()))
				.stream().map(DeckResponse::from).toList();
	}

	@GetMapping("/{deckId}/level")
	@Operation(summary = "Open a deck: its breadcrumb, its direct children and their subtree counts")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Level returned"),
			@ApiResponse(responseCode = "400", description = "Invalid UTC offset"),
			@ApiResponse(responseCode = "404", description = "Deck not found")
	})
	public DeckLevelResponse readLevel(
			@PathVariable String deckId,
			@RequestHeader(value = DayWindow.OFFSET_HEADER, required = false, defaultValue = "0")
			int utcOffsetMinutes) {
		final var window = DayWindow.of(clock, utcOffsetMinutes);
		final var level = deckTreeService.readLevel(deckId, window.now(), window.startOfDay());
		if (level == null) {
			throw new DeckNotFoundException(deckId);
		}
		return DeckLevelResponse.from(level);
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
