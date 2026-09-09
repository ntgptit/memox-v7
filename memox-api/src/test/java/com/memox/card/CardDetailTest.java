package com.memox.card;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.sql.Timestamp;
import java.time.Instant;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.card.entity.CardHistoryCursor;
import com.memox.card.entity.CardHistoryEntry;
import com.memox.card.entity.CardListItem;
import com.memox.card.exception.CardNotFoundException;
import com.memox.card.service.CardQueryService;
import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;

class CardDetailTest extends PostgresIntegrationTest {

	private static final Instant T1 = Instant.parse("2026-09-01T10:00:00Z");
	private static final Instant T2 = Instant.parse("2026-09-02T10:00:00Z");
	private static final Instant T3 = Instant.parse("2026-09-03T10:00:00Z");
	private static final int PAGE_OF_TWO = 2;
	private static final int PLENTY = 10;

	@Autowired
	private CardQueryService cardQueryService;

	/**
	 * Detail is the list row narrowed to one id, and deliberately the same shape.
	 *
	 * <p>Drift says so in as many words, and gives the reason: detail and the row it was opened from
	 * cannot disagree about a card's state or its chips. The plan asked for a separate
	 * {@code CardDetail} record; two records for one projection is exactly how they would come to
	 * disagree.
	 */
	@Test
	void readsTheSameShapeTheListRowHas() {
		seedCard("card-1");
		insertTag("t-a", "alpha");
		linkTag("card-1", "t-a");

		final var detail = cardQueryService.detail("card-1");

		assertThat(detail).isInstanceOf(CardListItem.class);
		assertThat(detail.id()).isEqualTo("card-1");
		assertThat(detail.deckId()).isEqualTo("deck");
		assertThat(detail.tagNames()).containsExactly("alpha");
		assertThat(detail.schedulerType()).isNotNull();
	}

	/** BR-245, BR-257: a card in Trash reads as not-found on every active surface. */
	@Test
	void refusesToShowATrashedCard() {
		seedCard("card-1");
		softDelete("card", "card-1");

		assertThatThrownBy(() -> cardQueryService.detail("card-1"))
				.isInstanceOf(CardNotFoundException.class);
	}

	@Test
	void refusesToShowACardThatNeverExisted() {
		assertThatThrownBy(() -> cardQueryService.detail("nope"))
				.isInstanceOf(CardNotFoundException.class);
	}

	/**
	 * Keyset, not offset: the cursor is the last row of the previous page and the next page starts
	 * strictly after it. Offset pagination shifts under a history that is being appended to.
	 */
	@Test
	void pagesHistoryByKeysetAndNotByOffset() {
		seedCard("card-1");
		insertAnswer("a1", "card-1", T1);
		insertAnswer("a2", "card-1", T2);
		insertAnswer("a3", "card-1", T3);

		final var first = cardQueryService.history("card-1", null, PAGE_OF_TWO);

		assertThat(first.entries()).extracting(CardHistoryEntry::id).containsExactly("a3", "a2");
		assertThat(first.hasMore()).isTrue();

		final var last = first.entries().get(1);
		final var next = cardQueryService.history("card-1",
				new CardHistoryCursor(last.answeredAt(), last.id()), PAGE_OF_TWO);

		assertThat(next.entries()).extracting(CardHistoryEntry::id).containsExactly("a1");
		assertThat(next.hasMore()).isFalse();
	}

	/**
	 * "Is there another page" is answered by the read, not guessed from a short result.
	 *
	 * <p>Drift's own note says the caller asks for one row more than the page size and reports what
	 * it found. The plan returned a bare list, which leaves the caller inferring — and a page that
	 * happens to be exactly full is indistinguishable from the last one.
	 */
	@Test
	void reportsThereIsNoNextPageWhenTheLastPageIsExactlyFull() {
		seedCard("card-1");
		insertAnswer("a1", "card-1", T1);
		insertAnswer("a2", "card-1", T2);

		final var page = cardQueryService.history("card-1", null, PAGE_OF_TWO);

		assertThat(page.entries()).hasSize(2);
		assertThat(page.hasMore()).isFalse();
	}

