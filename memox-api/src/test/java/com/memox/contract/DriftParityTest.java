package com.memox.contract;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Stream;

import org.junit.jupiter.api.Test;

/**
 * The parity document is a checked artifact, not a claim.
 *
 * <p>A table saying "these 69 statements were ported faithfully" is worth exactly as much as the
 * mechanism that keeps it true after the branch merges. These two tests are that mechanism: adding a
 * Drift query to a Phase 2 file without a parity row turns the suite red, and naming a MyBatis
 * statement that does not exist does the same.
 *
 * <p>Deliberately a plain unit test with no Spring context. It reads two files and compares two sets
 * of names; starting a container to do that would make the cheapest guard in the suite the slowest.
 */
class DriftParityTest {

	private static final Path DRIFT_QUERIES = Path.of("..", "lib", "core", "database", "queries");

	private static final Path PARITY_DOCUMENT =
			Path.of("..", "docs", "superpowers", "specs", "2026-09-09-drift-to-mybatis-parity.md");

	private static final Path MAPPERS = Path.of("src", "main", "resources", "mybatis");

	private static final List<String> PHASE_2_FILES =
			List.of("deck.drift", "card.drift", "tag.drift", "trash.drift");

	/** A named query in a {@code .drift} file: an identifier alone on a line, ending in a colon. */
	private static final Pattern DRIFT_QUERY =
			Pattern.compile("^([a-zA-Z][A-Za-z0-9_]*)(?:\\s+AS\\s+\\w+)?:\\s*$", Pattern.MULTILINE);

	private static final Pattern MAPPER_STATEMENT =
			Pattern.compile("<(?:select|insert|update|delete)\\s+id=\"([^\"]+)\"");

	/** A row of the parity table: {@code | `driftName` | `mapperId` | ... }. */
	private static final Pattern PARITY_ROW =
			Pattern.compile("^\\|\\s*`([^`]+)`\\s*\\|\\s*([^|]*)\\|", Pattern.MULTILINE);

	private static final Pattern BACKTICKED = Pattern.compile("`([^`]+)`");

	/**
	 * Every Phase 2 Drift query has a row.
	 *
	 * <p>Including the ones that were <em>not</em> ported: a row saying "not ported, and here is
	 * why" is the whole point. An unported statement with no row is indistinguishable from one
	 * nobody noticed, which is the state this document exists to make impossible.
	 */
	@Test
	void everyPhase2DriftQueryIsAccountedForInTheParityDocument() throws IOException {
		final var declared = driftQueryNames();
		assertThat(declared).as("Phase 2 Drift queries found").hasSizeGreaterThan(60);

		final var missing = new TreeSet<>(declared);
		missing.removeAll(parityDocumentQueryNames());
		assertThat(missing).as("Drift queries with no parity row").isEmpty();
	}

	/** Every MyBatis id the document names is a statement that exists. */
	@Test
	void everyDocumentedStatementExistsInAMapperXml() throws IOException {
		final var mapperIds = mapperStatementIds();
		assertThat(mapperIds).as("mapper statements found").hasSizeGreaterThan(60);

		final var documented = new TreeSet<>(parityDocumentStatementIds());
		documented.removeAll(mapperIds);
		assertThat(documented).as("documented statements that do not exist").isEmpty();
	}

	/**
	 * And the other direction: every statement that exists is documented.
	 *
	 * <p>Without this, a statement added later would simply be absent from the table — the same
	 * silence the first test refuses on the Drift side. The document has to describe the whole
	 * mapper, not a subset of it.
	 */
	@Test
	void everyMapperStatementAppearsInTheParityDocument() throws IOException {
		final var undocumented = new TreeSet<>(mapperStatementIds());
		undocumented.removeAll(parityDocumentStatementIds());
		assertThat(undocumented).as("mapper statements with no parity row").isEmpty();
	}

	private Set<String> driftQueryNames() throws IOException {
		final var names = new HashSet<String>();
		for (final var file : PHASE_2_FILES) {
			names.addAll(matches(DRIFT_QUERY, read(DRIFT_QUERIES.resolve(file))));
		}
		return names;
	}

	private Set<String> mapperStatementIds() throws IOException {
		try (Stream<Path> files = Files.list(MAPPERS)) {
			final var ids = new HashSet<String>();
			for (final var file : files.filter(path -> path.toString().endsWith(".xml")).toList()) {
				ids.addAll(matches(MAPPER_STATEMENT, read(file)));
			}
			return ids;
		}
	}

	private Set<String> parityDocumentQueryNames() throws IOException {
		return parityColumn(1);
	}

	private Set<String> parityDocumentStatementIds() throws IOException {
		return parityColumn(2);
	}

	private Set<String> parityColumn(int column) throws IOException {
		final var names = new HashSet<String>();
		final var rows = PARITY_ROW.matcher(read(PARITY_DOCUMENT));
		while (rows.find()) {
			if (column == 1) {
				names.add(rows.group(1));
				continue;
			}
			names.addAll(matches(BACKTICKED, rows.group(2)));
		}
		return names;
	}

	private List<String> matches(Pattern pattern, String text) {
		final Matcher matcher = pattern.matcher(text);
		final var found = new java.util.ArrayList<String>();
		while (matcher.find()) {
			found.add(matcher.group(1));
		}
		return found;
	}

	private String read(Path path) throws IOException {
		return Files.readString(path, StandardCharsets.UTF_8);
	}
}
