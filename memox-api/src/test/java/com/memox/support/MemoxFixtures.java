package com.memox.support;

import java.sql.Timestamp;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;

import com.memox.deck.enums.DeckContentType;
import com.memox.common.scheduler.SchedulerType;

/**
 * The seeding vocabulary every integration test shares, so no two features invent two different
 * ways to say "make me a deck".
 *
 * <p>{@link PostgresIntegrationTest} extends this class rather than holding it as a field. The
 * Phase 2 plan specified composition with a {@code protected final MemoxFixtures fixtures}, but
 * every one of the ~186 call sites it writes reads {@code insertRootDeck(...)} with no receiver —
 * which composition can only deliver through 25 one-line delegating methods that would put the
 * fixture surface in two places. Inheritance gives the same call sites one home.
 *
 * <p><strong>Fixtures write through {@link JdbcTemplate}, never through the services under test.</strong>
 * A fixture that calls the production write path cannot fail independently of it, and several
 * planned tests need to place rows a service would refuse to place — an orphaned tombstone, a deck
 * whose content type disagrees with its children, a batch backdated past the purge horizon.
 * That means fixtures do exactly what they say and maintain no invariants: seeding a card into an
 * {@code unset} deck leaves the deck {@code unset}, because that is sometimes the state under test.
 *
 * <p>Timestamps are truncated to microseconds. PostgreSQL's {@code TIMESTAMPTZ} holds microseconds
 * and {@link Instant} holds nanoseconds, so an untruncated value does not survive the round trip
 * and a test asserting equality against what it passed in fails for a reason that has nothing to do
 * with what it is testing.
 */
public abstract class MemoxFixtures {

	/** Every root deck shares one sibling scope, because a root has no parent to scope it by. */
	private static final String ROOT_SIBLING_SCOPE = "00000000-0000-0000-0000-000000000000";

	private static final int INITIAL_SCHEDULER_VERSION = 1;
	private static final int INITIAL_SCHEDULER_GENERATION = 1;

	@Autowired
	protected JdbcTemplate jdbcTemplate;

	@Autowired
	private Clock clock;

	public void insertRootDeck(String id, String name) {
		insertRootDeck(id, name, SchedulerType.EIGHT_BOX);
	}

	public void insertRootDeck(String id, String name, SchedulerType schedulerType) {
		insertRootDeck(id, name, schedulerType, INITIAL_SCHEDULER_GENERATION);
	}

	public void insertRootDeck(String id, String name, SchedulerType schedulerType, int generation) {
		final var now = stamp();
		this.jdbcTemplate.update("""
				INSERT INTO decks (id, name, parent_deck_id, sibling_scope_id, sibling_position, root_deck_id,
				                   content_type, scheduler_type, scheduler_version, scheduler_generation,
				                   created_at, updated_at)
				VALUES (?, ?, NULL, ?, ?, ?, 'deck', ?, ?, ?, ?, ?)""",
				id, name, ROOT_SIBLING_SCOPE, nextSiblingPosition(ROOT_SIBLING_SCOPE), id,
				schedulerType.getValue(), INITIAL_SCHEDULER_VERSION, generation, now, now);
	}

	public void insertSubDeck(String id, String name, String parentId, String rootId) {
		insertSubDeck(id, name, parentId, rootId, DeckContentType.UNSET);
	}

	public void insertSubDeck(String id, String name, String parentId, String rootId, DeckContentType contentType) {
		insertSubDeckRow(id, name, parentId, rootId, contentType, nextSiblingPosition(parentId));
	}

	/**
	 * Seeds a sub-deck at an exact sibling position.
	 *
	 * <p>Reordering tests need to place rows at chosen positions; everything else should use
	 * {@link #insertSubDeck} and let the next free position be picked, because
	 * {@code uq_decks_sibling_scope_position} rejects a duplicate within one parent.
	 */
	public void insertSubDeckAt(String id, String name, String parentId, String rootId, int siblingPosition) {
		insertSubDeckRow(id, name, parentId, rootId, DeckContentType.UNSET, siblingPosition);
	}

	/**
	 * Seeds a straight-line deck chain {@code d1..dN}, where {@code d1} is the root.
	 *
	 * <p>Every deck but the last holds sub-decks, so the chain is a legal tree rather than a
	 * shape the depth and content-type rules would reject. Used by the depth-limit tests.
	 */
	public void insertChain(int levels) {
		insertRootDeck("d1", "Level 1");
		for (int level = 2; level <= levels; level++) {
			final var contentType = level == levels ? DeckContentType.UNSET : DeckContentType.DECK;
			insertSubDeck("d" + level, "Level " + level, "d" + (level - 1), "d1", contentType);
		}
	}

