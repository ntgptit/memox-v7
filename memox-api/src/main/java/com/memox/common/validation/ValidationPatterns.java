package com.memox.common.validation;

import lombok.experimental.UtilityClass;

@UtilityClass
public class ValidationPatterns {

	/** Matches decks.name VARCHAR(200); the audit flagged this literal duplicated across DTOs. */
	public static final int DECK_NAME_MAX_LENGTH = 200;

	public static final String UUID = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$";
}
