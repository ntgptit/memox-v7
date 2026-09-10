package com.memox.trash.service;

/** Move one deck and its whole active subtree to Trash (BR-256, BR-258). */
public record DeleteDeckCommand(String deckId) {
}
