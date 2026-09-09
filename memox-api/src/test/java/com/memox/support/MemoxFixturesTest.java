package com.memox.support;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import java.time.Instant;

import org.junit.jupiter.api.Test;

import com.memox.deck.enums.DeckContentType;
import com.memox.deck.enums.SchedulerType;

/**
 * Tests the fixture vocabulary itself.
 *
 * <p>Roughly 186 planned test call sites depend on these methods. A fixture that seeds the wrong
 * shape does not fail here — it fails in whatever feature test happens to use it, as a defect in
 * that feature, which is the most expensive way to find a seeding bug. So the vocabulary is checked
 * once, where it is defined.
 */
class MemoxFixturesTest extends PostgresIntegrationTest {

	@Test
	void seedsARootDeckThatReadsBackThroughEveryAccessor() {
		insertRootDeck("root", "Korean", SchedulerType.SM2, 4);

		assertThat(deckExists("root")).isTrue();
		assertThat(rootDeckIdOf("root")).isEqualTo("root");
		assertThat(contentTypeOf("root")).isEqualTo(DeckContentType.DECK);
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT scheduler_type FROM decks WHERE id = ?", String.class, "root")).isEqualTo("sm2");
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT scheduler_generation FROM decks WHERE id = ?", Integer.class, "root")).isEqualTo(4);
	}

	/**
	 * The fixture's most likely failure mode, and the reason positions are assigned rather than
	 * defaulted: {@code uq_decks_sibling_scope_position} rejects two siblings at the same position,
	 * so a fixture that always wrote 0 would fail the second time any test seeded two children.
	 */
	@Test
	void givesEachSiblingItsOwnPositionWithinOneParent() {
		insertRootDeck("root", "Root");
		insertSubDeck("a", "A", "root", "root");
		insertSubDeck("b", "B", "root", "root");
		insertSubDeck("c", "C", "root", "root");

		assertThat(siblingPositionOf("a")).isZero();
		assertThat(siblingPositionOf("b")).isEqualTo(1);
		assertThat(siblingPositionOf("c")).isEqualTo(2);
	}

	@Test
	void countsPositionsPerParentRatherThanGlobally() {
		insertRootDeck("root", "Root");
		insertSubDeck("a", "A", "root", "root", DeckContentType.DECK);
		insertSubDeck("aa", "AA", "a", "root");

		assertThat(siblingPositionOf("a")).isZero();
		assertThat(siblingPositionOf("aa")).isZero();
	}

	@Test
	void placesASubDeckAtAnExactPositionWhenAsked() {
		insertRootDeck("root", "Root");
		insertSubDeckAt("far", "Far", "root", "root", 7);

		assertThat(siblingPositionOf("far")).isEqualTo(7);
	}

	/**
	 * The depth-limit tests need ten legal levels, not ten rows. Every deck but the last must hold
	 * sub-decks, or the chain contradicts the content-type rule it is used to exercise.
	 */
	@Test
	void buildsALegalChainWhoseOnlyUnsetDeckIsTheLeaf() {
		insertChain(10);

		assertThat(deckExists("d1")).isTrue();
		assertThat(deckExists("d10")).isTrue();
		assertThat(rootDeckIdOf("d10")).isEqualTo("d1");
		assertThat(contentTypeOf("d9")).isEqualTo(DeckContentType.DECK);
		assertThat(contentTypeOf("d10")).isEqualTo(DeckContentType.UNSET);
	}

	@Test
	void inheritsTheRootSchedulerWhenSeedingACardState() {
		insertRootDeck("root", "Root", SchedulerType.SM2, 3);
		insertSubDeck("leaf", "Leaf", "root", "root", DeckContentType.CARD);
		final var dueAt = Instant.parse("2026-01-02T03:04:05Z");

		insertCardWithState("card", "leaf", null, dueAt);

		assertThat(deckIdOf("card")).isEqualTo("leaf");
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT scheduler_type FROM card_study_states WHERE card_id = ?", String.class, "card"))
				.isEqualTo("sm2");
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT scheduler_generation FROM card_study_states WHERE card_id = ?", Integer.class, "card"))
				.isEqualTo(3);
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT due_at FROM card_study_states WHERE card_id = ?", Instant.class, "card")).isEqualTo(dueAt);
	}

