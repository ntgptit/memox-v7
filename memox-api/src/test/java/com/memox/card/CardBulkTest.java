package com.memox.card;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import java.util.stream.IntStream;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.card.exception.CardConflictException;
import com.memox.card.exception.CardNotFoundException;
import com.memox.card.service.BulkFlagCommand;
import com.memox.card.service.BulkMoveCommand;
import com.memox.card.service.CardBulkService;
import com.memox.card.service.CardEditService;
import com.memox.card.service.UpdateCardCommand;
import com.memox.common.error.ApiErrorCode;
import com.memox.common.error.ValidationFailedException;
import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class CardBulkTest extends PostgresIntegrationTest {

	private static final int OVER_THE_CAP = 501;

	@Autowired
	private CardBulkService cardBulkService;

	@Autowired
	private CardEditService cardEditService;

	/** BR-163: the source falls back to unset the moment it loses its last card. */
	@Test
	void movesEveryCardAndLeavesTheEmptiedSourceUnset() {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 2", "root", "root", DeckContentType.UNSET);
		insertCardWithState("c1", "src", null, null);
		insertCardWithState("c2", "src", null, null);

		assertThat(cardBulkService.move(new BulkMoveCommand(List.of("c1", "c2"), "dst"))).isEqualTo(2);

		assertThat(deckIdOf("c1")).isEqualTo("dst");
		assertThat(deckIdOf("c2")).isEqualTo("dst");
		assertThat(contentTypeOf("src")).isEqualTo(DeckContentType.UNSET);
		assertThat(contentTypeOf("dst")).isEqualTo(DeckContentType.CARD);
	}

	@Test
	void leavesASourceThatStillHoldsCardsAlone() {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 2", "root", "root", DeckContentType.CARD);
		insertCardWithState("moving", "src", null, null);
		insertCardWithState("staying", "src", null, null);

		cardBulkService.move(new BulkMoveCommand(List.of("moving"), "dst"));

		assertThat(contentTypeOf("src")).isEqualTo(DeckContentType.CARD);
	}

	/** Cards may come from several decks at once; each emptied one is maintained. */
	@Test
	void maintainsEverySourceDeckTheBatchEmptied() {
		insertRootDeck("root", "Korean");
		insertSubDeck("a", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("b", "Unit 2", "root", "root", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 3", "root", "root", DeckContentType.UNSET);
		insertCardWithState("from-a", "a", null, null);
		insertCardWithState("from-b", "b", null, null);

		cardBulkService.move(new BulkMoveCommand(List.of("from-a", "from-b"), "dst"));

		assertThat(contentTypeOf("a")).isEqualTo(DeckContentType.UNSET);
		assertThat(contentTypeOf("b")).isEqualTo(DeckContentType.UNSET);
	}

	/** BR-166: one violating card rolls the whole batch back. */
	@Test
	void rollsBackTheWholeBatchWhenOneCardBelongsToAnotherRoot() {
		insertRootDeck("r1", "Korean");
		insertRootDeck("r2", "Japanese");
		insertSubDeck("src", "Unit 1", "r1", "r1", DeckContentType.CARD);
		insertSubDeck("other", "Unit 1", "r2", "r2", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 2", "r1", "r1", DeckContentType.UNSET);
		insertCardWithState("ok", "src", null, null);
		insertCardWithState("foreign", "other", null, null);

		assertThatThrownBy(() -> cardBulkService.move(new BulkMoveCommand(List.of("ok", "foreign"), "dst")))
				.isInstanceOf(CardConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.CARD_CROSS_ROOT_MOVE);

		assertThat(deckIdOf("ok")).isEqualTo("src");
		assertThat(contentTypeOf("dst")).isEqualTo(DeckContentType.UNSET);
	}

	@Test
	void refusesARootDeckAsATarget() {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "src", null, null);

		assertThatThrownBy(() -> cardBulkService.move(new BulkMoveCommand(List.of("c1"), "root")))
				.isInstanceOf(CardConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.MOVE_TARGET_INVALID);
	}

	@Test
	void refusesADeckThatHoldsSubDecksAsATarget() {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("holder", "Unit 2", "root", "root", DeckContentType.DECK);
		insertCardWithState("c1", "src", null, null);

		assertThatThrownBy(() -> cardBulkService.move(new BulkMoveCommand(List.of("c1"), "holder")))
				.isInstanceOf(CardConflictException.class)
				.extracting("errorCode").isEqualTo(ApiErrorCode.MOVE_TARGET_INVALID);
	}

	@Test
	void refusesABatchContainingACardThatIsGone() {
		insertRootDeck("root", "Korean");
		insertSubDeck("src", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("dst", "Unit 2", "root", "root", DeckContentType.UNSET);
		insertCardWithState("c1", "src", null, null);
		insertCardWithState("trashed", "src", null, null);
		softDelete("card", "trashed");

		assertThatThrownBy(() -> cardBulkService.move(new BulkMoveCommand(List.of("c1", "trashed"), "dst")))
				.isInstanceOf(CardNotFoundException.class);
	}

	/** Set, not toggle: a mixed selection ends up uniformly flagged. */
	@Test
	void setsAndClearsTheFlagExplicitlyRatherThanToggling() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);
		insertFlaggedCard("c2", "deck");

		assertThat(cardBulkService.setFlag(new BulkFlagCommand(List.of("c1", "c2"), true))).isEqualTo(2);
		assertThat(flaggedOf("c1")).isTrue();
		assertThat(flaggedOf("c2")).isTrue();

		cardBulkService.setFlag(new BulkFlagCommand(List.of("c1", "c2"), false));
		assertThat(flaggedOf("c1")).isFalse();
		assertThat(flaggedOf("c2")).isFalse();
	}

	/** Translation row 9: PostgreSQL rejects IN (), so an empty batch never reaches the database. */
	@Test
	void refusesAnEmptyBatchBeforeItReachesTheDatabase() {
		assertThatThrownBy(() -> cardBulkService.setFlag(new BulkFlagCommand(List.of(), true)))
				.isInstanceOf(ValidationFailedException.class);
		assertThatThrownBy(() -> cardBulkService.move(new BulkMoveCommand(List.of(), "dst")))
				.isInstanceOf(ValidationFailedException.class);
	}

	/**
	 * The cap decided in M9.P0: 500 ids, refused rather than truncated.
	 *
	 * <p>A client that silently loses rows is worse off than one that is told no.
	 */
	@Test
	void refusesABatchLargerThanTheDocumentedCap() {
		final var tooMany = IntStream.range(0, OVER_THE_CAP).mapToObj(index -> "c" + index).toList();

		assertThatThrownBy(() -> cardBulkService.setFlag(new BulkFlagCommand(tooMany, true)))
				.isInstanceOf(ValidationFailedException.class)
				.hasMessageContaining("500");
	}

	/** BR-92: editing content never touches the flag or any scheduler column. */
	@Test
	void editsContentWithoutTouchingTheFlagOrTheSchedule() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertFlaggedCard("c1", "deck");
		this.jdbcTemplate.update("""
				INSERT INTO card_study_states (card_id, scheduler_type, scheduler_version,
				                               scheduler_generation, answer_count, current_box)
				VALUES ('c1', 'eight_box', 1, 1, 7, 4)""");

		final var updated = cardEditService.update(new UpdateCardCommand(
				"c1", "  안녕  ", "  Hello  ", "  example  ", null, "  annyeong  "));

		assertThat(updated.front()).isEqualTo("안녕");
		assertThat(updated.hint()).isNull();
		assertThat(flaggedOf("c1")).isTrue();
		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT current_box FROM card_study_states WHERE card_id = 'c1'", Integer.class))
				.isEqualTo(4);
	}

	/**
	 * Fold parity with the Dart side, pinned rather than believed.
	 *
	 * <p>{@code lib/core/text/search_fold.dart} folds with {@code raw.trim().toLowerCase()}. The
	 * service trims before binding and the statement applies {@code LOWER()}, so the two agree — but
	 * only a test over a mixed-script string says so for the scripts this app actually ships.
	 */
	@Test
	void writesTheSameFoldTheDartSideWouldWrite() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState("c1", "deck", null, null);
		final var raw = "  안녕하세요 Hello WORLD  ";

		cardEditService.update(new UpdateCardCommand("c1", raw, "Back", null, null, null));

		assertThat(this.jdbcTemplate.queryForObject(
				"SELECT front_folded FROM cards WHERE id = 'c1'", String.class))
				.isEqualTo(raw.trim().toLowerCase(java.util.Locale.ROOT));
	}

	@Test
	void refusesToEditACardThatIsGone() {
		assertThatThrownBy(() -> cardEditService.update(
				new UpdateCardCommand("nope", "Front", "Back", null, null, null)))
				.isInstanceOf(CardNotFoundException.class);
	}
}
