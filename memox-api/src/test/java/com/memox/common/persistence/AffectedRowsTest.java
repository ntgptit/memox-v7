package com.memox.common.persistence;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class AffectedRowsTest {

	@Test
	void acceptsTheSingleRowAWriteByPrimaryKeyShouldTouch() {
		assertThatCode(() -> AffectedRows.requireExactlyOne(1, () -> new IllegalStateException("unused")))
				.doesNotThrowAnyException();
	}

	@Test
	void raisesTheCallersExceptionWhenNothingMatched() {
		assertThatThrownBy(() -> AffectedRows.requireExactlyOne(0, () -> new IllegalArgumentException("deck 7 gone")))
				.isInstanceOf(IllegalArgumentException.class)
				.hasMessage("deck 7 gone");
	}

	/**
	 * The caller does not get to describe this one away.
	 *
	 * <p>A single-row write that matched several rows is a defective WHERE clause, never a client
	 * mistake, so reporting it as the caller's 404 or 409 would send a wrong answer to the client
	 * and hide a real defect. The supplier is ignored on purpose — this test would pass by accident
	 * if it were called, so it supplies an exception that would be obviously wrong.
	 */
	@Test
	void refusesAMultiRowResultAsAProgrammingErrorRatherThanTheCallersFailure() {
		assertThatThrownBy(() -> AffectedRows.requireExactlyOne(4, () -> new IllegalArgumentException("caller's")))
				.isInstanceOf(IllegalStateException.class)
				.hasMessageContaining("matched 4 rows")
				.hasMessageContaining("not selective");
	}

	/** The supplier must not run on the happy path — building it may be expensive or have a cost. */
	@Test
	void doesNotBuildTheExceptionWhenTheWriteSucceeded() {
		AffectedRows.requireExactlyOne(1, () -> {
			throw new AssertionError("the supplier ran on a successful write");
		});
	}
}
