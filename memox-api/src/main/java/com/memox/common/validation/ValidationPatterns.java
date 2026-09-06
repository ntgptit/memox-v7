package com.memox.common.validation;

import lombok.experimental.UtilityClass;

@UtilityClass
public class ValidationPatterns {

	public static final String UUID = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$";
}
