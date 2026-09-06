package com.memox.deck.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.InvocationTargetException;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.pagination.PageQuery;
import com.memox.support.PostgresIntegrationTest;

class DeckMapperTest extends PostgresIntegrationTest {

	@Autowired
	private DeckMapper deckMapper;

	@Test
	void executesTheXmlMappedQuery() throws NoSuchMethodException, InvocationTargetException, IllegalAccessException {
		final var method = DeckMapper.class.getMethod("readSchemaVersion");

		assertThat(method.invoke(deckMapper)).isEqualTo("v1");
	}

	@Test
	void returnsAnEmptyRootPageWithZeroTotalFromOneQuery() {
		final var pageRows = deckMapper.findRootDecks(PageQuery.builder().limit(10).offset(0).build());

		assertThat(pageRows).singleElement().satisfies(pageRow -> {
			assertThat(pageRow.getDeck()).isNull();
			assertThat(pageRow.getTotalItems()).isZero();
		});
	}
}
