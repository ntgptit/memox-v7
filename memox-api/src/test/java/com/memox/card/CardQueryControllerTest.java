package com.memox.card;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class CardQueryControllerTest extends PostgresIntegrationTest {

	private static final Instant LEARNED = Instant.parse("2026-09-01T00:00:00Z");

	@Autowired
	private MockMvc mockMvc;

	@Test
	void publishesTheManagementListWithScheduleAndTags() throws Exception {
		seedDeck();
		insertCardWithState("card-1", "deck", LEARNED, Instant.parse("2026-09-20T00:00:00Z"));
		insertTag("t-a", "alpha");
		linkTag("card-1", "t-a");

		mockMvc.perform(get("/api/v1/cards").param("deckId", "deck"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].id").value("card-1"))
				.andExpect(jsonPath("$.items[0].deckId").value("deck"))
				.andExpect(jsonPath("$.items[0].flagged").value(false))
				.andExpect(jsonPath("$.items[0].schedulerType").value("eight_box"))
				.andExpect(jsonPath("$.items[0].tagNames[0]").value("alpha"))
				.andExpect(jsonPath("$.totalItems").value(1));
	}

	@Test
	void filtersByTagAndByText() throws Exception {
		seedDeck();
		insertCardWithState("tagged", "deck", null, null);
		insertCardWithState("plain", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("tagged", "t-a");

		mockMvc.perform(get("/api/v1/cards").param("deckId", "deck").param("tagIds", "t-a"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.totalItems").value(1))
				.andExpect(jsonPath("$.items[0].id").value("tagged"));

		mockMvc.perform(get("/api/v1/cards").param("deckId", "deck").param("q", "  FRONT PLAIN  "))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.totalItems").value(1))
				.andExpect(jsonPath("$.items[0].id").value("plain"));
	}

	@Test
	void putsNewCardsFirstWhenSortingBySoonestDue() throws Exception {
		seedDeck();
		insertCardWithState("brand-new", "deck", null, null);
		insertCardWithState("due-soon", "deck", LEARNED, Instant.parse("2026-09-11T00:00:00Z"));

		mockMvc.perform(get("/api/v1/cards").param("deckId", "deck").param("sort", "dueAt:asc"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].id").value("brand-new"))
				.andExpect(jsonPath("$.items[1].id").value("due-soon"));
	}

	@Test
	void returnsEveryMatchingIdUnpaged() throws Exception {
		seedDeck();
		insertCardWithState("a", "deck", null, null);
		insertCardWithState("b", "deck", null, null);

		mockMvc.perform(get("/api/v1/cards/ids").param("deckId", "deck").param("size", "1"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(2));
	}

	@Test
	void publishesTheFourStageCounts() throws Exception {
		seedDeck();
		insertCardWithState("new-card", "deck", null, null);
		insertCardWithState("mastered", "deck", LEARNED, null);
		this.jdbcTemplate.update("UPDATE card_study_states SET current_box = 8 WHERE card_id = 'mastered'");

		mockMvc.perform(get("/api/v1/cards/state-counts").param("deckId", "deck"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.newCount").value(1))
				.andExpect(jsonPath("$.masteredCount").value(1))
				.andExpect(jsonPath("$.learningCount").value(0));
	}

	@Test
	void rejectsASortFieldTheCardEndpointDoesNotPublish() throws Exception {
		mockMvc.perform(get("/api/v1/cards").param("sort", "siblingPosition"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
