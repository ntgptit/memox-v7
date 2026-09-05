package com.memox.card;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;

@AutoConfigureMockMvc
@SpringBootTest(properties = "spring.profiles.active=test")
class CardControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@Autowired
	private JdbcTemplate jdbcTemplate;

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
		assertStudyState(cardId, "eight_box", 1);
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
