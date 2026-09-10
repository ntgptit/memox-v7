package com.memox.tag;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class TagControllerTest extends PostgresIntegrationTest {

	private static final int TAG_CEILING = 10;

	@Autowired
	private MockMvc mockMvc;

	@Test
	void publishesTheCatalogWithItsActiveCardCount() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		insertTag("t-b", "beta");
		linkTag("c1", "t-a");

		mockMvc.perform(get("/api/v1/tags"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(2))
				.andExpect(jsonPath("$[0].id").value("t-a"))
				.andExpect(jsonPath("$[0].cardCount").value(1))
				.andExpect(jsonPath("$[1].cardCount").value(0));

		mockMvc.perform(get("/api/v1/tags").param("q", " BET "))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].id").value("t-b"));
	}

	@Test
	void renamesATagAndReportsTheRowThatSurvived() throws Exception {
		insertTag("t-a", "alpha");

		mockMvc.perform(patch("/api/v1/tags/{tagId}", "t-a")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"name":"  Alphabet  "}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.id").value("t-a"))
				.andExpect(jsonPath("$.name").value("Alphabet"));
	}

	@Test
	void refusesATagNameBr93Forbids() throws Exception {
		insertTag("t-a", "alpha");

		mockMvc.perform(patch("/api/v1/tags/{tagId}", "t-a")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"name":"   "}"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
	}

	@Test
	void deletesATagAndThenReportsItGone() throws Exception {
		insertTag("t-a", "alpha");

		mockMvc.perform(delete("/api/v1/tags/{tagId}", "t-a")).andExpect(status().isNoContent());

		mockMvc.perform(delete("/api/v1/tags/{tagId}", "t-a"))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("TAG_NOT_FOUND"));
	}

	/** BR-93: the folded name owns the tag, so a second spelling reuses the row rather than adding one. */
	@Test
	void attachesOneTagToABatchAndReusesTheRowOwningTheFoldedName() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);
		insertTag("t-a", "alpha");

		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1","c2"],"name":"Alpha"}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.id").value("t-a"))
				.andExpect(jsonPath("$.name").value("alpha"));

		assertThat(tagIdsOf("c1")).containsExactly("t-a");
		assertThat(tagIdsOf("c2")).containsExactly("t-a");
	}

	@Test
	void mintsATagTheLibraryDoesNotHaveYet() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);

		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1"],"name":"Động Từ"}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.name").value("Động Từ"));

		assertThat(tagIdsOf("c1")).hasSize(1);

		mockMvc.perform(get("/api/v1/tags").param("q", "động"))
				.andExpect(jsonPath("$.length()").value(1))
				.andExpect(jsonPath("$[0].cardCount").value(1));
	}

	/** BR-166: attaching a tag a card already carries writes nothing and still succeeds. */
	@Test
	void attachingTwiceIsIdempotent() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1"],"name":"alpha"}"""))
				.andExpect(status().isOk());

		assertThat(tagIdsOf("c1")).containsExactly("t-a");
	}

	/**
	 * BR-94 and BR-166: one card at the ceiling refuses the whole batch, and the card that was
	 * under it must not keep the tag — a partial tag is a state nobody asked for.
	 */
	@Test
	void refusesTheWholeBatchWhenOneCardIsAtTheCeiling() throws Exception {
		seedDeck();
		insertCardWithState("full", "deck", null, null);
		insertCardWithState("roomy", "deck", null, null);
		fillToTheCeiling("full");

		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["full","roomy"],"name":"eleventh"}"""))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.code").value("TAG_LIMIT_EXCEEDED"));

		assertThat(tagIdsOf("roomy")).isEmpty();
		assertThat(tagIdsOf("full")).hasSize(TAG_CEILING);
	}

	/**
	 * A card already carrying the tag stays where it is however full it is (BR-166), so a full card
	 * does not block a batch that would not have given it anything.
	 */
	@Test
	void letsAFullCardThroughWhenItAlreadyCarriesTheTag() throws Exception {
		seedDeck();
		insertCardWithState("full", "deck", null, null);
		fillToTheCeiling("full");

		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["full"],"name":"filler-0"}"""))
				.andExpect(status().isOk());

		assertThat(tagIdsOf("full")).hasSize(TAG_CEILING);
	}

	@Test
	void refusesToTagACardThatIsInTrash() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		softDelete("card", "c1");

		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":["c1"],"name":"alpha"}"""))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("CARD_NOT_FOUND"));
	}

	@Test
	void refusesABatchWithNoIds() throws Exception {
		mockMvc.perform(post("/api/v1/cards/bulk-tag")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"cardIds":[],"name":"alpha"}"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"));
	}

	/**
	 * Detaching needs the tag id, and every card projection carries names only — so the chips a card
	 * draws have to be readable with their ids from somewhere. This is that somewhere.
	 */
	@Test
	void publishesTheChipsOfOneCardWithTheirIds() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-v", "Verb");
		insertTag("t-a", "Adjective");
		linkTag("c1", "t-v");
		linkTag("c1", "t-a");

		mockMvc.perform(get("/api/v1/cards/{cardId}/tags", "c1"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(2))
				.andExpect(jsonPath("$[0].id").value("t-a"))
				.andExpect(jsonPath("$[0].name").value("Adjective"))
				.andExpect(jsonPath("$[1].id").value("t-v"));
	}

	/** Unlinking a pair that is not there is the same end state, so it is not an error. */
	@Test
	void detachesATagAndSaysTheSameThingTwice() throws Exception {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		mockMvc.perform(delete("/api/v1/cards/{cardId}/tags/{tagId}", "c1", "t-a"))
				.andExpect(status().isNoContent());
		mockMvc.perform(delete("/api/v1/cards/{cardId}/tags/{tagId}", "c1", "t-a"))
				.andExpect(status().isNoContent());

		assertThat(tagIdsOf("c1")).isEmpty();
		assertThat(tagExists("t-a")).isTrue();
	}

	private void fillToTheCeiling(final String cardId) {
		for (var index = 0; index < TAG_CEILING; index++) {
			insertTag("filler-" + index, "filler-" + index);
			linkTag(cardId, "filler-" + index);
		}
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
