package com.memox.deck.domain;

public record DeckSchedulerState(SchedulerType schedulerType, int version, int generation) {
}
