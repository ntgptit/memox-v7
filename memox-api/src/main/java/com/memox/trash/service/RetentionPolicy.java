package com.memox.trash.service;

import java.time.Duration;
import java.time.Instant;

import lombok.experimental.UtilityClass;

/**
 * How long Trash keeps a deletion (BR-264).
 *
 * <p>Thirty times twenty-four hours from {@code deleted_at}, and the comparison is {@code <=}: a
 * batch sitting at exactly thirty days is eligible. The rule says so, and a boundary written the
 * other way is invisible — it would only ever show up as one batch surviving a day longer than
 * anyone intended.
 *
 * <p>{@code now} is a parameter, never a clock read here. Every layer takes the moment from the
 * injected clock so tests can move it, and so two reads inside one sweep cannot disagree.
 */
@UtilityClass
public class RetentionPolicy {

	public static final Duration RETENTION = Duration.ofDays(30);

	public Instant cutoff(Instant now) {
		return now.minus(RETENTION);
	}
}
