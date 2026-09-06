package com.memox.deck.application;

public record CreateSubDeckCommand(String id, String name, String parentDeckId) {
}
