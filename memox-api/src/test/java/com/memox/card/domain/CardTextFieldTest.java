package com.memox.card.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

import com.memox.common.error.FieldValidationException;

class CardTextFieldTest {

	@Test
	void normalizesRequiredAndOptionalText() {
		assertThat(CardTextField.FRONT.normalizeRequired("  Front  ")).isEqualTo("Front");
		assertThat(CardTextField.HINT.normalizeOptional("  ")).isNull();
	}

	@Test
	void rejectsBlankRequiredAndOverlongOptionalText() {
		assertThatThrownBy(() -> CardTextField.BACK.normalizeRequired(" "))
				.isInstanceOf(FieldValidationException.class);
		assertThatThrownBy(() -> CardTextField.EXAMPLE.normalizeOptional("x".repeat(241)))
				.isInstanceOf(FieldValidationException.class);
	}
}
