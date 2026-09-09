package com.memox.card;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.card.entity.CardFilter;
import com.memox.card.entity.CardListItem;
import com.memox.card.entity.StageThresholds;
import com.memox.card.enums.CardSortField;
import com.memox.card.service.CardQueryService;
import com.memox.common.pagination.PageQuery;
import com.memox.common.pagination.SortDirection;
import com.memox.common.pagination.SortSpec;
import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class CardListTest extends PostgresIntegrationTest {

	private static final Instant LEARNED = Instant.parse("2026-09-01T00:00:00Z");

	/** Boxes and intervals chosen to land one card in each stage under StageThresholds.DEFAULTS. */
	private static final int LEARNING_BOX = 1;
	private static final int REVIEWING_BOX = 4;
	private static final int MASTERED_BOX = 8;
	private static final int LEARNING_DAYS = 3;
	private static final int MASTERED_DAYS = 200;

	@Autowired
	private CardQueryService cardQueryService;

	/** Translation row 1: an aggregate has no order unless it is given one. */
	@Test
	void joinsTagNamesInAStableOrder() {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);
		insertTag("t-b", "beta");
		insertTag("t-a", "alpha");
		linkTag("card-1", "t-b");
		linkTag("card-1", "t-a");

		final var page = cardQueryService.list(CardFilter.ofDeck("deck"), page());

		assertThat(page.getItems()).singleElement()
				.extracting(CardListItem::tagNames)
				.isEqualTo(List.of("alpha", "beta"));
	}

	@Test
	void returnsAnEmptyTagListForACardWithNoTags() {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);

		assertThat(cardQueryService.list(CardFilter.ofDeck("deck"), page()).getItems())
				.singleElement().extracting(CardListItem::tagNames).isEqualTo(List.of());
	}

	/** BR-231 OR-semantics, BR-252 one row per card however many of its tags matched. */
	@Test
	void matchesACardOnceWhenTwoOfItsTagsAreSelected() {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);
		insertTag("t-a", "alpha");
		insertTag("t-b", "beta");
		linkTag("card-1", "t-a");
		linkTag("card-1", "t-b");

		final var filter = CardFilter.ofDeck("deck").withTagIds(List.of("t-a", "t-b"));

		assertThat(cardQueryService.list(filter, page()).getTotalItems()).isEqualTo(1);
	}

	@Test
	void treatsAnEmptyTagListAsNoTagFilterRatherThanMatchNothing() {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);

		final var filter = CardFilter.ofDeck("deck").withTagIds(List.of());

		assertThat(cardQueryService.list(filter, page()).getTotalItems()).isEqualTo(1);
	}

	@Test
	void filtersOnTheFlagInBothDirectionsAndNotAtAllWhenUnset() {
		seedDeck();
		insertCardWithState("plain", "deck", null, null);
		insertFlaggedCard("flagged", "deck");
		insertCardStateFor("flagged");

		assertThat(ids(CardFilter.ofDeck("deck").withFlagged(true))).containsExactly("flagged");
		assertThat(ids(CardFilter.ofDeck("deck").withFlagged(false))).containsExactly("plain");
		assertThat(ids(CardFilter.ofDeck("deck"))).containsExactlyInAnyOrder("plain", "flagged");
	}

	@Test
	void reachesTheWholeSubtreeOnlyWhenAsked() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("nested", "Lesson 1", "deck", "root", DeckContentType.CARD);
		insertCardWithState("deep", "nested", null, null);

		assertThat(ids(CardFilter.ofDeck("deck"))).isEmpty();
		assertThat(ids(CardFilter.ofDeck("deck").includingSubtree())).containsExactly("deep");
	}

	/** Translation row 4: {@code instr} does not exist in PostgreSQL; {@code strpos} is the port. */
	@Test
	void searchesBothFoldedFacesAndIgnoresCase() {
		seedDeck();
		insertCardWithState("card-1", "deck", null, null);

		assertThat(ids(CardFilter.ofDeck("deck").searchingFor("front card-1"))).containsExactly("card-1");
		assertThat(ids(CardFilter.ofDeck("deck").searchingFor("back card-1"))).containsExactly("card-1");
		assertThat(ids(CardFilter.ofDeck("deck").searchingFor("nothing here"))).isEmpty();
	}

	@Test
	void leavesSoftDeletedCardsOutOfTheListAndTheCount() {
		seedDeck();
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("gone", "deck", null, null);
		softDelete("card", "gone");

		final var page = cardQueryService.list(CardFilter.ofDeck("deck"), page());

		assertThat(page.getTotalItems()).isEqualTo(1);
		assertThat(page.getItems()).extracting(CardListItem::id).containsExactly("kept");
	}

	/**
	 * The port's sharpest difference from SQLite, and the one the plan had backwards.
	 *
	 * <p>A card with no {@code due_at} is NEW — due now — so "soonest due first" must put it at the
	 * front. SQLite sorts NULLs first ascending and the Dart source relies on exactly that;
	 * PostgreSQL sorts them last and would bury the most urgent cards at the end. The plan specified
	 * {@code s.due_at ASC NULLS LAST}, which is the opposite of what the app means.
	 */
	@Test
	void putsNewCardsFirstWhenSortingBySoonestDue() {
		seedDeck();
		insertCardWithState("brand-new", "deck", null, null);
		insertCardWithState("due-soon", "deck", LEARNED, Instant.parse("2026-09-11T00:00:00Z"));
		insertCardWithState("due-later", "deck", LEARNED, Instant.parse("2026-10-31T00:00:00Z"));

		final var sorted = cardQueryService.list(CardFilter.ofDeck("deck"),
				PageQuery.<CardSortField>builder()
						.sort(new SortSpec<>(CardSortField.DUE_AT, SortDirection.ASC))
						.build());

		assertThat(sorted.getItems()).extracting(CardListItem::id)
				.containsExactly("brand-new", "due-soon", "due-later");
	}

	@Test
	void ordersNewestFirstByDefault() {
		seedDeck();
		insertCardWithState("older", "deck", null, null);
		insertCardWithState("newer", "deck", null, null);
		this.jdbcTemplate.update("UPDATE cards SET created_at = ? WHERE id = 'older'",
				java.sql.Timestamp.from(Instant.parse("2026-01-01T00:00:00Z")));

		assertThat(ids(CardFilter.ofDeck("deck"))).containsExactly("newer", "older");
	}

	/** "Select all" means all of the filter, not the page currently on screen. */
	@Test
	void returnsEveryMatchingIdRegardlessOfThePageSize() {
		seedDeck();
		insertCardWithState("a", "deck", null, null);
		insertCardWithState("b", "deck", null, null);
		insertCardWithState("c", "deck", null, null);

		final var onePage = PageQuery.<CardSortField>builder().size(1).build();

		assertThat(cardQueryService.list(CardFilter.ofDeck("deck"), onePage).getItems()).hasSize(1);
		assertThat(cardQueryService.idsMatching(CardFilter.ofDeck("deck"), onePage)).hasSize(3);
	}

	/** The four stages partition the deck's active cards, so they sum to its total. */
	@Test
	void partitionsTheDeckIntoFourStages() {
		seedDeck();
		insertCardWithState("new-card", "deck", null, null);
		insertCardWithState("learning", "deck", LEARNED, null);
		insertCardWithState("reviewing", "deck", LEARNED, null);
		insertCardWithState("mastered", "deck", LEARNED, null);
		setBox("learning", LEARNING_BOX);
		setBox("reviewing", REVIEWING_BOX);
		setBox("mastered", MASTERED_BOX);

		final var counts = cardQueryService.stateCounts("deck", StageThresholds.DEFAULTS);

		assertThat(counts.newCount()).isEqualTo(1);
		assertThat(counts.learningCount()).isEqualTo(1);
		assertThat(counts.reviewingCount()).isEqualTo(1);
		assertThat(counts.masteredCount()).isEqualTo(1);
	}

	@Test
	void countsSm2CardsByIntervalRatherThanByBox() {
		insertRootDeck("root", "Korean", com.memox.common.scheduler.SchedulerType.SM2);
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("learning", "deck", LEARNED, null);
		insertCardWithState("mastered", "deck", LEARNED, null);
		setInterval("learning", LEARNING_DAYS);
		setInterval("mastered", MASTERED_DAYS);

		final var counts = cardQueryService.stateCounts("deck", StageThresholds.DEFAULTS);

		assertThat(counts.learningCount()).isEqualTo(1);
		assertThat(counts.masteredCount()).isEqualTo(1);
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}

	private List<String> ids(final CardFilter filter) {
		return cardQueryService.idsMatching(filter, page());
	}

	private PageQuery<CardSortField> page() {
		return PageQuery.<CardSortField>builder().build();
	}

	/** insertFlaggedCard writes no study state, and the list statement joins one. */
	private void insertCardStateFor(final String cardId) {
		this.jdbcTemplate.update("""
				INSERT INTO card_study_states (card_id, scheduler_type, scheduler_version,
				                               scheduler_generation)
				VALUES (?, 'eight_box', 1, 1)""", cardId);
	}

	private void setBox(final String cardId, final int box) {
		this.jdbcTemplate.update("UPDATE card_study_states SET current_box = ? WHERE card_id = ?", box, cardId);
	}

	private void setInterval(final String cardId, final int days) {
		this.jdbcTemplate.update(
				"UPDATE card_study_states SET interval_days = ? WHERE card_id = ?", days, cardId);
	}
}
