package com.memox.trash;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import com.memox.deck.enums.DeckContentType;
import com.memox.support.PostgresIntegrationTest;
import com.memox.trash.service.DeleteCardsCommand;
import com.memox.trash.service.DeleteDeckCommand;
import com.memox.trash.service.TrashDeleteService;

/**
 * BR-259: a soft-delete closes the sessions it takes the material out from under.
 *
 * <p>All of it in the deletion's own transaction, with the reason stored rather than inferred
 * later. The queue's own {@code delete_batch_id IS NULL} guard at serve time is a backstop for this
 * write failing, not a substitute for it — a session left {@code in_progress} over deleted material
 * is a session whose reason nobody can reconstruct.
 */
class TrashSessionInvalidationTest extends PostgresIntegrationTest {

	@Autowired
	private TrashDeleteService trashDeleteService;

	/** The obvious half: the session was opened on a deck that is going away. */
	@Test
	void closesASessionOpenedOnADeletedDeck() {
		seedTree();
		insertOpenSession("s1", "leaf", "root");

		final var batch = trashDeleteService.deleteDeck(new DeleteDeckCommand("leaf"));

		assertThat(sessionStatusOf("s1")).isEqualTo("invalidated");
		assertThat(sessionEndReasonOf("s1")).isEqualTo("content_deleted");
		// Both values as the columns hold them. Comparing against the in-memory Instant would be
		// flaky by one microsecond: TIMESTAMPTZ keeps microseconds and the driver rounds to them,
		// while truncatedTo floors — so they disagree whenever the clock lands past the half.
		assertThat(sessionEndedAtOf("s1")).isEqualTo(batchDeletedAtOf(batch.id()));
	}

	/**
	 * The half a deck-side lookup alone cannot see, and the reason there are two statements.
	 *
	 * <p>The session is a review of the whole <em>root</em>, so its {@code deck_id} is the root and
	 * the root is not in the batch. Only its queue connects it to the sub-deck being deleted. Drop
	 * the card-side lookup and this session keeps running over material the user can no longer see.
	 */
	@Test
	void closesASessionWhoseQueueHoldsACardFromADeletedSubDeck() {
		seedTree();
		insertCardWithState("c1", "leaf", null, null);
		insertOpenSession("s1", "root", "root");
		queueCard("s1", "c1");

		trashDeleteService.deleteDeck(new DeleteDeckCommand("mid"));

		assertThat(sessionStatusOf("s1")).isEqualTo("invalidated");
		assertThat(sessionEndReasonOf("s1")).isEqualTo("content_deleted");
	}

	/** The same, through the bulk-card path — one lookup for the whole selection. */
	@Test
	void closesASessionWhoseQueueHoldsABulkDeletedCard() {
		seedTree();
		insertCardWithState("c1", "leaf", null, null);
		insertCardWithState("c2", "leaf", null, null);
		insertOpenSession("s1", "root", "root");
		queueCard("s1", "c2");

		final var batches = trashDeleteService.deleteCards(
				new DeleteCardsCommand(List.of("c1", "c2")));

		assertThat(sessionStatusOf("s1")).isEqualTo("invalidated");
		assertThat(sessionEndedAtOf("s1")).isEqualTo(batchDeletedAtOf(batches.get(0).id()));
	}

	/**
	 * BR-86: a session that already ended stays as it ended.
	 *
	 * <p>Both lookups filter {@code status = 'in_progress'} for this reason. Rewriting a completed
	 * session's end state would replace a fact with a different one, and the first would be gone.
	 */
	@Test
	void leavesASessionThatAlreadyEndedExactlyAsItEnded() {
		seedTree();
		insertEndedSession("done", "leaf", "root");

		trashDeleteService.deleteDeck(new DeleteDeckCommand("leaf"));

		assertThat(sessionStatusOf("done")).isEqualTo("completed");
		assertThat(sessionEndReasonOf("done")).isEqualTo("user_exit");
	}

	/** A session over material this deletion did not touch keeps running. */
	@Test
	void leavesASessionOnAnUntouchedDeckAlone() {
		seedTree();
		insertSubDeck("other", "Unit 2", "root", "root", DeckContentType.CARD);
		insertOpenSession("s1", "other", "root");

		trashDeleteService.deleteDeck(new DeleteDeckCommand("mid"));

		assertThat(sessionStatusOf("s1")).isEqualTo("in_progress");
		assertThat(sessionEndReasonOf("s1")).isNull();
	}

	/**
	 * A deck deletion closes a session opened on a descendant, not only on the named deck.
	 *
	 * <p>The subtree read has already decided which decks are going; the lookup takes that set.
	 */
	@Test
	void closesASessionOpenedOnADescendantOfTheDeletedDeck() {
		seedTree();
		insertOpenSession("s1", "leaf", "root");

		trashDeleteService.deleteDeck(new DeleteDeckCommand("mid"));

		assertThat(sessionStatusOf("s1")).isEqualTo("invalidated");
	}

	private void seedTree() {
		insertRootDeck("root", "Korean");
		insertSubDeck("mid", "Unit 1", "root", "root", DeckContentType.DECK);
		insertSubDeck("leaf", "Lesson 1", "mid", "root", DeckContentType.CARD);
	}
}
