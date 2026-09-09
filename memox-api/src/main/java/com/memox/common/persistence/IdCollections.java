package com.memox.common.persistence;

import java.util.Collection;
import java.util.List;

import com.memox.common.error.ValidationFailedException;

import lombok.experimental.UtilityClass;

/**
 * The guard every {@code IN}-collection statement passes through.
 *
 * <p>Two things it refuses, for two different reasons.
 *
 * <p><strong>Empty.</strong> PostgreSQL rejects {@code IN ()} outright — translation row 9 — so an
 * empty list must never reach the database. It is also not the same request as "match nothing": a
 * batch operation on no ids is a client mistake worth naming.
 *
 * <p><strong>Too large.</strong> {@value #MAX_BATCH_SIZE} ids, and a longer list is <em>refused
 * rather than truncated</em>. A client that silently loses rows is worse off than one that is told
 * no. The number keeps a single statement's parameter list far below PostgreSQL's 65 535 bind limit
 * even at several parameters per id, and is far above any selection a person assembles by hand.
 */
@UtilityClass
public class IdCollections {

	/** Decided in M9.P0, because the Phase 2 plan specified no cap at all. */
	public static final int MAX_BATCH_SIZE = 500;

	public List<String> requireUsableBatch(Collection<String> ids, String parameterName) {
		if (ids == null || ids.isEmpty()) {
			throw new ValidationFailedException(parameterName, "must not be empty");
		}
		if (ids.size() > MAX_BATCH_SIZE) {
			throw new ValidationFailedException(parameterName,
					"must not hold more than " + MAX_BATCH_SIZE + " ids in one request");
		}
		return List.copyOf(ids);
	}
}
