package com.memox.contract;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

@AutoConfigureMockMvc
@SpringBootTest(properties = "spring.profiles.active=test")
class OpenApiContractTest {

	@Autowired
	private MockMvc mockMvc;

	@Test
	void publishesTheVersionedDeckAndCardContract() throws Exception {
		mockMvc.perform(get("/v3/api-docs"))
				.andExpect(status().isOk())
				.andExpect(jsonPath("$.info.title").value("MemoX API"))
				.andExpect(jsonPath("$.paths['/api/v1/decks'].get").exists())
				.andExpect(jsonPath("$.paths['/api/v1/decks'].post").exists())
				.andExpect(jsonPath("$.paths['/api/v1/decks/{deckId}/cards'].get").exists())
				.andExpect(jsonPath("$.paths['/api/v1/decks/{deckId}/cards'].post").exists());
	}
}