	/**
	 * A null {@code learned_at} is what makes a card new rather than merely undue (BR-90, BR-151).
	 * A fixture that substituted "now" would silently turn every new-card test into a learned-card
	 * test — one of the three causes that left the integration suite broken for seventy PRs.
	 */
	@Test
	void keepsANullLearnedAtNull() {
		insertRootDeck("root", "Root");
		insertSubDeck("leaf", "Leaf", "root", "root", DeckContentType.CARD);

		insertCardWithState("card", "leaf", null, null);

		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT learned_at FROM card_study_states WHERE card_id = ?", Instant.class, "card")).isNull();
	}

	@Test
	void seedsAFlaggedCardThatReadsBackAsFlagged() {
		insertRootDeck("root", "Root");
		insertSubDeck("leaf", "Leaf", "root", "root", DeckContentType.CARD);

		insertFlaggedCard("flagged", "leaf");
		insertCardWithState("plain", "leaf", null, null);

		assertThat(flaggedOf("flagged")).isTrue();
		assertThat(flaggedOf("plain")).isFalse();
		assertThat(cardExists("flagged")).isTrue();
	}

	@Test
	void foldsATagNameForSearchAndLinksItToACard() {
		insertRootDeck("root", "Root");
		insertSubDeck("leaf", "Leaf", "root", "root", DeckContentType.CARD);
		insertCardWithState("card", "leaf", null, null);
		insertTag("t1", "  Grammar  ");
		insertTag("t2", "Verbs");

		linkTag("card", "t2");
		linkTag("card", "t1");

		assertThat(tagExists("t1")).isTrue();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT name_folded FROM tags WHERE id = ?", String.class, "t1")).isEqualTo("grammar");
		assertThat(tagIdsOf("card")).containsExactly("t1", "t2");
	}

	/**
	 * One row, not a subtree. Cascading a soft delete is the trash service's job and therefore the
	 * behaviour under test; a fixture that did it too would make a service that forgot to cascade
	 * look correct.
	 */
	@Test
	void softDeleteStampsOnlyTheNamedRow() {
		insertRootDeck("root", "Root");
		insertSubDeck("child", "Child", "root", "root");

		softDelete("deck", "root");

		assertThat(batchIdOfDeck("root")).isNotNull();
		assertThat(batchIdOfDeck("child")).isNull();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT item_type FROM delete_batches WHERE id = ?", String.class, batchIdOfDeck("root")))
				.isEqualTo("deck");
	}

	@Test
	void softDeletesACardThroughTheSameEntryPoint() {
		insertRootDeck("root", "Root");
		insertSubDeck("leaf", "Leaf", "root", "root", DeckContentType.CARD);
		insertCardWithState("card", "leaf", null, null);

		softDelete("card", "card");

		assertThat(batchIdOfCard("card")).isNotNull();
	}

	@Test
	void refusesAnItemTypeThatIsNeitherDeckNorCard() {
		assertThatThrownBy(() -> softDelete("tag", "whatever"))
				.isInstanceOf(IllegalArgumentException.class)
				.hasMessageContaining("deck or card");
	}

	@Test
	void agesABatchIntoThePast() {
		insertRootDeck("root", "Root");
		softDelete("deck", "root");
		final var batchId = batchIdOfDeck("root");
		final var before = this.jdbcTemplate.queryForObject(
				"SELECT deleted_at FROM delete_batches WHERE id = ?", Instant.class, batchId);

		backdateBatch(batchId, Duration.ofDays(31));

		final var after = this.jdbcTemplate.queryForObject(
				"SELECT deleted_at FROM delete_batches WHERE id = ?", Instant.class, batchId);
		assertThat(after).isBefore(before.minus(Duration.ofDays(30)));
	}

	/** Produces the orphaned-batch state the services refuse to create and must still survive. */
	@Test
	void revivesADeckAndLeavesItsBatchBehind() {
		insertRootDeck("root", "Root");
		softDelete("deck", "root");
		final var batchId = batchIdOfDeck("root");

		reviveDeckWithoutBatch("root");

		assertThat(batchIdOfDeck("root")).isNull();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT COUNT(*) FROM delete_batches WHERE id = ?", Integer.class, batchId)).isEqualTo(1);
	}

	@Test
	void reportsAbsentRowsAsAbsent() {
		assertThat(deckExists("nope")).isFalse();
		assertThat(cardExists("nope")).isFalse();
		assertThat(tagExists("nope")).isFalse();
	}
}
