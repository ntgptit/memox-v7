package com.memox.tag;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.error.ValidationFailedException;
import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;
import com.memox.tag.entity.TagCatalogEntry;
import com.memox.tag.entity.TagName;
import com.memox.tag.service.TagCatalogService;

class TagCatalogTest extends PostgresIntegrationTest {

	private static final int OVER_THE_NAME_LIMIT = 51;

	@Autowired
	private TagCatalogService tagCatalogService;

	/**
	 * BR-237: a card hidden in Trash is not an active card, so it must not inflate the count.
	 *
	 * <p>This is a deliberate divergence from Drift, whose {@code tagCatalog} counts {@code card_tags}
	 * rows without joining {@code cards}.
	 */
	@Test
	void countsOnlyActiveCardsAgainstATag() {
		seedDeck();
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("trashed", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("kept", "t-a");
		linkTag("trashed", "t-a");
		softDelete("card", "trashed");

		assertThat(tagCatalogService.catalog("")).singleElement()
				.extracting(TagCatalogEntry::cardCount).isEqualTo(1L);
	}

	/** Translation row 4: {@code instr} does not exist in PostgreSQL; {@code strpos} is the port. */
	@Test
	void filtersTheCatalogOnTheFoldedName() {
		insertTag("t-a", "Alpha");
		insertTag("t-b", "Beta");

		assertThat(tagCatalogService.catalog("alp"))
				.extracting(TagCatalogEntry::id).containsExactly("t-a");
	}

	/**
	 * BR-230: ordered by the folded name, not the spelling.
	 *
	 * <p>Ordering by {@code name} puts "Verb" before "adjective" in a byte-ordered collation and
	 * reads as random to whoever typed both. The folded column is also the one BR-93's uniqueness is
	 * measured in, so the catalog's order and its identity agree by construction.
	 */
	@Test
	void ordersTheCatalogByTheFoldedNameRatherThanTheSpelling() {
		insertTag("t-v", "Verb");
		insertTag("t-a", "adjective");

		assertThat(tagCatalogService.catalog(""))
				.extracting(TagCatalogEntry::name).containsExactly("adjective", "Verb");
	}

	@Test
	void returnsAZeroCountForATagNoCardCarries() {
		insertTag("t-a", "alpha");

		assertThat(tagCatalogService.catalog("")).singleElement()
				.extracting(TagCatalogEntry::cardCount).isEqualTo(0L);
	}

	/** BR-93: trimmed, non-blank, at most 50 characters, no control characters. */
	@Test
	void normalisesATagNameAndRefusesTheOnesBr93Forbids() {
		assertThat(TagName.of("  Động Từ  ").value()).isEqualTo("Động Từ");
		assertThat(TagName.of("  Động Từ  ").folded()).isEqualTo("động từ");

		assertThatThrownBy(() -> TagName.of("   ")).isInstanceOf(ValidationFailedException.class);
		assertThatThrownBy(() -> TagName.of(null)).isInstanceOf(ValidationFailedException.class);
		assertThatThrownBy(() -> TagName.of("a".repeat(OVER_THE_NAME_LIMIT)))
				.isInstanceOf(ValidationFailedException.class);
		assertThatThrownBy(() -> TagName.of("alpha\tbeta"))
				.isInstanceOf(ValidationFailedException.class);
	}

	/**
	 * The fold is case-insensitive beyond ASCII, which is the whole reason it exists.
	 *
	 * <p>SQLite's own {@code lower()} folds ASCII only, so a Vietnamese or Korean tag would compare
	 * as distinct from its own capitalisation. Java's {@code toLowerCase} does not have that limit,
	 * and BR-93's uniqueness is measured in the folded value.
	 */
	@Test
	void foldsBeyondAsciiSoBr93sUniquenessHoldsForEveryScript() {
		assertThat(TagName.of("Động Từ").folded()).isEqualTo(TagName.of("động từ").folded());
		assertThat(TagName.of("ÁNH").folded()).isEqualTo(TagName.of("ánh").folded());
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
