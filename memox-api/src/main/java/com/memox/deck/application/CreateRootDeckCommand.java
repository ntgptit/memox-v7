package com.memox.deck.application;

import com.memox.deck.domain.SchedulerType;

public record CreateRootDeckCommand(String id, String name, SchedulerType schedulerType) {
}
