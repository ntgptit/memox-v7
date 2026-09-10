package com.memox.tag.dto.request;

import jakarta.validation.constraints.NotNull;

/**
 * A new name for one tag.
 *
 * <p>Only the null check is a Bean Validation annotation. Trimming, the length ceiling and the
 * control-character rule are BR-93 and live on {@code TagName}, so the same request arriving through
 * a future import path is held to the same rule rather than to a second copy of it.
 */
public record RenameTagRequest(@NotNull(message = "{validation.required}") String name) {
}
