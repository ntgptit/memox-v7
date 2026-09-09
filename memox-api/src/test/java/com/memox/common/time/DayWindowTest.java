package com.memox.common.time;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;

import org.junit.jupiter.api.Test;

import com.memox.common.error.ValidationFailedException;

/**
 * BR-105 in one test class: whose midnight decides what is overdue.
 */
class DayWindowTest {

	/** Late evening in UTC — deliberately, because it is already tomorrow east of here. */
	private static final Instant NOW = Instant.parse("2026-09-09T22:00:00Z");

	private static final Clock CLOCK = Clock.fixed(NOW, ZoneOffset.UTC);

	/**
	 * The same instant is two different days in two places, and the boundary follows the caller.
	 *
	 * <p>At 22:00 UTC it is already the 10th in Seoul and still the 9th in New York. A server that
	 * used its own midnight would mark a Seoul user's cards overdue nine hours early, and a New York
	 * user's five hours late.
	 */
	@Test
	void derivesMidnightFromTheCallersOffsetRatherThanTheServersDay() {
		assertThat(DayWindow.of(CLOCK, 9 * 60).startOfDay())
				.isEqualTo(Instant.parse("2026-09-09T15:00:00Z"));
		assertThat(DayWindow.of(CLOCK, -5 * 60).startOfDay())
				.isEqualTo(Instant.parse("2026-09-09T05:00:00Z"));
		assertThat(DayWindow.of(CLOCK, 0).startOfDay())
				.isEqualTo(Instant.parse("2026-09-09T00:00:00Z"));
	}

	@Test
	void readsNowFromTheInjectedClock() {
		assertThat(DayWindow.of(CLOCK, 0).now()).isEqualTo(NOW);
	}

	/** Half-hour and three-quarter-hour zones are real; India is +05:30 and Nepal +05:45. */
	@Test
	void acceptsOffsetsThatAreNotWholeHours() {
		assertThat(DayWindow.of(CLOCK, 5 * 60 + 45).startOfDay())
				.isEqualTo(Instant.parse("2026-09-09T18:15:00Z"));
	}

	@Test
	void acceptsTheExtremesOfTheRealOffsetRange() {
		assertThat(DayWindow.of(CLOCK, -12 * 60)).isNotNull();
		assertThat(DayWindow.of(CLOCK, 14 * 60)).isNotNull();
	}

	/**
	 * An offset outside the real range is a client bug or an attempt to shift the due window, and
	 * either way it must not silently move what counts as overdue.
	 */
	@Test
	void refusesAnOffsetNoPlaceOnEarthUses() {
		assertThatThrownBy(() -> DayWindow.of(CLOCK, 15 * 60))
				.isInstanceOf(ValidationFailedException.class)
				.hasFieldOrPropertyWithValue("field", "X-Utc-Offset-Minutes");
		assertThatThrownBy(() -> DayWindow.of(CLOCK, -13 * 60))
				.isInstanceOf(ValidationFailedException.class);
	}
}
