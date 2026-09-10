package com.memox.trash.service;

/**
 * Put one batch back, into a target the user chose (BR-261).
 *
 * <p>{@code targetDeckId} is null for <strong>the top level</strong>, which is a real target and
 * not a missing one: a root deck has exactly one valid destination and that is it. Nothing else may
 * use it — a sub-deck promoted to the top would need a scheduler of its own, which is a decision
 * rather than a restore, and the top level holds no cards at all (BR-58).
 */
public record RestoreBatchCommand(String batchId, String targetDeckId) {
}
