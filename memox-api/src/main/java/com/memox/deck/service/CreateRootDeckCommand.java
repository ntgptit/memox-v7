package com.memox.deck.service;

import com.memox.common.scheduler.SchedulerType;

public record CreateRootDeckCommand(String id, String name, SchedulerType schedulerType) {
}
