package com.memox.deck.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

import com.memox.common.error.FieldValidationException;

class DeckNameTest {

	@Test
	void normalizesWhitespaceAtTheDomainBoundary() {
		assertThat(DeckName.of("  Korean basics  ").value()).isEqualTo("Korean basics");
	}

	@Test
	void rejectsBlankAndOverlongNames() {
		assertThatThrownBy(() -> DeckName.of("   ")).isInstanceOf(FieldValidationException.class);
		assertThatThrownBy(() -> DeckName.of("x".repeat(DeckName.MAX_LENGTH + 1)))
				.isInstanceOf(FieldValidationException.class);
	}
}