	/** Two turns of one session can share a millisecond, so the id tie-break is load-bearing. */
	@Test
	void breaksATieOnAnsweredAtByDescendingId() {
		seedCard("card-1");
		insertAnswer("a-lower", "card-1", T1);
		insertAnswer("b-higher", "card-1", T1);

		assertThat(cardQueryService.history("card-1", null, PLENTY).entries())
				.extracting(CardHistoryEntry::id).containsExactly("b-higher", "a-lower");
	}

	/**
	 * Every stored column reaches the read model.
	 *
	 * <p>BR-242's point is that the screen shows what the row stored, so a column dropped from the
	 * projection is a fact that silently stops being displayed. The plan's projection dropped
	 * {@code comparison_version}; this asserts the whole row survives.
	 */
	@Test
	void carriesEveryStoredColumnIncludingComparisonVersion() {
		seedCard("card-1");
		insertAnswer("a1", "card-1", T1);
		this.jdbcTemplate.update("""
				UPDATE study_answers
				SET comparison_version = 3, used_hint = 1, outcome_reason = 'timeout',
				    next_due_at = ?, previous_box = 2, next_box = 3,
				    previous_ease_factor = 2.5, next_ease_factor = 2.6,
				    previous_interval_days = 4, next_interval_days = 9,
				    direction = 'korean_to_meaning'
				WHERE id = 'a1'""", Timestamp.from(T3));

		final var entry = cardQueryService.history("card-1", null, PLENTY).entries().get(0);

		assertThat(entry.comparisonVersion()).isEqualTo(3);
		assertThat(entry.usedHint()).isTrue();
		assertThat(entry.outcomeReason()).isEqualTo("timeout");
		assertThat(entry.nextDueAt()).isEqualTo(T3);
		assertThat(entry.previousBox()).isEqualTo(2);
		assertThat(entry.nextBox()).isEqualTo(3);
		assertThat(entry.previousEaseFactor()).isEqualTo(2.5);
		assertThat(entry.nextEaseFactor()).isEqualTo(2.6);
		assertThat(entry.previousIntervalDays()).isEqualTo(4);
		assertThat(entry.nextIntervalDays()).isEqualTo(9);
		assertThat(entry.direction()).isEqualTo("korean_to_meaning");
		assertThat(entry.action()).isEqualTo("remembered");
	}

	/** {@code used_hint} is nullable, so "we do not know" must not read as "no hint was used". */
	@Test
	void keepsAnUnknownHintNullRatherThanFalse() {
		seedCard("card-1");
		insertAnswer("a1", "card-1", T1);

		assertThat(cardQueryService.history("card-1", null, PLENTY).entries().get(0).usedHint())
				.isNull();
	}

	private void seedCard(final String cardId) {
		insertRootDeck("root", "Korean");
		insertSubDeck("deck", "Unit 1", "root", "root", DeckContentType.CARD);
		insertCardWithState(cardId, "deck", null, null);
	}

	private void insertAnswer(final String answerId, final String cardId, final Instant answeredAt) {
		this.jdbcTemplate.update("""
				INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, status,
				                            session_kind, current_mode, card_limit, started_at)
				VALUES ('session', 'deck', 'root', 1, 'in_progress', 'reviewing', 'self_assess', 20, ?)
				ON CONFLICT (id) DO NOTHING""", Timestamp.from(T1));
		this.jdbcTemplate.update("""
				INSERT INTO study_answers (id, card_id, session_id, scheduler_type,
				                           scheduler_generation, kind, mode, "action", answered_at)
				VALUES (?, ?, 'session', 'eight_box', 1, 'scheduled', 'self_assess', 'remembered', ?)""",
				answerId, cardId, Timestamp.from(answeredAt));
	}
}
