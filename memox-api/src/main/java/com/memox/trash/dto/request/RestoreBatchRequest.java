package com.memox.trash.dto.request;

/**
 * Where a restore should put the batch back (BR-261).
 *
 * <p>Deliberately not {@code @NotBlank}: <strong>absent means the top level</strong>, which is a
 * real target and the only one a root deck may use. Requiring a value would make the one legal
 * destination for a root deck unexpressible.
 */
public record RestoreBatchRequest(String targetDeckId) {
}
