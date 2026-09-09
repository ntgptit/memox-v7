package com.memox.deck.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.memox.deck.entity.DeckMoveTarget;

/**
 * One deck a card may be moved into.
 *
 * <p>{@code parentName} is what makes a flat picker usable: two lessons both called "Unit 1" under
 * different units are indistinguishable without it.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record DeckMoveTargetResponse(
		String deckId,
		String deckName,
		String contentType,
		String parentName) {

	public static DeckMoveTargetResponse from(DeckMoveTarget target) {
		return new DeckMoveTargetResponse(target.deckId(), target.deckName(),
				target.contentType().getValue(), target.parentName());
	}
}
