package com.memox.common.pagination;

/**
 * One entry of a sort request: which field, in which direction.
 *
 * <p>{@code TSort} is an enum by declaration, so there is no string channel into a sort — a client
 * that writes something the enum does not name is rejected while still in the transport layer.
 *
 * @param <TSort> the feature's sort enum, for example {@code DeckSortField}
 */
public record SortSpec<TSort extends Enum<TSort>>(TSort field, SortDirection direction) {
}
