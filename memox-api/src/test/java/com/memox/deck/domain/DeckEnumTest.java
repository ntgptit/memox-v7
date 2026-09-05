package com.memox.deck.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;

class DeckEnumTest {

	@Test
	void resolvesCanonicalPersistenceValues() {
		assertThat(DeckContentType.fromValue("card")).isSameAs(DeckContentType.CARD);
		assertThat(SchedulerType.fromValue("eight_box")).isSameAs(SchedulerType.EIGHT_BOX);
		assertThat(SchedulerType.fromNullableValue(null)).isNull();
	}

	@Test
	void rejectsUnknownPersistenceValues() {
		assertThatThrownBy(() -> DeckContentType.fromValue("unknown"))
				.isInstanceOf(IllegalArgumentException.class);
		assertThatThrownBy(() -> SchedulerType.fromValue("unknown"))
				.isInstanceOf(IllegalArgumentException.class);
	}
}
