package com.memox.deck;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;

import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.support.PostgresIntegrationTest;

class DeckControllerTest extends PostgresIntegrationTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void returnsAnEmptyPageWhenNoRootDecksExist() throws Exception {
		mockMvc.perform(get("/api/v1/decks").param("size", "20"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items").isEmpty())
				.andExpect(jsonPath("$.totalItems").value(0))
				.andExpect(jsonPath("$.totalPages").value(0))
				.andExpect(jsonPath("$.hasNext").value(false))
				.andExpect(jsonPath("$.hasPrevious").value(false));
	}

	@Test
	void createsAndListsAClientIdentifiedRootDeck() throws Exception {
		final var deckId = UUID.randomUUID().toString();
		final var request = """
				{
				  "id": "%s",
				  "name": "  Korean basics  ",
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
	void retainsRootDeckTotalsWhenPageExceedsAvailableDecks() throws Exception {
		createRootDeck(UUID.randomUUID().toString(), "First root");
		createRootDeck(UUID.randomUUID().toString(), "Second root");

		mockMvc.perform(get("/api/v1/decks")
					.param("size", "1")
					.param("page", "100"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items").isEmpty())
				.andExpect(jsonPath("$.totalItems").value(2))
				.andExpect(jsonPath("$.totalPages").value(2))
				.andExpect(jsonPath("$.hasNext").value(false))
				.andExpect(jsonPath("$.hasPrevious").value(true));
	}

	/**
	 * The whole sort chain, end to end: query string, binding, enum whitelist, rendered ORDER BY.
	 *
	 * <p>Each layer is unit-tested on its own, and each of those tests would still pass if the
	 * layers were wired to each other wrongly — a sort that binds but is never applied looks
	 * exactly like a sort that works, until someone reads the second page.
	 */
	@Test
	void ordersRootDecksByTheRequestedFieldAndDirection() throws Exception {
		createRootDeck(UUID.randomUUID().toString(), "Beta");
		createRootDeck(UUID.randomUUID().toString(), "Alpha");
		createRootDeck(UUID.randomUUID().toString(), "Gamma");

		mockMvc.perform(get("/api/v1/decks").param("sort", "name:desc"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].name").value("Gamma"))
				.andExpect(jsonPath("$.items[1].name").value("Beta"))
				.andExpect(jsonPath("$.items[2].name").value("Alpha"));

		mockMvc.perform(get("/api/v1/decks").param("sort", "name"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].name").value("Alpha"))
				.andExpect(jsonPath("$.items[2].name").value("Gamma"));
	}

	@Test
	void rejectsASortFieldTheDeckEndpointDoesNotPublish() throws Exception {
		mockMvc.perform(get("/api/v1/decks").param("sort", "front"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.sort").value(
						"unknown sort field; allowed fields are siblingPosition, name, createdAt, updatedAt"));
	}

	/**
	 * The summaries endpoint end to end, including the response shape the Library screen reads.
	 *
	 * <p>`DeckSummaryTest` proves the counts; this proves they survive the trip out — a 16-field
	 * mapping where a swapped pair of counts is invisible to any assertion that only checks the
	 * page is non-empty.
	 */
	@Test
	void publishesRootDeckSummariesWithTheirCounts() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var childId = UUID.randomUUID().toString();
		createRootDeck(rootId, "Korean");
		createSubDeck(rootId, childId, "Unit 1");
		insertCardWithState(UUID.randomUUID().toString(), childId, null, null);

		mockMvc.perform(get("/api/v1/decks/summaries"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.items[0].id").value(rootId))
				.andExpect(jsonPath("$.items[0].name").value("Korean"))
				.andExpect(jsonPath("$.items[0].contentType").value("deck"))
				.andExpect(jsonPath("$.items[0].totalCardCount").value(1))
				.andExpect(jsonPath("$.items[0].newCardCount").value(1))
				.andExpect(jsonPath("$.items[0].dueCardCount").value(0))
				.andExpect(jsonPath("$.items[0].subDeckCount").value(1))
				.andExpect(jsonPath("$.items[0].oldestDueAt").doesNotExist())
				.andExpect(jsonPath("$.totalItems").value(1));
	}

	@Test
	void rejectsAUtcOffsetNoPlaceOnEarthUses() throws Exception {
		mockMvc.perform(get("/api/v1/decks/summaries").header("X-Utc-Offset-Minutes", "900"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors['X-Utc-Offset-Minutes']").exists());
	}

	@Test
	void publishesOneRootsWholeTreeAndNothingFromAnother() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var childId = UUID.randomUUID().toString();
		final var otherRootId = UUID.randomUUID().toString();
		createRootDeck(rootId, "Korean");
		createSubDeck(rootId, childId, "Unit 1");
		createRootDeck(otherRootId, "Japanese");

		mockMvc.perform(get("/api/v1/decks/{rootDeckId}/tree", rootId))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.length()").value(2))
				.andExpect(jsonPath("$[?(@.id == '%s')]".formatted(childId)).exists())
				.andExpect(jsonPath("$[?(@.id == '%s')]".formatted(otherRootId)).doesNotExist());
	}

	/**
	 * The level endpoint end to end: header, breadcrumb, child counts and the level's own timer.
	 *
	 * <p>Four response records map here for the first time, and the breadcrumb arrives through a
	 * JSON column and a type handler rather than through columns — so this is the only place that
	 * shows the ancestry surviving the whole trip.
	 */
	@Test
	void publishesADeckLevelWithItsBreadcrumbAndChildSubtreeCounts() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var midId = UUID.randomUUID().toString();
		final var leafId = UUID.randomUUID().toString();
		createRootDeck(rootId, "Korean");
		createSubDeck(rootId, midId, "Unit 1");
		createSubDeck(midId, leafId, "Lesson 1");
		insertCardWithState(UUID.randomUUID().toString(), leafId, null, null);

		mockMvc.perform(get("/api/v1/decks/{deckId}/level", rootId))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.parent.deckId").value(rootId))
				.andExpect(jsonPath("$.parent.deckName").value("Korean"))
				.andExpect(jsonPath("$.parent.ancestry").isEmpty())
				.andExpect(jsonPath("$.children[0].deck.id").value(midId))
				.andExpect(jsonPath("$.children[0].totalCardCount").value(1))
				.andExpect(jsonPath("$.children[0].subDeckCount").value(1))
				.andExpect(jsonPath("$.children[0].inheritedSchedulerType").value("sm2"));

		mockMvc.perform(get("/api/v1/decks/{deckId}/level", midId))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.parent.ancestry[0].id").value(rootId))
				.andExpect(jsonPath("$.parent.ancestry[0].name").value("Korean"))
				.andExpect(jsonPath("$.parent.ancestry[0].distance").value(1));
	}

	@Test
	void reordersSiblingsAndReturnsTheGroupInItsNewOrder() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var firstId = UUID.randomUUID().toString();
		final var secondId = UUID.randomUUID().toString();
		createRootDeck(rootId, "Korean");
		createSubDeck(rootId, firstId, "Unit 1");
		createSubDeck(rootId, secondId, "Unit 2");

		mockMvc.perform(put("/api/v1/decks/{deckId}/position", secondId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"targetPosition":0}"""))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$[0].id").value(secondId))
				.andExpect(jsonPath("$[0].siblingPosition").value(0))
				.andExpect(jsonPath("$[1].id").value(firstId))
				.andExpect(jsonPath("$[1].siblingPosition").value(1));
	}

	@Test
	void rejectsAReorderPastTheEndOfTheSiblingGroup() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		final var childId = UUID.randomUUID().toString();
		createRootDeck(rootId, "Korean");
		createSubDeck(rootId, childId, "Unit 1");

		mockMvc.perform(put("/api/v1/decks/{deckId}/position", childId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"targetPosition":5}"""))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("DECK_POSITION_OUT_OF_RANGE"));
	}

	@Test
	void returnsNotFoundForTheLevelOfADeckThatDoesNotExist() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/level", UUID.randomUUID()))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"));
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

	@Test
	void rejectsCreatingAnEleventhDeckLevel() throws Exception {
		final var rootId = UUID.randomUUID().toString();
		createRootDeck(rootId, "Root");
		var parentId = rootId;
		for (int depth = 2; depth <= 10; depth++) {
			final var childId = UUID.randomUUID().toString();
			createSubDeck(parentId, childId, "Level " + depth);
			parentId = childId;
		}

		mockMvc.perform(post("/api/v1/decks/{parentDeckId}/children", parentId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"Too deep"}
							""".formatted(UUID.randomUUID())))
				.andExpect(status().isConflict())
				.andExpect(jsonPath("$.code").value("DECK_DEPTH_EXCEEDED"));
	}

	private void createRootDeck(String deckId, String name) throws Exception {
		mockMvc.perform(post("/api/v1/decks")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"%s","schedulerType":"sm2"}
							""".formatted(deckId, name)))
				.andExpect(status().isCreated());
	}

	private void createSubDeck(String parentDeckId, String deckId, String name) throws Exception {
		mockMvc.perform(post("/api/v1/decks/{parentDeckId}/children", parentDeckId)
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"%s","name":"%s"}
							""".formatted(deckId, name)))
				.andExpect(status().isCreated());
	}
}