	/**
	 * Seeds a card together with its study state, inheriting the scheduler from the deck's root.
	 *
	 * <p>Both timestamps are nullable on purpose: {@code learned_at == null} is what makes a card
	 * new rather than merely undue (BR-90, BR-151), and a fixture that quietly substituted "now"
	 * would make every new-card test seed a learned card instead.
	 */
	public void insertCardWithState(String id, String deckId, Instant learnedAt, Instant dueAt) {
		insertCardRow(id, deckId, false);
		final var scheduler = schedulerOfRootFor(deckId);
		this.jdbcTemplate.update("""
				INSERT INTO card_study_states (card_id, scheduler_type, scheduler_version, scheduler_generation,
				                               learned_at, due_at)
				VALUES (?, ?, ?, ?, ?, ?)""",
				id, scheduler.type().getValue(), scheduler.version(), scheduler.generation(),
				stamp(learnedAt), stamp(dueAt));
	}

	public void insertFlaggedCard(String id, String deckId) {
		insertCardRow(id, deckId, true);
	}

	public void insertTag(String id, String name) {
		this.jdbcTemplate.update(
				"INSERT INTO tags (id, name, name_folded, created_at) VALUES (?, ?, ?, ?)",
				id, name, fold(name), stamp());
	}

	public void linkTag(String cardId, String tagId) {
		this.jdbcTemplate.update("INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)", cardId, tagId);
	}

	/**
	 * Soft-deletes exactly one row by opening a batch and stamping that row with it.
	 *
	 * <p>One row, not a subtree: maintaining the subtree is the behaviour the trash service owns
	 * and therefore the behaviour under test. A fixture that did it too would hide the difference
	 * between a service that cascades and one that does not.
	 *
	 * @param itemType {@code deck} or {@code card}, matching the batch's CHECK constraint
	 */
	public void softDelete(String itemType, String itemId) {
		// Resolved before the insert on purpose: delete_batches has its own CHECK on item_type, so a
		// typo would otherwise surface as a constraint violation naming a column rather than as a
		// message naming the mistake — and this guard would never run.
		final var table = tableOf(itemType);
		final var batchId = UUID.randomUUID().toString();
		this.jdbcTemplate.update(
				"INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES (?, ?, ?, ?)",
				batchId, itemType, itemId, stamp());
		this.jdbcTemplate.update(
				"UPDATE %s SET delete_batch_id = ? WHERE id = ?".formatted(table), batchId, itemId);
	}

	/** Ages a batch so purge-horizon tests do not have to wait for one. */
	public void backdateBatch(String batchId, Duration age) {
		this.jdbcTemplate.update("UPDATE delete_batches SET deleted_at = ? WHERE id = ?",
				stamp(Instant.now(this.clock).minus(age)), batchId);
	}

	/**
	 * Clears a deck's batch pointer without touching the batch.
	 *
	 * <p>Produces a batch whose root item is no longer deleted — a state the services refuse to
	 * create and the restore and purge paths must still survive.
	 */
	public void reviveDeckWithoutBatch(String deckId) {
		this.jdbcTemplate.update("UPDATE decks SET delete_batch_id = NULL WHERE id = ?", deckId);
	}

	/**
	 * Seeds an in-progress study session on one deck.
	 *
	 * <p>Only the columns the CHECK constraints demand. Everything else about a session belongs to
	 * Phase 3; what BR-259 needs is a row that is {@code in_progress} and points somewhere.
	 */
	public void insertOpenSession(String id, String deckId, String rootDeckId) {
		this.jdbcTemplate.update("""
				INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, status,
				                            session_kind, current_mode, card_limit, started_at)
				VALUES (?, ?, ?, 1, 'in_progress', 'reviewing', 'self_assess', 20, ?)""",
				id, deckId, rootDeckId, stamp());
	}

	/** A session that has already ended. BR-86 says its end state is never rewritten. */
	public void insertEndedSession(String id, String deckId, String rootDeckId) {
		this.jdbcTemplate.update("""
				INSERT INTO study_sessions (id, deck_id, root_deck_id, scheduler_generation, status,
				                            session_kind, current_mode, card_limit, started_at,
				                            ended_at, end_reason)
				VALUES (?, ?, ?, 1, 'completed', 'reviewing', 'self_assess', 20, ?, ?, 'user_exit')""",
				id, deckId, rootDeckId, stamp(), stamp());
	}

	/** Puts one card in a session's queue — the only way the card-side lookup can find the session. */
	public void queueCard(String sessionId, String cardId) {
		this.jdbcTemplate.update("""
				INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status)
				VALUES (?, 'self_assess', 1, ?, 0, 'pending')""",
				sessionId, cardId);
	}

	/**
	 * The batch's {@code deleted_at} as the column holds it.
	 *
	 * <p>Read back rather than compared against the in-memory {@code Instant}: {@code TIMESTAMPTZ}
	 * keeps microseconds and the driver <em>rounds</em> to them, while {@code truncatedTo(MICROS)}
	 * floors — so the two disagree by one microsecond whenever the clock lands past the half. A test
	 * written that way passes or fails on the nanoseconds, which is not what it means to assert.
	 */
	public Instant batchDeletedAtOf(String batchId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT deleted_at FROM delete_batches WHERE id = ?", Instant.class, batchId);
	}

	public String sessionStatusOf(String sessionId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT status FROM study_sessions WHERE id = ?", String.class, sessionId);
	}

	public String sessionEndReasonOf(String sessionId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT end_reason FROM study_sessions WHERE id = ?", String.class, sessionId);
	}

