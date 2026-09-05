package com.memox.deck;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@AutoConfigureMockMvc
@SpringBootTest(properties = "spring.profiles.active=test")
class DeckControllerTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void createsAndListsAClientIdentifiedRootDeck() throws Exception {
		final var deckId = UUID.randomUUID().toString();
		final var request = """
				{
				  "id": "%s",
				  "name": "Korean basics",
				  "schedulerType": "eight_box"
				}
				""".formatted(deckId);

		mockMvc.perform(post("/api/v1/decks")
					.header("X-Request-Id", "client-request-1")
					.contentType(MediaType.APPLICATION_JSON)
					.content(request))
				.andExpect(status().isCreated())
				.andExpect(jsonPath("$.id").value(deckId))
				.andExpect(jsonPath("$.name").value("Korean basics"))
				.andExpect(jsonPath("$.parentDeckId").doesNotExist())
				.andExpect(jsonPath("$.rootDeckId").value(deckId))
				.andExpect(jsonPath("$.contentType").value("deck"))
				.andExpect(jsonPath("$.schedulerType").value("eight_box"))
				.andExpect(jsonPath("$.schedulerGeneration").value(1));

		mockMvc.perform(get("/api/v1/decks"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[?(@.id == '%s')].name".formatted(deckId))
						.value("Korean basics"));
	}

	@Test
	void returnsProblemDetailsForInvalidRootDeckInput() throws Exception {
		mockMvc.perform(post("/api/v1/decks")
					.header("X-Request-Id", "client-request-1")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{
							  "id": "not-a-uuid",
							  "name": "   ",
							  "schedulerType": "unknown"
							}
							"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.requestId").value("client-request-1"))
				.andExpect(header().string("X-Request-Id", "client-request-1"))
				.andExpect(jsonPath("$.fieldErrors.id").exists())
				.andExpect(jsonPath("$.fieldErrors.name").exists())
				.andExpect(jsonPath("$.fieldErrors.schedulerType").exists());
	}

	@Test
	void returnsConflictProblemDetailsForADuplicateClientId() throws Exception {
		final var deckId = UUID.randomUUID().toString();
		final var request = """
				{"id":"%s","name":"Root","schedulerType":"sm2"}
				""".formatted(deckId);

		mockMvc.perform(post("/api/v1/decks").contentType(MediaType.APPLICATION_JSON).content(request))
				.andExpect(status().isCreated());

		mockMvc.perform(post("/api/v1/decks").contentType(MediaType.APPLICATION_JSON).content(request))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.code").value("DATA_INTEGRITY_VIOLATION"));
	}

	@Test
	void createsASubDeckAndLocksAnUnsetParentToDeckContent() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var childId = UUID.randomUUID().toString();
		final var grandchildId = UUID.randomUUID().toString();
		mockMvc.perform(post("/api/v1/decks")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"Root","schedulerType":"sm2"}
							""".formatted(rootId)))
				.andExpect(status().isCreated());

		mockMvc.perform(post("/api/v1/decks/{parentDeckId}/children", rootId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"Child"}
							""".formatted(childId)))
				.andExpect(status().isCreated())
				.andExpect(jsonPath("$.id").value(childId))
				.andExpect(jsonPath("$.parentDeckId").value(rootId))
				.andExpect(jsonPath("$.rootDeckId").value(rootId))
				.andExpect(jsonPath("$.contentType").value("unset"))
				.andExpect(jsonPath("$.schedulerType").doesNotExist());

		mockMvc.perform(post("/api/v1/decks/{parentDeckId}/children", childId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"Grandchild"}
							""".formatted(grandchildId)))
				.andExpect(status().isCreated());

		mockMvc.perform(get("/api/v1/decks/{deckId}", childId))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.contentType").value("deck"))
				.andExpect(jsonPath("$.rootDeckId").value(rootId));
	}
}
