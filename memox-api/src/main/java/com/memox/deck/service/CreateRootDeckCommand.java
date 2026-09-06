package com.memox.deck.service;

import com.memox.deck.domain.SchedulerType;

public record CreateRootDeckCommand(String id, String name, SchedulerType schedulerType) {
}
