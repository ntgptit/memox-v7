package com.memox.deck.service;

public record CreateSubDeckCommand(String id, String name, String parentDeckId) {
}
