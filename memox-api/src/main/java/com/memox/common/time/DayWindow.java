package com.memox.common.time;

import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;

import com.memox.common.error.ValidationFailedException;

/**
 * The two instants a "what is due today" question needs, in the caller's day rather than the
 * server's.
 *
 * <p>BR-105: the server never guesses a local midnight. Overdue means <em>before today began where
 * the user is</em>, and a server in UTC deciding that for a user in UTC+9 marks nine hours of cards
 * overdue that are not. So the client states its offset and the boundary is derived from it.
 *
 * @param now the moment the request is being served
 * @param startOfDay midnight of the caller's current day, expressed as an instant
 */
public record DayWindow(Instant now, Instant startOfDay) {

	public static final String OFFSET_HEADER = "X-Utc-Offset-Minutes";

	/** The real range of UTC offsets: UTC-12:00 through UTC+14:00. */
	private static final int MIN_OFFSET_MINUTES = -12 * 60;
	private static final int MAX_OFFSET_MINUTES = 14 * 60;
	private static final int SECONDS_PER_MINUTE = 60;

	public static DayWindow of(Clock clock, int utcOffsetMinutes) {
		if (utcOffsetMinutes < MIN_OFFSET_MINUTES || utcOffsetMinutes > MAX_OFFSET_MINUTES) {
			throw new ValidationFailedException(OFFSET_HEADER,
					"must be a real UTC offset in minutes, between " + MIN_OFFSET_MINUTES
							+ " and " + MAX_OFFSET_MINUTES);
		}
		final var offset = ZoneOffset.ofTotalSeconds(utcOffsetMinutes * SECONDS_PER_MINUTE);
		final var now = Instant.now(clock);
		return new DayWindow(now, LocalDate.ofInstant(now, offset).atStartOfDay(offset).toInstant());
	}
}
