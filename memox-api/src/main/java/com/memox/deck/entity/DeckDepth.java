package com.memox.deck.entity;

/**
 * How far a deck sits from its root, and whether the walk actually got there.
 *
 * <p>{@code reachedRoot} is what separates a measurement from a lower bound. The walk is capped, so
 * a chain longer than the cap — which only corrupt data or a cycle can produce — returns the cap
 * rather than the truth. Without this flag the caller could not tell those apart, and "10" would
 * mean both "exactly at the limit" and "at least this deep".
 *
 * @param depth 1 for a root, counting downwards (BR-55)
 * @param reachedRoot false when the walk hit its bound before finding a deck with no parent
 */
public record DeckDepth(int depth, boolean reachedRoot) {
}
