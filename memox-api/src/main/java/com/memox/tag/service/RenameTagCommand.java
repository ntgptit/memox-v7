package com.memox.tag.service;

/**
 * Rename one tag (BR-233), which becomes a merge when the folded name is already taken (BR-234).
 *
 * <p>The raw name arrives here rather than a {@code TagName}: normalising it is BR-93's rule and
 * belongs to the type, so the service is the layer that runs it and the controller stays a mapping.
 */
public record RenameTagCommand(String tagId, String name) {
}
