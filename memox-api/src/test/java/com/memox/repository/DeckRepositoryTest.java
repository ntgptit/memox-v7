package com.memox.repository;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.reflect.InvocationTargetException;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = "spring.profiles.active=test")
class DeckRepositoryTest {

	@Autowired
	private DeckRepository deckRepository;

	@Test
	void executesTheXmlMappedQuery() throws NoSuchMethodException, InvocationTargetException, IllegalAccessException {
		final var method = DeckRepository.class.getMethod("readSchemaVersion");

		assertThat(method.invoke(deckRepository)).isEqualTo("v1");
	}
}
