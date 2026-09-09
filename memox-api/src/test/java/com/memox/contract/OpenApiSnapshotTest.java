package com.memox.contract;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.TreeMap;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.test.web.servlet.MockMvc;

import com.fasterxml.jackson.core.util.DefaultIndenter;
import com.fasterxml.jackson.core.util.DefaultPrettyPrinter;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.memox.support.PostgresIntegrationTest;

/**
 * The API contract gate: the committed {@code openapi.json} must match what the app publishes.
 *
 * <p>The module's design spec promised "a canonical exported OpenAPI JSON file is committed and
 * diffed in CI". Neither existed. {@link OpenApiContractTest} asserted that four paths were
 * present, which a renamed field, a changed status code or a dropped required property all pass
 * unchanged — a smoke test, not a contract diff. This is the diff.
 *
 * <p>Exported through MockMvc rather than {@code springdoc-openapi-maven-plugin}: the plugin needs
 * the application actually started and stopped around the build, while the integration suite
 * already has a booted context. One fewer moving part, and the document comes from the same
 * configuration the other tests exercise.
 */
class OpenApiSnapshotTest extends PostgresIntegrationTest {

	/**
	 * Module root, not {@code src/main/resources}: the snapshot is a reviewable artifact, not a
	 * runtime resource, and it must not be packaged into the jar.
	 */
	private static final Path SNAPSHOT = Path.of("openapi.json");

	/** {@code ./mvnw -Dmemox.openapi.write=true -Dtest=OpenApiSnapshotTest test} rewrites it. */
	private static final String WRITE_PROPERTY = "memox.openapi.write";

	@Autowired
	private MockMvc mockMvc;

	@Test
	void publishedContractMatchesTheCommittedSnapshot() throws Exception {
		final var published = canonicalise(fetchDocument());

		if (Boolean.getBoolean(WRITE_PROPERTY)) {
			Files.writeString(SNAPSHOT, published, StandardCharsets.UTF_8);
			return;
		}

		assertThat(SNAPSHOT)
				.as("No committed contract. Generate it with: ./mvnw -D%s=true -Dtest=%s test",
						WRITE_PROPERTY, getClass().getSimpleName())
				.exists();

		assertThat(Files.readString(SNAPSHOT, StandardCharsets.UTF_8).replace("\r\n", "\n"))
				.as("The published API no longer matches %s. If the change is intended, regenerate "
						+ "with ./mvnw -D%s=true -Dtest=%s test and commit the diff — that diff IS the "
						+ "contract change, and it is what a reviewer reads.",
						SNAPSHOT, WRITE_PROPERTY, getClass().getSimpleName())
				.isEqualTo(published);
	}

	private String fetchDocument() throws Exception {
		return this.mockMvc.perform(get("/v3/api-docs"))
				.andExpect(status().isOk())
				.andReturn()
				.getResponse()
				.getContentAsString(StandardCharsets.UTF_8);
	}

	/**
	 * Sorts every object key and drops {@code servers}.
	 *
	 * <p>Both are about determinism rather than tidiness. springdoc does not promise a stable key
	 * order between runs, and {@code servers} carries the host and port the document was generated
	 * against — which differs between a Testcontainers port, a local one and CI, and would make the
	 * snapshot fail for reasons that have nothing to do with the contract.
	 */
	private String canonicalise(String document) throws Exception {
		final var mapper = new ObjectMapper().enable(SerializationFeature.ORDER_MAP_ENTRIES_BY_KEYS);
		@SuppressWarnings("unchecked")
		final var parsed = (Map<String, Object>) mapper.readValue(document, Map.class);
		final var sorted = new TreeMap<>(parsed);
		sorted.remove("servers");
		return mapper.writer(lineFeedPrinter()).writeValueAsString(sorted) + "\n";
	}

	/**
	 * A pretty printer pinned to LF, because the default one uses the platform separator.
	 *
	 * <p>Caught by this test on its first real run: the snapshot was written with CRLF on Windows
	 * while the comparison normalised only the file side, so it failed against a document that was
	 * byte-identical in content. The deeper problem is the one that would have followed —
	 * CI regenerating on Linux and a developer regenerating on Windows would flip every line of the
	 * committed file back and forth, and a contract diff nobody can read is a contract diff nobody
	 * reviews. Pinning the separator makes the artifact the same on both.
	 */
	private DefaultPrettyPrinter lineFeedPrinter() {
		final var indenter = new DefaultIndenter("  ", "\n");
		final var printer = new DefaultPrettyPrinter();
		printer.indentObjectsWith(indenter);
		printer.indentArraysWith(indenter);
		return printer;
	}
}
