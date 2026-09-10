package com.memox.card.dto.response;

import com.memox.card.entity.CardKey;

/**
 * One duplicate identity already present in a deck (BR-170).
 *
 * <p>Two folded fields rather than one joined string: every separator scheme rests on the unspoken
 * invariant that the separator does not occur in the text, and no type defends it (AD-20).
 */
public record CardKeyResponse(String frontFolded, String backFolded) {

	public static CardKeyResponse from(CardKey key) {
		return new CardKeyResponse(key.frontFolded(), key.backFolded());
	}
}
