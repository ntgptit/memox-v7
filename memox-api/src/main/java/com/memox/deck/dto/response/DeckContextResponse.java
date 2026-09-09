package com.memox.deck.dto.response;

import java.util.List;

import com.memox.deck.entity.DeckContext;

/** A deck's own identity and the path above it: the header of any screen opened on it. */
public record DeckContextResponse(
		String deckId,
		String deckName,
		String contentType,
		List<DeckAncestorResponse> ancestry) {

	public DeckContextResponse {
		ancestry = List.copyOf(ancestry);
	}

	public static DeckContextResponse from(DeckContext context) {
		return new DeckContextResponse(context.deckId(), context.deckName(),
				context.contentType().getValue(),
				context.ancestry().stream().map(DeckAncestorResponse::from).toList());
	}
}
