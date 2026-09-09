package com.memox.deck.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import java.sql.Timestamp;
import java.time.Instant;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.common.pagination.PageSlice;
import com.memox.common.pagination.SortColumn;
import com.memox.common.pagination.SortDirection;
import com.memox.deck.entity.Deck;
import com.memox.deck.enums.DeckContentType;
import com.memox.common.scheduler.SchedulerType;
import com.memox.support.PostgresIntegrationTest;

class DeckMapperTest extends PostgresIntegrationTest {

	private static final String ROOT_ID = "11111111-1111-4111-8111-111111111111";
	private static final String SECOND_ID = "33333333-3333-4333-8333-333333333333";
	private static final String THIRD_ID = "44444444-4444-4444-8444-444444444444";
	private static final String DELETE_BATCH_ID = "22222222-2222-4222-8222-222222222222";

	private static final SortColumn BY_POSITION = new SortColumn("sibling_position", SortDirection.ASC);
	private static final SortColumn BY_ID = new SortColumn("id", SortDirection.ASC);

	@Autowired
	private DeckMapper deckMapper;

	@Test
	void returnsAnEmptyRootPageAndZeroTotal() {
		assertThat(deckMapper.findRootDecks(new PageSlice(50, 0, List.of(BY_POSITION, BY_ID)))).isEmpty();
		assertThat(deckMapper.countRootDecks()).isZero();
	}

	/**
	 * Reads a row back through the result map, field by field.
	 *
	 * <p>This is the test the module did not have when it needed it. The result maps declared
	 * {@code javaType="int"} and {@code javaType="boolean"}, which are MyBatis's aliases for the
	 * WRAPPER types, while the records declare the primitives their NOT NULL columns justify — so
	 * no constructor matched and every deck and card creation returned HTTP 500. Nothing caught it
	 * at this level; it surfaced as a controller failure, three layers from the cause.
	 *
	 * <p>Asserting each field rather than just "not null" is the point: a result map can bind and
	 * still put the wrong column in the wrong argument, and every one here is a String or a number
	 * that would happily slot into a neighbour's place.
	 */
	@Test
	void bindsEveryColumnOfTheResultMapToItsOwnField() {
		insertRootDeck(ROOT_ID, "Korean", 7);

		final var deck = deckMapper.findActiveDeckById(ROOT_ID);

		assertThat(deck).isNotNull();
		assertThat(deck.id()).isEqualTo(ROOT_ID);
		assertThat(deck.name()).isEqualTo("Korean");
		assertThat(deck.parentDeckId()).isNull();
		assertThat(deck.rootDeckId()).isEqualTo(ROOT_ID);
		assertThat(deck.contentType()).isEqualTo(DeckContentType.DECK);
		assertThat(deck.schedulerType()).isEqualTo(SchedulerType.EIGHT_BOX);
		assertThat(deck.schedulerVersion()).isEqualTo(1);
		assertThat(deck.schedulerGeneration()).isEqualTo(3);
		assertThat(deck.siblingPosition()).isEqualTo(7);
		assertThat(deck.createdAt()).isEqualTo(Instant.EPOCH);
	}

	@Test
	void doesNotReturnASoftDeletedDeck() {
		insertRootDeck(ROOT_ID, "Korean", 7);
		this.jdbcTemplate.update(
				"INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES (?, 'deck', ?, ?)",
				DELETE_BATCH_ID, ROOT_ID, Timestamp.from(Instant.EPOCH));
		this.jdbcTemplate.update("UPDATE decks SET delete_batch_id = ? WHERE id = ?", DELETE_BATCH_ID, ROOT_ID);

		assertThat(deckMapper.findActiveDeckById(ROOT_ID)).isNull();
		assertThat(deckMapper.countRootDecks()).isZero();
	}

	/**
	 * The ORDER BY the mapper renders from the slice, executed against a real database.
	 *
	 * <p>Both halves of that clause are substituted rather than bound — a column name is not a JDBC
	 * value and cannot be — so nothing short of running the statement proves it produces valid SQL.
	 * A unit test over {@code PageHelper.slice} shows the right columns were chosen; only this
	 * shows PostgreSQL accepted them and ordered by them.
	 */
	@Test
	void ordersRowsByTheColumnAndDirectionTheSliceCarries() {
		insertRootDeck(ROOT_ID, "Korean", 7);
		insertRootDeck(SECOND_ID, "Japanese", 3);
		insertRootDeck(THIRD_ID, "Vietnamese", 5);

		final var ascending = deckMapper.findRootDecks(new PageSlice(50, 0, List.of(BY_POSITION, BY_ID)));
		final var descending = deckMapper.findRootDecks(new PageSlice(50, 0,
				List.of(new SortColumn("sibling_position", SortDirection.DESC), BY_ID)));

		assertThat(ascending).extracting(Deck::id).containsExactly(SECOND_ID, THIRD_ID, ROOT_ID);
		assertThat(descending).extracting(Deck::id).containsExactly(ROOT_ID, THIRD_ID, SECOND_ID);
	}

	/**
	 * The tie-breaker doing the job it exists for.
	 *
	 * <p>All three decks were created at the same instant, so ordering by {@code created_at} alone
	 * leaves PostgreSQL free to break the tie differently on each execution — and two LIMIT/OFFSET
	 * queries over that ordering can return the same deck twice and never return another. The
	 * {@code id} key appended by {@code PageHelper.slice} is what makes these two pages disjoint.
	 */
	@Test
	void breaksTiesByIdSoConsecutivePagesDoNotOverlap() {
		insertRootDeck(ROOT_ID, "Korean", 1);
		insertRootDeck(SECOND_ID, "Japanese", 2);
		insertRootDeck(THIRD_ID, "Vietnamese", 3);
		final var tiedSorts = List.of(new SortColumn("created_at", SortDirection.ASC), BY_ID);

		final var firstPage = deckMapper.findRootDecks(new PageSlice(2, 0, tiedSorts));
		final var secondPage = deckMapper.findRootDecks(new PageSlice(2, 2, tiedSorts));

		assertThat(firstPage).extracting(Deck::id).containsExactly(ROOT_ID, SECOND_ID);
		assertThat(secondPage).extracting(Deck::id).containsExactly(THIRD_ID);
	}

	private void insertRootDeck(String deckId, String name, int siblingPosition) {
		// Deliberately distinct values: 1, 3 and the caller's position cannot be swapped between
		// scheduler_version, scheduler_generation and sibling_position without a test noticing.
		this.jdbcTemplate.update("""
				INSERT INTO decks (id, name, parent_deck_id, sibling_scope_id, sibling_position,
				                   root_deck_id, content_type, scheduler_type, scheduler_version,
				                   scheduler_generation, created_at, updated_at)
				VALUES (?, ?, NULL, '00000000-0000-0000-0000-000000000000', ?,
				        ?, 'deck', 'eight_box', 1, 3, ?, ?)""",
				deckId, name, siblingPosition, deckId, Timestamp.from(Instant.EPOCH),
				Timestamp.from(Instant.EPOCH));
	}
}
