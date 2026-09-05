package com.memox.deck.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import com.memox.deck.domain.SchedulerType;

public record CreateRootDeckRequest(
		@NotBlank @Pattern(regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$") String id,
		@NotBlank @Size(max = 200) String name,
		@NotBlank @Pattern(regexp = SchedulerType.VALIDATION_PATTERN) String schedulerType) {
}
