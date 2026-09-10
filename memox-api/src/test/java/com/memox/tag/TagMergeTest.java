package com.memox.tag;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;
import com.memox.tag.exception.TagNotFoundException;
import com.memox.tag.service.RenameTagCommand;
import com.memox.tag.service.TagCatalogService;

class TagMergeTest extends PostgresIntegrationTest {

	@Autowired
	private TagCatalogService tagCatalogService;

	/** BR-234: one transaction, and a card carrying both tags keeps one row rather than failing. */
	@Test
	void mergesIntoTheExistingTagWhenTheFoldedNameCollides() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertCardWithState("c2", "deck", null, null);
		insertTag("src", "Bravo");
		insertTag("dst", "alpha");
		linkTag("c1", "src");
		linkTag("c2", "src");
		linkTag("c2", "dst");

		assertThat(tagCatalogService.rename(new RenameTagCommand("src", "alpha")).id()).isEqualTo("dst");

		assertThat(tagIdsOf("c1")).containsExactly("dst");
		assertThat(tagIdsOf("c2")).containsExactly("dst");
		assertThat(tagExists("src")).isFalse();
	}

	/**
	 * BR-237, the half the catalog's count does not cover: a merge must carry a hidden card's link
	 * across, so restoring it from Trash gets the tag back rather than a card stripped of metadata
	 * while it was not being looked at.
	 */
	@Test
	void carriesTheLinksOfATrashedCardThroughAMerge() {
		seedDeck();
		insertCardWithState("hidden", "deck", null, null);
		insertTag("src", "Bravo");
		insertTag("dst", "alpha");
		linkTag("hidden", "src");
		softDelete("card", "hidden");

		tagCatalogService.rename(new RenameTagCommand("src", "alpha"));

		assertThat(tagIdsOf("hidden")).containsExactly("dst");
	}

	/**
	 * BR-233: a rename that only changes the case is a rename, not a merge with itself.
	 *
	 * <p>The folded name is unchanged, so the collision probe finds the tag being renamed. Treating
	 * that as a merge would delete the row it was asked to rename and leave every card untagged.
	 */
	@Test
	void acceptsACaseOnlyRenameWithoutTouchingTheIdOrTheLinks() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		final var renamed = tagCatalogService.rename(new RenameTagCommand("t-a", "Alpha"));

		assertThat(renamed.id()).isEqualTo("t-a");
		assertThat(renamed.name()).isEqualTo("Alpha");
		assertThat(tagIdsOf("c1")).containsExactly("t-a");
	}

	@Test
	void refusesToRenameATagThatIsNotThere() {
		assertThatThrownBy(() -> tagCatalogService.rename(new RenameTagCommand("ghost", "alpha")))
				.isInstanceOf(TagNotFoundException.class);
	}

	/** BR-235: only {@code card_tags} and the {@code tags} row go. The cards stay. */
	@Test
	void deletingATagLeavesEveryCardIntact() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		tagCatalogService.delete("t-a");

		assertThat(cardExists("c1")).isTrue();
		assertThat(tagIdsOf("c1")).isEmpty();
		assertThat(tagExists("t-a")).isFalse();
	}

	@Test
	void refusesToDeleteATagThatIsNotThere() {
		assertThatThrownBy(() -> tagCatalogService.delete("ghost"))
				.isInstanceOf(TagNotFoundException.class);
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
