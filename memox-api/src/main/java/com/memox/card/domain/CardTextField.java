package com.memox.card.domain;

import lombok.Getter;
import lombok.RequiredArgsConstructor;

@Getter
@RequiredArgsConstructor
public enum CardTextField {

	FRONT("front", 60),
	BACK("back", 240),
	EXAMPLE("example", 240),
	HINT("hint", 240),
	PRONUNCIATION("pronunciation", 240);

	private final String fieldName;
	private final int maxLength;
}
