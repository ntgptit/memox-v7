package com.memox.deck.domain;

import java.util.Arrays;

import com.memox.common.mybatis.PersistableEnum;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum DeckContentType implements PersistableEnum {

	UNSET("unset"),
	DECK("deck"),
	CARD("card");

	private final String value;

	public static DeckContentType fromValue(String value) {
		return Arrays.stream(values())
				.filter(contentType -> contentType.value.equals(value))
				.findFirst()
				.orElseThrow(() -> new IllegalArgumentException("Unsupported deck content type: " + value));
	}
}
