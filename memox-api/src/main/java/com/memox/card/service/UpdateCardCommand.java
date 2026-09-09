package com.memox.card.service;

/**
 * New content for one card.
 *
 * <p>Content only. BR-92: an edit never touches the flag and never touches a scheduler column —
 * content survives every reset, and the schedule is not the content's business.
 *
 * <p>Optional fields are normalised the way creation normalises them: trimmed, and blank becomes
 * absent, so "  " and null mean the same thing rather than two different stored values.
 */
public record UpdateCardCommand(
		String cardId,
		String front,
		String back,
		String example,
		String hint,
		String pronunciation) {
}
