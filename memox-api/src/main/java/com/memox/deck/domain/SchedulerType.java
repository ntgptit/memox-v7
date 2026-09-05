package com.memox.deck.domain;

import java.util.Arrays;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum SchedulerType {

	EIGHT_BOX("eight_box"),
	SM2("sm2");

	public static final String VALIDATION_PATTERN = "eight_box|sm2";

	private final String value;

	public static SchedulerType fromValue(String value) {
		return Arrays.stream(values())
				.filter(schedulerType -> schedulerType.value.equals(value))
				.findFirst()
				.orElseThrow(() -> new IllegalArgumentException("Unsupported scheduler type: " + value));
	}

	public static SchedulerType fromNullableValue(String value) {
		if (value == null) {
			return null;
		}
		return fromValue(value);
	}
}
