package com.memox.deck.entity;

import com.memox.deck.enums.SchedulerType;

public record DeckSchedulerState(SchedulerType schedulerType, int version, int generation) {
}
