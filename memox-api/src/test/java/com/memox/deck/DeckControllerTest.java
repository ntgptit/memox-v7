package com.memox.deck;

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
				.andExpect(jsonPath("$[?(@.id == '%s')].name".formatted(deckId))
						.value("Korean basics"));
	}

	@Test
	void returnsProblemDetailsForInvalidRootDeckInput() throws Exception {
		mockMvc.perform(post("/api/v1/decks")
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
				.andExpect(jsonPath("$.fieldErrors.id").exists())
				.andExpect(jsonPath("$.fieldErrors.name").exists())
				.andExpect(jsonPath("$.fieldErrors.schedulerType").exists());
	}
}
