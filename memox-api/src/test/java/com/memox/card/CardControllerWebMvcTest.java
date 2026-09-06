package com.memox.card;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.memox.card.api.CardController;
import com.memox.card.service.CardService;
import com.memox.common.config.PaginationProperties;
import com.memox.common.error.ApiExceptionHandler;

@WebMvcTest(CardController.class)
@Import(ApiExceptionHandler.class)
@EnableConfigurationProperties(PaginationProperties.class)
class CardControllerWebMvcTest {

	@Autowired
	private MockMvc mockMvc;

	@MockitoBean
	private CardService cardService;

	@Test
	void rejectsNegativeOffset() throws Exception {
		mockMvc.perform(get("/api/v1/decks/{deckId}/cards", "11111111-1111-4111-8111-111111111111")
					.param("offset", "-1"))
				.andExpect(status().isBadRequest())
				.andExpect(jsonPath("$.code").value("VALIDATION_FAILED"))
				.andExpect(jsonPath("$.fieldErrors.offset").exists());
	}
}
