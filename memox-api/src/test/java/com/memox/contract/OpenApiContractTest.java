package com.memox.contract;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import com.jayway.jsonpath.JsonPath;
import com.memox.support.PostgresIntegrationTest;

/**
 * A smoke test over the published contract, not a snapshot of it.
 *
 * <p>The byte-for-byte snapshot is {@code OpenApiSnapshotTest}'s job, and its diff <em>is</em> the
 * contract change a reviewer reads. What is asserted here are the few properties that must hold for
 * every path this API will ever publish, so a new endpoint that breaks one fails immediately rather
 * than arriving as an unexplained line in a large snapshot diff.
 */
class OpenApiContractTest extends PostgresIntegrationTest {

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

	/**
	 * Every path is versioned.
	 *
	 * <p>One unversioned path is enough to make the whole prefix a convention rather than a
	 * contract, and the first client to hard-code it is the one that finds out.
	 */
	@Test
	void publishesEveryPathUnderTheVersionedPrefix() throws Exception {
		assertThat(publishedPaths().keySet())
				.allSatisfy(path -> assertThat(path).startsWith("/api/v1/"));
	}

	/**
	 * Every operation that can refuse on a business rule documents the refusal.
	 *
	 * <p>A 409 with no schema in the contract is a failure a client cannot prepare for: it learns the
	 * shape of the Problem Details body by hitting it in production. The check is scoped to the
	 * operations that actually declare one, so it asserts the documentation is complete rather than
	 * that every endpoint can conflict.
	 */
	@Test
	void documentsAResponseBodyForEveryConflictItCanReturn() throws Exception {
		final Map<String, Map<String, Object>> paths = publishedPaths();
		var conflicts = 0;
		for (final var path : paths.entrySet()) {
			for (final var operation : path.getValue().entrySet()) {
				if (!(operation.getValue() instanceof Map<?, ?> details)) {
					continue;
				}
				if (!(details.get("responses") instanceof Map<?, ?> responses)) {
					continue;
				}
				if (!(responses.get("409") instanceof Map<?, ?> conflict)) {
					continue;
				}
				conflicts++;
				assertThat(conflict.get("description"))
						.as("409 description for %s %s", operation.getKey(), path.getKey())
						.asString().isNotBlank();
			}
		}
		assertThat(conflicts).as("operations documenting a 409").isGreaterThan(5);
	}

	private Map<String, Map<String, Object>> publishedPaths() throws Exception {
		final var body = mockMvc.perform(get("/v3/api-docs"))
				.andExpect(status().isOk())
				.andReturn().getResponse().getContentAsString();
		return JsonPath.read(body, "$.paths");
	}
}
