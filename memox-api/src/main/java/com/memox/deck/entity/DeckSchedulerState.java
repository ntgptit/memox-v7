package com.memox.deck.entity;

import com.memox.common.scheduler.SchedulerType;

public record DeckSchedulerState(SchedulerType schedulerType, int version, int generation) {
}
