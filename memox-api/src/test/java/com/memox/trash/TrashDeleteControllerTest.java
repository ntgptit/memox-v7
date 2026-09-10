package com.memox.trash;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class TrashDeleteControllerTest extends PostgresIntegrationTest {

	@Autowired
	private MockMvc mockMvc;

	/** A soft-delete creates a batch, so it answers 201 with the resource it created. */
	@Test
	void movesADeckToTrashAndReportsTheBatchItOpened() throws Exception {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.UNSET);

		mockMvc.perform(delete("/api/v1/decks/{deckId}", "a"))
				.andExpect(status().isCreated())
				.andExpect(jsonPath("$.id").isNotEmpty())
				.andExpect(jsonPath("$.itemType").value("deck"))
				.andExpect(jsonPath("$.rootItemId").value("a"))
				.andExpect(jsonPath("$.deletedAt").isNotEmpty());
	}

	/** BR-256: a multi-item delete answers with one batch per item root. */
	@Test
	void movesABatchOfCardsToTrashAndReportsOneBatchEach() throws Exception {
		seedCardDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);

		mockMvc.perform(post("/api/v1/cards/bulk-delete")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1","c2"]}"""))
				.andExpect(status().isCreated())
				.andExpect(jsonPath("$.length()").value(2))
				.andExpect(jsonPath("$[0].itemType").value("card"))
				.andExpect(jsonPath("$[0].rootItemId").value("c1"))
				.andExpect(jsonPath("$[1].rootItemId").value("c2"));
	}

	@Test
	void refusesToDeleteADeckThatIsNotThere() throws Exception {
		mockMvc.perform(delete("/api/v1/decks/{deckId}", "ghost"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
	}

	@Test
	void refusesADeleteBatchWithNoIds() throws Exception {
		mockMvc.perform(post("/api/v1/cards/bulk-delete")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":[]}"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
	}

	/** The deleted deck leaves every active surface in the same instant (BR-257). */
	@Test
	void hidesTheDeckFromEveryActiveSurfaceOnceItIsDeleted() throws Exception {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.UNSET);

		mockMvc.perform(delete("/api/v1/decks/{deckId}", "a")).andExpect(status().isCreated());

		mockMvc.perform(delete("/api/v1/decks/{deckId}", "a"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
	}

	private void seedCardDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
