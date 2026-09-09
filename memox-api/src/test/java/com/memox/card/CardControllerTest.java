package com.memox.card;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.support.PostgresIntegrationTest;

class CardControllerTest extends PostgresIntegrationTest {

	@Autowired
	private MockMvc mockMvc;


	@Test
	void returnsNotFoundForCardsInAnUnknownDeck() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", UUID.randomUUID())
					.param("size", "20"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
	}

	@Test
	void returnsAnEmptyPageForAnExistingDeckWithoutCards() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var cardDeckId = UUID.randomUUID().toString();
		createRoot(rootId);
		createChild(rootId, cardDeckId);

		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", cardDeckId).param("size", "20"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items").isEmpty())
				.andExpect(jsonPath("$.totalItems").value(0))
				.andExpect(jsonPath("$.totalPages").value(0))
				.andExpect(jsonPath("$.hasNext").value(false))
				.andExpect(jsonPath("$.hasPrevious").value(false));
	}

	@Test
	void createsCardAndInitialStudyStateInAnUnsetSubDeck() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var cardDeckId = UUID.randomUUID().toString();
		final var cardId = UUID.randomUUID().toString();
		createRoot(rootId);
		createChild(rootId, cardDeckId);

		mockMvc.perform(post("/api/v1/decks/{deckId}/cards", cardDeckId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{
							  "id": "%s",
							  "front": "안녕하세요",
							  "back": "Hello"
							}
							""".formatted(cardId)))
				.andExpect(status().isCreated())
				.andExpect(jsonPath("$.id").value(cardId))
				.andExpect(jsonPath("$.deckId").value(cardDeckId))
				.andExpect(jsonPath("$.front").value("안녕하세요"))
				.andExpect(jsonPath("$.back").value("Hello"));

		mockMvc.perform(get("/api/v1/decks/{deckId}", cardDeckId))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.contentType").value("card"));
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", cardDeckId).param("size", "20"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].id").value(cardId))
				.andExpect(jsonPath("$.size").value(20))
				.andExpect(jsonPath("$.page").value(0))
				.andExpect(jsonPath("$.totalItems").value(1))
				.andExpect(jsonPath("$.totalPages").value(1))
				.andExpect(jsonPath("$.hasNext").value(false))
				.andExpect(jsonPath("$.hasPrevious").value(false));
		assertStudyState(cardId, "eight_box", 1);
	}

	@Test
	void returnsCardPagesUsingLimitAndOffset() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var cardDeckId = UUID.randomUUID().toString();
		final var firstCardId = UUID.randomUUID().toString();
		final var secondCardId = UUID.randomUUID().toString();
		createRoot(rootId);
		createChild(rootId, cardDeckId);
		createCard(cardDeckId, firstCardId, "First", "One");
		createCard(cardDeckId, secondCardId, "Second", "Two");

		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", cardDeckId)
					.param("size", "1")
					.param("page", "0"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].id").value(firstCardId))
				.andExpect(jsonPath("$.size").value(1))
				.andExpect(jsonPath("$.page").value(0))
				.andExpect(jsonPath("$.totalItems").value(2))
				.andExpect(jsonPath("$.totalPages").value(2))
				.andExpect(jsonPath("$.hasNext").value(true))
				.andExpect(jsonPath("$.hasPrevious").value(false));

		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", cardDeckId)
					.param("size", "1")
					.param("page", "1"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].id").value(secondCardId))
				.andExpect(jsonPath("$.size").value(1))
				.andExpect(jsonPath("$.page").value(1))
				.andExpect(jsonPath("$.totalItems").value(2))
				.andExpect(jsonPath("$.totalPages").value(2))
				.andExpect(jsonPath("$.hasNext").value(false))
				.andExpect(jsonPath("$.hasPrevious").value(true));
	}

	@Test
	void retainsCardTotalsWhenOffsetExceedsAvailableCards() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var cardDeckId = UUID.randomUUID().toString();
		createRoot(rootId);
		createChild(rootId, cardDeckId);
		createCard(cardDeckId, UUID.randomUUID().toString(), "First", "One");
		createCard(cardDeckId, UUID.randomUUID().toString(), "Second", "Two");

		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", cardDeckId)
					.param("size", "1")
					.param("page", "100"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items").isEmpty())
				.andExpect(jsonPath("$.totalItems").value(2))
				.andExpect(jsonPath("$.totalPages").value(2))
				.andExpect(jsonPath("$.hasNext").value(false))
				.andExpect(jsonPath("$.hasPrevious").value(true));
	}

	private void createRoot(String rootId) throws Exception {
		mockMvc.perform(post("/api/v1/decks")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"Root","schedulerType":"eight_box"}
							""".formatted(rootId)))
				.andExpect(status().isCreated());
	}

	private void createChild(String rootId, String childId) throws Exception {
		mockMvc.perform(post("/api/v1/decks/{parentDeckId}/children", rootId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"Cards"}
							""".formatted(childId)))
				.andExpect(status().isCreated());
	}

	private void createCard(String deckId, String cardId, String front, String back) throws Exception {
		mockMvc.perform(post("/api/v1/decks/{deckId}/cards", deckId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","front":"%s","back":"%s"}
							""".formatted(cardId, front, back)))
				.andExpect(status().isCreated());
	}

	private void assertStudyState(String cardId, String schedulerType, int generation) {
		final var state = jdbcTemplate.queryForMap(
				"SELECT scheduler_type, scheduler_generation, due_at FROM card_study_states WHERE card_id = ?",
				cardId);
		org.assertj.core.api.Assertions.assertThat(state)
				.containsEntry("scheduler_type", schedulerType)
				.containsEntry("scheduler_generation", generation)
				.containsEntry("due_at", null);
	}
}
