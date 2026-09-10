package com.memox.card;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class CardExportControllerTest extends PostgresIntegrationTest {

	@Autowired
	private MockMvc mockMvc;

	/**
	 * BR-175: the artifact carries the six content fields and nothing else.
	 *
	 * <p>The card id and its creation time are read — the id is how a missing selection is named,
	 * the order comes from the timestamp — and they stop at the service. A response that carried
	 * them would let a client write them into a cell, which is the line BR-175 draws between a
	 * content transfer and a backup.
	 */
	@Test
	void publishesTheSixFieldsAndNeitherIdNorTimestamp() throws Exception {
		seedDeck();
		insertFlaggedCard("c1", "deck");
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		mockMvc.perform(get("/api/v1/decks/{deckId}/export", "deck"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.deckName").value("Unit 1"))
				.andExpect(jsonPath("$.cards[0].front").value("front c1"))
				.andExpect(jsonPath("$.cards[0].back").value("back c1"))
				.andExpect(jsonPath("$.cards[0].tagNames[0]").value("alpha"))
				.andExpect(jsonPath("$.cards[0].id").doesNotExist())
				.andExpect(jsonPath("$.cards[0].cardId").doesNotExist())
				.andExpect(jsonPath("$.cards[0].createdAt").doesNotExist())
				.andExpect(jsonPath("$.cards[0].flagged").doesNotExist());
	}

	/** BR-179: an optional field with no value is an empty cell, so the key is present and null. */
	@Test
	void publishesAnAbsentOptionalFieldAsNull() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);

		mockMvc.perform(get("/api/v1/decks/{deckId}/export", "deck"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.cards[0].example").doesNotHaveJsonPath())
				.andExpect(jsonPath("$.cards[0].tagNames").isEmpty());
	}

	@Test
	void exportsTheSelectedScopeThroughAPostBecauseTheIdListDoesNotFitAUrl() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);

		mockMvc.perform(post("/api/v1/decks/{deckId}/export", "deck")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1"]}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.cards.length()").value(1))
				.andExpect(jsonPath("$.cards[0].front").value("front c1"));
	}

	@Test
	void refusesASelectionCarryingAnIdThatLeftTheDeck() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("gone", "deck", null, null);
		softDelete("card", "gone");

		mockMvc.perform(post("/api/v1/decks/{deckId}/export", "deck")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1","gone"]}"""))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.code").value("EXPORT_SELECTION_STALE"));
	}

	@Test
	void refusesAnEmptyDeckAndAnEmptySelection() throws Exception {
		seedDeck();

		mockMvc.perform(get("/api/v1/decks/{deckId}/export", "deck"))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.code").value("EXPORT_SCOPE_EMPTY"));

		mockMvc.perform(post("/api/v1/decks/{deckId}/export", "deck")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":[]}"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
	}

	@Test
	void refusesToExportADeckThatIsNotThere() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/export", "ghost"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
	}

	/** BR-170: the probe the import preview runs, and runs again inside the commit transaction. */
	@Test
	void publishesTheDuplicateKeysOfADeck() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);

		mockMvc.perform(get("/api/v1/decks/{deckId}/card-keys", "deck"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].frontFolded").value("front c1"))
				.andExpect(jsonPath("$[0].backFolded").value("back c1"));
	}

	/** An empty deck has no duplicate identities, which is an answer rather than a refusal. */
	@Test
	void publishesAnEmptyKeySetForADeckWithNoCards() throws Exception {
		seedDeck();

		mockMvc.perform(get("/api/v1/decks/{deckId}/card-keys", "deck"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(0));
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
