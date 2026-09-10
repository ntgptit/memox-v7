package com.memox.card.dto.response;

import java.util.List;

import com.memox.card.entity.DeckExport;

/**
 * One export: the deck name the file is named after (BR-180), and the cards in BR-177's order.
 *
 * <p>The order is the contract, not a convenience — the same deck must produce the same content
 * every time — so a client must write the cards in the order they arrive rather than re-sorting.
 */
public record ExportResponse(String deckName, List<ExportCardResponse> cards) {

	public ExportResponse {
		cards = List.copyOf(cards);
	}

	public static ExportResponse from(DeckExport export) {
		return new ExportResponse(export.deckName(),
				export.cards().stream().map(ExportCardResponse::from).toList());
	}
}
