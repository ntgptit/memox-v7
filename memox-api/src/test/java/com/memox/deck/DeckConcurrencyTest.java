package com.memox.deck;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;

import com.memox.deck.application.CreateRootDeckCommand;
import com.memox.deck.domain.SchedulerType;
import com.memox.service.DeckService;

@SpringBootTest(properties = "spring.profiles.active=test")
class DeckConcurrencyTest {

	@Autowired
	private DeckService deckService;

	@Autowired
	private JdbcTemplate jdbcTemplate;

	@Test
	void assignsDistinctSiblingPositionsWhenRootDecksAreCreatedConcurrently() throws Exception {
		final var firstDeckId = UUID.randomUUID().toString();
		final var secondDeckId = UUID.randomUUID().toString();
		final var ready = new CountDownLatch(2);
		final var start = new CountDownLatch(1);

		final ExecutorService executor = Executors.newFixedThreadPool(2);
		try {
			final var first = executor.submit(() -> createRootDeck(firstDeckId, ready, start));
			final var second = executor.submit(() -> createRootDeck(secondDeckId, ready, start));
			assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
			start.countDown();
			first.get(10, TimeUnit.SECONDS);
			second.get(10, TimeUnit.SECONDS);
		} finally {
			executor.shutdownNow();
		}

		final List<Integer> positions = jdbcTemplate.queryForList(
				"SELECT sibling_position FROM decks WHERE id IN (?, ?) ORDER BY sibling_position",
				Integer.class,
				firstDeckId,
				secondDeckId);
		assertThat(positions).hasSize(2).doesNotHaveDuplicates();
	}

	private void createRootDeck(String deckId, CountDownLatch ready, CountDownLatch start) {
		ready.countDown();
		await(start);
		deckService.createRootDeck(new CreateRootDeckCommand(deckId, "Concurrent root", SchedulerType.SM2));
	}

	private void await(CountDownLatch latch) {
		try {
			latch.await();
		} catch (InterruptedException exception) {
			Thread.currentThread().interrupt();
			throw new IllegalStateException("Interrupted while coordinating concurrent test.", exception);
		}
	}
}
