package com.memox.deck.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

import com.memox.common.validation.ValidationPatterns;
import com.memox.common.scheduler.SchedulerType;

public record CreateRootDeckRequest(
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = ValidationPatterns.UUID, message = "{validation.uuid}") String id,
		@NotBlank(message = "{validation.required}") @Size(max = ValidationPatterns.DECK_NAME_MAX_LENGTH, message = "{validation.max-length}") String name,
		@NotBlank(message = "{validation.required}")
		@Pattern(regexp = SchedulerType.VALIDATION_PATTERN, message = "{validation.scheduler-type}") String schedulerType) {
}
