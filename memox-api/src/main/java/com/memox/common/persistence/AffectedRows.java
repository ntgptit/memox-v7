package com.memox.common.persistence;

import java.util.function.Supplier;

import lombok.experimental.UtilityClass;

/**
 * Turns the row count an UPDATE or DELETE returns into a decision, instead of discarding it.
 *
 * <p>Every mapper write hands back the number of rows it touched, and the default habit is to
 * ignore it. That is safe in exactly one situation — the statement runs after a
 * {@code SELECT ... FOR UPDATE} in the same transaction has already proved the row exists and
 * holds it — and unsafe everywhere else, because a write that matched nothing looks identical to a
 * write that succeeded. The module's two existing updates are in that safe situation, and nothing
 * said so; this makes the precondition an assertion rather than a fact you had to reconstruct from
 * the call site.
 *
 * <p>The two failure counts are not the same kind of event, so they are not reported the same way:
 *
 * <ul>
 *   <li><strong>zero rows</strong> — the row was not there. Only the caller knows what that means:
 *       a 404 for a rename by id, a 409 for a state that moved underneath a check, or a broken
 *       invariant when the row was already locked. So the caller supplies the exception.</li>
 *   <li><strong>more than one row</strong> — the WHERE clause is wrong. That is never a client's
 *       fault and never something a caller should be able to describe away, so it is always an
 *       {@link IllegalStateException}, whatever the caller passed.</li>
 * </ul>
 */
@UtilityClass
public class AffectedRows {

	private static final int EXPECTED_SINGLE_ROW = 1;

	/**
	 * @param rowsAffected the value returned by the mapper method — pass it directly, do not store
	 *                     it in a variable you might forget to check
	 * @param whenNoRowMatched builds the exception for the zero-row case; it is only called when
	 *                         that case happens, so building it may cost whatever it needs to
	 */
	public <X extends RuntimeException> void requireExactlyOne(int rowsAffected, Supplier<X> whenNoRowMatched) {
		if (rowsAffected == EXPECTED_SINGLE_ROW) {
			return;
		}
		if (rowsAffected > EXPECTED_SINGLE_ROW) {
			throw new IllegalStateException(
					"a single-row write matched " + rowsAffected + " rows; its WHERE clause is not selective");
		}
		throw whenNoRowMatched.get();
	}
}
