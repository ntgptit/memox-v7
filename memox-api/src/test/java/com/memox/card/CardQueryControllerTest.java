package com.memox.card;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class CardQueryControllerTest extends PostgresIntegrationTest {

	private static final Instant LEARNED = Instant.parse("2026-09-01T00:00:00Z");
	private static final String TARGET_DECK_ID = "55555555-5555-4555-8555-555555555555";

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

	@Test
	void publishesOneCardAndRefusesATrashedOne() throws Exception {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);

		mockMvc.perform(get("/api/v1/cards/{cardId}", "card-1"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.id").value("card-1"))
				.andExpect(jsonPath("$.deckId").value("deck"));

		softDelete("card", "card-1");

		mockMvc.perform(get("/api/v1/cards/{cardId}", "card-1"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("CARD_NOT_FOUND"));
	}

	@Test
	void publishesHistoryWithACursorThatCanBeSentStraightBack() throws Exception {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);
		insertAnswer("a1", Instant.parse("2026-09-01T10:00:00Z"));
		insertAnswer("a2", Instant.parse("2026-09-02T10:00:00Z"));

		final var body = mockMvc.perform(get("/api/v1/cards/{cardId}/history", "card-1")
					.param("limit", "1"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.entries.length()").value(1))
				.andExpect(jsonPath("$.entries[0].id").value("a2"))
				.andExpect(jsonPath("$.entries[0].action").value("remembered"))
				.andExpect(jsonPath("$.hasMore").value(true))
				.andExpect(jsonPath("$.nextCursor.id").value("a2"))
				.andReturn().getResponse().getContentAsString();

		final var cursorAt = com.jayway.jsonpath.JsonPath.read(body, "$.nextCursor.answeredAt")
				.toString();

		mockMvc.perform(get("/api/v1/cards/{cardId}/history", "card-1")
					.param("limit", "1").param("answeredAt", cursorAt).param("cursorId", "a2"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.entries[0].id").value("a1"))
				.andExpect(jsonPath("$.hasMore").value(false))
				.andExpect(jsonPath("$.nextCursor").doesNotExist());
	}

	/** Half a cursor would silently restart at page one and repeat rows the client already showed. */
	@Test
	void refusesHalfACursor() throws Exception {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);

		mockMvc.perform(get("/api/v1/cards/{cardId}/history", "card-1").param("cursorId", "a2"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.cursor").exists());
	}

	@Test
	void editsACardWithoutTouchingItsFlag() throws Exception {
		seedDeck();
		insertFlaggedCard("c1", "deck");

		mockMvc.perform(patch("/api/v1/cards/{cardId}", "c1")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"front":"  안녕  ","back":"Hello"}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.front").value("안녕"))
				.andExpect(jsonPath("$.flagged").value(true));
	}

	/** The target id is validated as a UUID, so these tests use real ones rather than short names. */
	@Test
	void movesABatchAndReportsHowManyItWrote() throws Exception {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck(TARGET_DECK_ID, "Unit 2", "root", "root", DeckContentType.UNSET);
		insertCardWithState("c1", "src", null, null);
		insertCardWithState("c2", "src", null, null);

		mockMvc.perform(post("/api/v1/cards/bulk-move")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1","c2"],"targetDeckId":"%s"}""".formatted(TARGET_DECK_ID)))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.written").value(2));
	}

	@Test
	void refusesAMoveIntoADeckThatHoldsSubDecks() throws Exception {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck(TARGET_DECK_ID, "Unit 2", "root", "root", DeckContentType.DECK);
		insertCardWithState("c1", "src", null, null);

		mockMvc.perform(post("/api/v1/cards/bulk-move")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1"],"targetDeckId":"%s"}""".formatted(TARGET_DECK_ID)))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.code").value("MOVE_TARGET_INVALID"));
	}

	@Test
	void setsTheFlagOnABatch() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);

		mockMvc.perform(post("/api/v1/cards/bulk-flag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1"],"flagged":true}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.written").value(1));

		mockMvc.perform(get("/api/v1/cards/{cardId}", "c1"))
				.andExpect(jsonPath("$.flagged").value(true));
	}

	@Test
	void refusesABulkRequestWithNoIds() throws Exception {
		mockMvc.perform(post("/api/v1/cards/bulk-flag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":[],"flagged":true}"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
	}

	private void insertAnswer(final String answerId, final Instant answeredAt) {
		this.jdbcTemplate.update("""
				INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, status,
				                            session_kind, current_mode, card_limit, started_at)
				VALUES ('session', 'deck', 'root', 1, 'in_progress', 'reviewing', 'self_assess', 20, ?)
				ON CONFLICT (id) DO NOTHING""", java.sql.Timestamp.from(answeredAt));
		this.jdbcTemplate.update("""
				INSERT INTO study_answers (id, card_id, session_id, scheduler_type,
				                           scheduler_generation, kind, mode, "action", answered_at)
				VALUES (?, 'card-1', 'session', 'eight_box', 1, 'scheduled', 'self_assess',
				        'remembered', ?)""",
				answerId, java.sql.Timestamp.from(answeredAt));
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
