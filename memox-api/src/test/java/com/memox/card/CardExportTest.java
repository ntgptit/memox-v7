package com.memox.card;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.lang.reflect.RecordComponent;
import java.time.Instant;
import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.card.entity.CardKey;
import com.memox.card.entity.ExportCard;
import com.memox.card.exception.CardConflictException;
import com.memox.card.service.CardExportService;
import com.memox.deck.enums.DeckContentType;
import com.memox.deck.exception.DeckNotFoundException;
import com.memox.support.PostgresIntegrationTest;

class CardExportTest extends PostgresIntegrationTest {

	@Autowired
	private CardExportService cardExportService;

	/** BR-175: exactly AD-20's six content fields. No flag, no schedule, no history. */
	@Test
	void exportsTheSixContentFieldsAndNothingElse() {
		seedDeck();
		insertFlaggedCard("c1", "deck");
		insertTag("t-a", "alpha");
		linkTag("c1", "t-a");

		final var export = cardExportService.exportDeck("deck");

		assertThat(export.deckName()).isEqualTo("Unit 1");
		assertThat(export.cards()).singleElement()
				.extracting(ExportCard::tagNames).isEqualTo(List.of("alpha"));
		assertThat(ExportCard.class.getRecordComponents()).extracting(RecordComponent::getName)
				.doesNotContain("flagged", "dueAt", "currentBox", "schedulerType", "createdAt");
	}

	/** BR-257: a card in Trash is not part of the deck on any active surface. */
	@Test
	void excludesTrashedCardsFromTheExport() {
		seedDeck();
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("trashed", "deck", null, null);
		softDelete("card", "trashed");

		assertThat(cardExportService.exportDeck("deck").cards())
				.extracting(ExportCard::cardId).containsExactly("kept");
	}

	/** {@code string_agg} over an empty set is NULL, and the handler turns that into an empty list. */
	@Test
	void returnsAnEmptyTagListRatherThanNullWhenACardHasNoTags() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);

		assertThat(cardExportService.exportDeck("deck").cards())
				.singleElement().extracting(ExportCard::tagNames).isEqualTo(List.of());
	}

	/**
	 * BR-177: the tags of each card are ordered by the <em>folded</em> name, not the spelling.
	 *
	 * <p>Byte-ordered, {@code Verb} sorts before {@code adjective}; folded, it does not. The same
	 * deck has to produce the same artifact on both platforms, and the Flutter export sorts by the
	 * folded name in Dart because SQLite does not honour an ORDER BY inside an aggregate.
	 */
	@Test
	void ordersTheTagsOfACardByTheFoldedNameRatherThanTheSpelling() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		insertTag("t-v", "Verb");
		insertTag("t-a", "adjective");
		linkTag("c1", "t-v");
		linkTag("c1", "t-a");

		assertThat(cardExportService.exportDeck("deck").cards())
				.singleElement().extracting(ExportCard::tagNames)
				.isEqualTo(List.of("adjective", "Verb"));
	}

	/** BR-177: {@code created_at ASC} with an {@code id ASC} tie-break, for both scopes. */
	@Test
	void ordersCardsByCreationThenIdInBothScopes() {
		seedDeck();
		insertCardWithState("later", "deck", null, null);
		insertCardWithState("b-same", "deck", null, null);
		insertCardWithState("a-same", "deck", null, null);
		backdateCreation("b-same", Instant.parse("2026-01-01T00:00:00Z"));
		backdateCreation("a-same", Instant.parse("2026-01-01T00:00:00Z"));

		assertThat(cardExportService.exportDeck("deck").cards())
				.extracting(ExportCard::cardId).containsExactly("a-same", "b-same", "later");

		assertThat(cardExportService.exportCards("deck", List.of("later", "a-same", "b-same")).cards())
				.extracting(ExportCard::cardId).containsExactly("a-same", "b-same", "later");
	}

	/** BR-174: only the deck's own cards. A descendant deck's cards carry that deck's id. */
	@Test
	void excludesTheCardsOfADescendantDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("child", "Lesson 1", "deck", "root", DeckContentType.CARD);
		insertCardWithState("theirs", "child", null, null);
		insertCardWithState("mine", "deck", null, null);

		assertThat(cardExportService.exportDeck("deck").cards())
				.extracting(ExportCard::cardId).containsExactly("mine");
	}

	/**
	 * BR-174: an id that is gone, or that moved to another deck, fails the <em>whole</em> request.
	 *
	 * <p>Measured by subtracting the ids that came back from the ids that were asked for, never by
	 * comparing counts: duplicates are normalised away first, so a short result and a stale id are
	 * indistinguishable by count alone.
	 */
	@Test
	void refusesTheWholeRequestWhenASelectedCardIsNoLongerInTheDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertSubDeck("other", "Unit 2", "root", "root", DeckContentType.CARD);
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("trashed", "deck", null, null);
		insertCardWithState("moved", "other", null, null);
		softDelete("card", "trashed");

		assertThatThrownBy(() -> cardExportService.exportCards("deck", List.of("kept", "trashed")))
				.isInstanceOf(CardConflictException.class);
		assertThatThrownBy(() -> cardExportService.exportCards("deck", List.of("kept", "moved")))
				.isInstanceOf(CardConflictException.class);
	}

	/** BR-174: a repeated id is one card in the file, not two rows. */
	@Test
	void normalisesARepeatedIdToOneRow() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);

		assertThat(cardExportService.exportCards("deck", List.of("c1", "c1")).cards())
				.extracting(ExportCard::cardId).containsExactly("c1");
	}

	/**
	 * BR-174: an empty scope is refused in the repository even when the UI has hidden the action.
	 *
	 * <p>A deck whose last card was deleted from another screen reaches here with the export button
	 * still on screen, and an empty file is not what was asked for.
	 */
	@Test
	void refusesAnEmptyScope() {
		seedDeck();

		assertThatThrownBy(() -> cardExportService.exportDeck("deck"))
				.isInstanceOf(CardConflictException.class);
		assertThatThrownBy(() -> cardExportService.exportCards("deck", List.of()))
				.isInstanceOf(com.memox.common.error.ValidationFailedException.class);
	}

	/** The deck name read returns no row for a deck that is gone, which is the missing-deck signal. */
	@Test
	void refusesADeckThatIsGone() {
		seedDeck();
		insertCardWithState("c1", "deck", null, null);
		softDelete("deck", "deck");

		assertThatThrownBy(() -> cardExportService.exportDeck("deck"))
				.isInstanceOf(DeckNotFoundException.class);
		assertThatThrownBy(() -> cardExportService.exportCards("deck", List.of("c1")))
				.isInstanceOf(DeckNotFoundException.class);
	}

	/**
	 * BR-170: a card in Trash is not a duplicate an import has to avoid — it is not visible, and
	 * refusing an import over one would be refusing on evidence the user cannot see.
	 */
	@Test
	void probesDuplicateKeysAgainstActiveCardsOnly() {
		seedDeck();
		insertCardWithState("kept", "deck", null, null);
		insertCardWithState("trashed", "deck", null, null);
		softDelete("card", "trashed");

		assertThat(cardExportService.existingKeys("deck"))
				.isEqualTo(Set.of(new CardKey("front kept", "back kept")));
	}

	private void backdateCreation(final String cardId, final Instant createdAt) {
		this.jdbcTemplate.update("UPDATE cards SET created_at = ? WHERE id = ?",
				java.sql.Timestamp.from(createdAt), cardId);
	}

	private void seedDeck() {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
	}
}