	public Instant sessionEndedAtOf(String sessionId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT ended_at FROM study_sessions WHERE id = ?", Instant.class, sessionId);
	}

	public String deckIdOf(String cardId) {
		return this.jdbcTemplate.queryForObject("SELECT deck_id FROM cards WHERE id = ?", String.class, cardId);
	}

	public String rootDeckIdOf(String deckId) {
		return this.jdbcTemplate.queryForObject("SELECT root_deck_id FROM decks WHERE id = ?", String.class, deckId);
	}

	public String batchIdOfDeck(String deckId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT delete_batch_id FROM decks WHERE id = ?", String.class, deckId);
	}

	public String batchIdOfCard(String cardId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT delete_batch_id FROM cards WHERE id = ?", String.class, cardId);
	}

	public DeckContentType contentTypeOf(String deckId) {
		return DeckContentType.fromValue(this.jdbcTemplate.queryForObject(
				"SELECT content_type FROM decks WHERE id = ?", String.class, deckId));
	}

	public int siblingPositionOf(String deckId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT sibling_position FROM decks WHERE id = ?", Integer.class, deckId);
	}

	public boolean flaggedOf(String cardId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT is_flagged FROM cards WHERE id = ?", Integer.class, cardId) == 1;
	}

	public boolean cardExists(String id) {
		return exists("cards", id);
	}

	public boolean deckExists(String id) {
		return exists("decks", id);
	}

	public boolean tagExists(String id) {
		return exists("tags", id);
	}

	public List<String> tagIdsOf(String cardId) {
		return this.jdbcTemplate.queryForList(
				"SELECT tag_id FROM card_tags WHERE card_id = ? ORDER BY tag_id", String.class, cardId);
	}

	/** The fold the app searches by: {@code raw.trim().toLowerCase()}, matching Dart's foldForSearch. */
	protected String fold(String raw) {
		return raw.trim().toLowerCase(Locale.ROOT);
	}

	private void insertSubDeckRow(
			String id, String name, String parentId, String rootId, DeckContentType contentType, int siblingPosition) {
		final var now = stamp();
		this.jdbcTemplate.update("""
				INSERT INTO decks (id, name, parent_deck_id, sibling_scope_id, sibling_position, root_deck_id,
				                   content_type, created_at, updated_at)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
				id, name, parentId, parentId, siblingPosition, rootId, contentType.getValue(), now, now);
	}

	private void insertCardRow(String id, String deckId, boolean flagged) {
		final var now = stamp();
		final var front = "front " + id;
		final var back = "back " + id;
		this.jdbcTemplate.update("""
				INSERT INTO cards (id, deck_id, front, back, front_folded, back_folded, is_flagged,
				                   created_at, updated_at)
				VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
				id, deckId, front, back, fold(front), fold(back), flagged ? 1 : 0, now, now);
	}

	private SchedulerTriple schedulerOfRootFor(String deckId) {
		final var rows = this.jdbcTemplate.queryForList("""
				SELECT scheduler_type, scheduler_version, scheduler_generation
				FROM decks
				WHERE id = (SELECT root_deck_id FROM decks WHERE id = ?)""", deckId);
		if (rows.isEmpty() || rows.get(0).get("scheduler_type") == null) {
			return new SchedulerTriple(
					SchedulerType.EIGHT_BOX, INITIAL_SCHEDULER_VERSION, INITIAL_SCHEDULER_GENERATION);
		}
		final var row = rows.get(0);
		return new SchedulerTriple(
				SchedulerType.fromValue((String) row.get("scheduler_type")),
				(Integer) row.get("scheduler_version"),
				(Integer) row.get("scheduler_generation"));
	}

	private int nextSiblingPosition(String siblingScopeId) {
		return this.jdbcTemplate.queryForObject(
				"SELECT COALESCE(MAX(sibling_position), -1) + 1 FROM decks WHERE sibling_scope_id = ?",
				Integer.class, siblingScopeId);
	}

	private boolean exists(String table, String id) {
		return Boolean.TRUE.equals(this.jdbcTemplate.queryForObject(
				"SELECT EXISTS (SELECT 1 FROM %s WHERE id = ?)".formatted(table), Boolean.class, id));
	}

	/**
	 * The table a delete batch's item type points at.
	 *
	 * <p>Interpolated into SQL, which is safe only because the value never comes from outside this
	 * class's two accepted constants — and unrecognised input throws rather than reaching a query.
	 */
	private String tableOf(String itemType) {
		if ("deck".equals(itemType)) {
			return "decks";
		}
		if ("card".equals(itemType)) {
			return "cards";
		}
		throw new IllegalArgumentException("item type must be deck or card, was: " + itemType);
	}

	private Timestamp stamp() {
		return stamp(Instant.now(this.clock));
	}

	private Timestamp stamp(Instant instant) {
		if (instant == null) {
			return null;
		}
		return Timestamp.from(instant.truncatedTo(ChronoUnit.MICROS));
	}

	private record SchedulerTriple(SchedulerType type, int version, int generation) {
	}
}
