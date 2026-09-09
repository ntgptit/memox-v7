package com.memox.card;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.card.controller.CardController;
import com.memox.card.service.CardService;
import com.memox.common.config.PaginationProperties;
import com.memox.common.error.ApiExceptionHandler;
import com.memox.deck.exception.DeckNotFoundException;

import ch.qos.logback.classic.Logger;
import ch.qos.logback.classic.spi.ILoggingEvent;
import ch.qos.logback.core.read.ListAppender;

import org.slf4j.LoggerFactory;

@WebMvcTest(CardController.class)
@Import(ApiExceptionHandler.class)
@EnableConfigurationProperties(PaginationProperties.class)
class CardControllerWebMvcTest {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private CardService cardService;

	@Test
	void rejectsANegativePage() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.param("page", "-1"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.page").exists());
	}

	@Test
	void rejectsASizeAboveTheDocumentedMaximum() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.param("size", "101"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.size").exists());
	}

	/**
	 * The proof that sort has no string channel into SQL.
	 *
	 * <p>The payload is a working {@code ORDER BY} injection if the token were ever concatenated
	 * into a statement. It never reaches one: {@code SortSpecs} resolves against the
	 * {@code CardSortField} constants first and answers 400 for anything else, so the service is
	 * not called at all — which is why this runs as a WebMvc slice with a mocked service.
	 */
	@Test
	void rejectsASortTokenThatIsNotOneOfTheFeaturesFields() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.param("sort", "created_at ASC, (SELECT 1)"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.sort").value(
						"unknown sort field; allowed fields are front, createdAt, updatedAt"));

		verifyNoInteractions(cardService);
	}

	@Test
	void rejectsASortDirectionThatIsNeitherAscNorDesc() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.param("sort", "createdAt:sideways"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.sort").value("sort direction must be asc or desc"));
	}

	/**
	 * Pins why the field and its direction are joined by a colon rather than a comma.
	 *
	 * <p>Spring splits one query parameter into a {@code List<String>} on commas, so a comma here
	 * separates two sort keys and cannot also separate a key from its direction. This test states
	 * that as a property of the endpoint: one parameter, one comma, two sorts — and it fails if the
	 * binding behaviour it relies on ever changes, rather than the format quietly half-working.
	 */
	@Test
	void readsOneCommaSeparatedParameterAsSeveralSortKeys() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.param("sort", "createdAt:desc,front:sideways"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.fieldErrors.sort").value("sort direction must be asc or desc"));
	}

	/**
	 * The whole point of making the exception carry its id.
	 *
	 * <p>A 404 used to leave no server-side trace at all: the service threw, the handler answered,
	 * and the id that was not found existed nowhere afterwards. This asserts the property rather
	 * than the wording — the log line must contain the deck id — so rephrasing the message stays
	 * free while losing the id does not.
	 *
	 * <p>It also asserts the body gains no {@code deckId} property. The id does appear in the
	 * standard {@code instance} field, because that is the URI the client called and the id is a
	 * path variable in it — but nothing is <em>added</em> to the body for it. That is the whole
	 * split: the id is diagnostic, so it belongs in the log, and the response says only which
	 * rule refused the request.
	 */
	@Test
	void logsTheDeckIdItCouldNotFindWithoutAddingItToTheResponseBody() throws Exception {
		final var deckId = "11111111-1111-4111-8111-111111111111";
		final var logger = (Logger) LoggerFactory.getLogger(ApiExceptionHandler.class);
		final var recorded = new ListAppender<ILoggingEvent>();
		recorded.start();
		logger.addAppender(recorded);
		given(cardService.listCards(eq(deckId), any())).willThrow(new DeckNotFoundException(deckId));

		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", deckId))
				.andExpect(status().isNotFound())
				.andExpect(jsonPath("$.code").value("DECK_NOT_FOUND"))
				.andExpect(jsonPath("$.deckId").doesNotExist());

		logger.detachAppender(recorded);
		assertThat(recorded.list)
				.extracting(ILoggingEvent::getFormattedMessage)
				.anySatisfy(message -> assertThat(message).contains(deckId));
	}

	@Test
	void rejectsInvalidCardFieldsBeforeCallingTheService() throws Exception {
		mockMvc.perform(post("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.contentType(MediaType.APPLICATION_JSON)
					.content("""
							{"id":"not-a-uuid","front":"   ","back":"%s"}
							""".formatted("x".repeat(241))))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.id").exists())
				.andExpect(jsonPath("$.fieldErrors.front").exists())
				.andExpect(jsonPath("$.fieldErrors.back").exists());
	}
}
