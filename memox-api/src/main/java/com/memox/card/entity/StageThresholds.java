package com.memox.card.entity;

/**
 * Where one learning stage ends and the next begins, for both schedulers at once.
 *
 * <p>Constants rather than literals inside the statement: the same four numbers decide the badge on
 * the deck list, the badge on the card list and the counts here, so a boundary that moved would
 * otherwise have to be found in four places.
 *
 * @param reviewingBox eight-box: the box at which a card counts as reviewing
 * @param masteredBox eight-box: the box at which it counts as mastered
 * @param reviewingDays SM-2: the interval in days at which a card counts as reviewing
 * @param masteredDays SM-2: the interval at which it counts as mastered
 */
public record StageThresholds(int reviewingBox, int masteredBox, int reviewingDays, int masteredDays) {

	/** The values the Flutter side calls {@code cardStateCountsByDeck} with. */
	public static final StageThresholds DEFAULTS = new StageThresholds(2, 8, 21, 128);
}
