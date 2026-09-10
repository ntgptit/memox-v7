package com.memox.card.controller;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.memox.card.dto.request.ExportSelectionRequest;
import com.memox.card.dto.response.CardKeyResponse;
import com.memox.card.dto.response.ExportResponse;
import com.memox.card.service.CardExportService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

/**
 * The data a card export is made of, and the duplicate probe an import runs first.
 *
 * <p>Its own controller rather than a third block in {@code CardController}, whose class-level path
 * is a deck's <em>cards</em>: an export is of the deck, and its file is named after the deck
 * (BR-180). It publishes data, never a file — writing one is the client's job, and BR-180's date
 * has to come from the client's own clock.
 */
@RestController
@RequestMapping("/api/v1/decks/{deckId}")
@RequiredArgsConstructor
@Tag(name = "Cards")
public class CardExportController {

	private final CardExportService cardExportService;

	@GetMapping("/export")
	@Operation(summary = "Every card held directly by one deck, in the export's order")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Export data returned"),
			@ApiResponse(responseCode = "404", description = "Deck not found, or in Trash"),
			@ApiResponse(responseCode = "409", description = "The deck holds no active card")
	})
	public ExportResponse exportDeck(@PathVariable String deckId) {
		return ExportResponse.from(cardExportService.exportDeck(deckId));
	}

	/**
	 * Scope {@code selected}, as a POST although it writes nothing (BR-178).
	 *
	 * <p>The selection is up to 500 ids, which does not fit a query string on any client. The verb
	 * describes how the request is carried, not what it does — nothing here is mutated, and a
	 * successful export must not even clear the selection it was given.
	 */
	@PostMapping("/export")
	@Operation(summary = "Exactly the selected cards of one deck, or none of them")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Export data returned"),
			@ApiResponse(responseCode = "400", description = "Empty selection, or more than 500 ids"),
			@ApiResponse(responseCode = "404", description = "Deck not found, or in Trash"),
			@ApiResponse(responseCode = "409", description = "A selected card is no longer in this deck")
	})
	public ExportResponse exportSelected(
			@PathVariable String deckId,
			@Valid @RequestBody ExportSelectionRequest request) {
		return ExportResponse.from(cardExportService.exportCards(deckId, request.cardIds()));
	}

	@GetMapping("/card-keys")
	@Operation(summary = "The duplicate identities already in one deck, for an import preview")
	@ApiResponses({
			@ApiResponse(responseCode = "200", description = "Keys returned"),
			@ApiResponse(responseCode = "404", description = "Deck not found, or in Trash")
	})
	public List<CardKeyResponse> cardKeys(@PathVariable String deckId) {
		return cardExportService.existingKeys(deckId).stream().map(CardKeyResponse::from).toList();
	}
}
