package com.memox.tag.service;

import java.util.List;

/**
 * Attach one tag to a batch of cards (BR-166).
 *
 * <p>A batch even for one card: the single-card path in the Flutter repository is literally
 * {@code addTagToCards([cardId])}, and BR-166's rules — reuse by folded name, the ten-tag ceiling,
 * idempotence — are the single-card rules applied to a list. Two entry points would be two places
 * for those three rules to drift apart.
 */
public record AttachTagCommand(List<String> cardIds, String name) {

	public AttachTagCommand {
		cardIds = cardIds == null ? List.of() : List.copyOf(cardIds);
	}
}
