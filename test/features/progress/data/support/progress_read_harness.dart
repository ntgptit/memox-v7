import 'package:drift/drift.dart' show TableInfo, UpdateKind, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';

import '../../../../database/support/test_database.dart';

/// The instant every Progress read in these tests is measured against.
///
/// **09:00 UTC, read at +07:00**, so the local clock is 16:00 on 2026-08-13 and
/// every boundary below sits far from a UTC midnight. A fixture anchored at a
/// UTC midnight would pass whether the offset was applied or not, which is the
/// one thing these tests exist to check.
final DateTime progressNow = DateTime.utc(2026, 8, 13, 9);

/// Vietnam's offset — positive, and not a whole day away from UTC.
const Duration progressOffset = Duration(hours: 7);

/// The instant a local day starts, as UTC, for the local calendar day
/// [daysFromToday] away from 2026-08-13.
///
/// Spelled out rather than derived from `LocalDayModel`, deliberately: the
/// production code computes its window from that class, so a test that asked the
/// same class would be asserting it agrees with itself. These are the instants a
/// person with a calendar would write down.
DateTime localMidnight(int daysFromToday) =>
    DateTime.utc(2026, 8, 13 + daysFromToday).subtract(progressOffset);

/// One second before the local day [daysFromToday] ends — 23:59:59 local.
DateTime lastSecondOfLocalDay(int daysFromToday) =>
    localMidnight(daysFromToday + 1).subtract(const Duration(seconds: 1));

/// A real SQLite database with the Progress repository on top of it.
///
/// Real SQLite, not a mock, for the reason `test_database.dart` states: the
/// cascade that removes a deleted deck's answers, the recursive subtree walk and
/// the exactness of the day-bucket division are all behaviour of SQLite itself.
final class ProgressReadHarness {
  late AppDatabase db;
  late ProgressRepositoryImpl repository;

  /// Every statement the database ran, newest last — the production interceptor,
  /// kept for what it can prove. "This read does not scale with the number of
  /// decks" is a claim about how many statements ran, and no assertion on the
  /// result can see it: an N+1 read returns exactly the same records.
  final List<String> statements = <String>[];

  int countStatements(String fragment) =>
      statements.where((String line) => line.contains(fragment)).length;

  void clearStatements() => statements.clear();

  /// Statements that change data. A read path must produce none of them.
  Iterable<String> get writeStatements => statements.where(
    (String line) =>
        line.contains('INSERT ') ||
        line.contains('UPDATE ') ||
        line.contains('DELETE '),
  );

  /// Opens the read the screen opens.
  Stream<DeckActivitySnapshot> watch({String? deckId}) =>
      repository.watchDeckActivity(
        deckId: deckId,
        now: progressNow,
        utcOffset: progressOffset,
      );

  Future<int> countRows(String table) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM $table')
        .getSingle();

    return row.read<int>('c');
  }

  /// A root deck. Named so the sort's folded-name tie-break can be exercised.
  Future<String> root(String id, {String? name}) async {
    await insertRootDeck(db, id: id);
    if (name != null) await rename(id, name);

    return id;
  }

  /// A sub-deck of [parentId], inside [rootId]'s tree.
  Future<String> subDeck(
    String id, {
    required String parentId,
    required String rootId,
    String contentType = 'deck',
    String? name,
  }) async {
    await insertSubDeck(
      db,
      id: id,
      parentId: parentId,
      rootDeckId: rootId,
      contentType: contentType,
    );
    if (name != null) await rename(id, name);

    return id;
  }

  /// **Every mutation below declares the tables it touches.** Drift's stream
  /// cache is what decides whether an open `watch()` re-runs its query, and a
  /// `customUpdate` with no `updates` set tells it nothing — so the stream
  /// replays its previous snapshot and a test asserting "the figures moved"
  /// silently asserts that they did not. The production writes go through
  /// generated statements, which declare this for themselves; only these
  /// hand-written fixtures have to say it out loud.
  Future<void> rename(String deckId, String name) => db.customUpdate(
    'UPDATE decks SET name = ? WHERE id = ?',
    variables: <Variable<Object>>[
      Variable<String>(name),
      Variable<String>(deckId),
    ],
    updates: <TableInfo<dynamic, dynamic>>{db.decks},
    updateKind: UpdateKind.update,
  );

  /// A card and the study state BR-09 says is born with it.
  Future<String> card(String id, {required String deckId}) async {
    await insertCard(db, id: id, deckId: deckId);
    await insertReviewState(db, cardId: id);

    return id;
  }

  /// One graded turn, at an instant the test chooses.
  ///
  /// `answered_at` is the whole subject of these tests, so it is required —
  /// unlike the shared `insertHistory`, which fixes it at `testNow` because
  /// every other suite is testing something the instant does not change.
  Future<void> answer(
    String id, {
    required String cardId,
    required DateTime at,
    String kind = 'scheduled',
    int generation = 1,
  }) async {
    await db.customInsert(
      'INSERT INTO study_answers (id, card_id, session_id, scheduler_type, '
      'scheduler_generation, kind, mode, action, answered_at) '
      "VALUES (?, ?, ?, 'eight_box', ?, ?, 'self_assess', 'remembered', ?)",
      variables: <Variable<Object>>[
        Variable<String>(id),
        Variable<String>(cardId),
        const Variable<String>(_sessionId),
        Variable<int>(generation),
        Variable<String>(kind),
        Variable<DateTime>(at),
      ],
      updates: <TableInfo<dynamic, dynamic>>{db.studyAnswers},
    );
  }

  Future<void> moveCard(String cardId, {required String toDeckId}) =>
      db.customUpdate(
        'UPDATE cards SET deck_id = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(toDeckId),
          Variable<String>(cardId),
        ],
        updates: <TableInfo<dynamic, dynamic>>{db.cards},
        updateKind: UpdateKind.update,
      );

  /// Points [deckId] at a new parent and touches nothing else.
  ///
  /// Deliberately **not** the production move: it does not rewrite
  /// `root_deck_id` and does not check depth, which is exactly how a corrupt or
  /// cyclic tree looks from the query's side. Only the cycle test uses it.
  Future<void> reparent(String deckId, {required String toParentId}) =>
      db.customUpdate(
        'UPDATE decks SET parent_deck_id = ? WHERE id = ?',
        variables: <Variable<Object>>[
          Variable<String>(toParentId),
          Variable<String>(deckId),
        ],
        updates: <TableInfo<dynamic, dynamic>>{db.decks},
        updateKind: UpdateKind.update,
      );

  /// Re-parents a deck and rewrites `root_deck_id` for its whole subtree — the
  /// production move's two writes (BR-71), spelled out here rather than driven
  /// through `DeckRepository`, so a Progress test does not fail because a Deck
  /// rule refused the move for reasons of its own.
  Future<void> moveSubtree(
    String deckId, {
    required String toParentId,
    required String toRootId,
  }) async {
    await db.customUpdate(
      'UPDATE decks SET parent_deck_id = ? WHERE id = ?',
      variables: <Variable<Object>>[
        Variable<String>(toParentId),
        Variable<String>(deckId),
      ],
      updates: <TableInfo<dynamic, dynamic>>{db.decks},
      updateKind: UpdateKind.update,
    );
    await db.updateSubtreeRootDeck(toRootId, progressNow, deckId);
  }

  /// A hard delete, which cascades to sub-decks, cards and answers.
  ///
  /// All four tables are declared: the cascade is SQLite's, so drift sees only
  /// the `decks` statement and would leave a stream watching `cards` or
  /// `study_answers` unaware that its rows had gone.
  Future<void> deleteDeck(String deckId) => db.customUpdate(
    'DELETE FROM decks WHERE id = ?',
    variables: <Variable<Object>>[Variable<String>(deckId)],
    updates: <TableInfo<dynamic, dynamic>>{
      db.decks,
      db.cards,
      db.studyAnswers,
      db.cardStudyStates,
    },
    updateKind: UpdateKind.delete,
  );

  /// Reset drops the schedule and bumps the generation; `study_answers` is not
  /// touched (BR-43). Written as the two statements a reset performs so a test
  /// can prove activity survives it.
  Future<void> resetTree(String rootDeckId) async {
    await db.customUpdate(
      'UPDATE card_study_states SET learned_at = NULL, due_at = NULL, '
      'answer_count = 0, scheduler_generation = scheduler_generation + 1 '
      'WHERE card_id IN (SELECT c.id FROM cards c INNER JOIN decks d '
      'ON d.id = c.deck_id WHERE d.root_deck_id = ?)',
      variables: <Variable<Object>>[Variable<String>(rootDeckId)],
      updates: <TableInfo<dynamic, dynamic>>{db.cardStudyStates},
      updateKind: UpdateKind.update,
    );
    await db.customUpdate(
      'UPDATE decks SET scheduler_generation = scheduler_generation + 1 '
      'WHERE id = ?',
      variables: <Variable<Object>>[Variable<String>(rootDeckId)],
      updates: <TableInfo<dynamic, dynamic>>{db.decks},
      updateKind: UpdateKind.update,
    );
  }

  static const String _sessionId = 'session-1';

  /// The one session every fixture answer belongs to. Sessions are a foreign key
  /// on `study_answers` and nothing in Progress reads them, so one is enough and
  /// naming it here keeps every test from repeating the setup.
  Future<void> seedSession({required String deckId}) =>
      insertSession(db, id: _sessionId, deckId: deckId, rootDeckId: deckId);
}

/// Registers a fresh database and repository per test.
ProgressReadHarness installProgressReadHarness() {
  final harness = ProgressReadHarness();
  setUp(() {
    harness.statements.clear();
    harness.db = openTestDatabase(log: harness.statements.add);
    harness.repository = ProgressRepositoryImpl(ProgressDao(harness.db));
  });

  return harness;
}

/// The row for [deckId] in the level [snapshot] describes.
///
/// Top-level rather than nested in one file's `main`, because both halves of
/// the read suite reach for it and a second copy is a second thing to keep in
/// step.
DeckActivity rowFor(DeckActivitySnapshot snapshot, String deckId) =>
    snapshot.decks.firstWhere((DeckActivity d) => d.deckId == deckId);

/// The id of the card-holding sub-deck [seedSingleDeck] creates.
const String cardDeckId = 'cards-a';

/// One root, one card-holding sub-deck under it, the session its answers belong
/// to, and one card.
///
/// **The card goes in the sub-deck, not in the root.** A root deck holds only
/// sub-decks (BR-58), so a fixture that put a card straight into `root-a` would
/// encode a state production cannot reach — and every assertion built on it
/// would be true of a database that cannot exist. The root's figures are
/// unchanged by the extra level: a root aggregates its whole subtree.
Future<void> seedSingleDeck(ProgressReadHarness harness) async {
  await harness.root('root-a', name: 'Alpha');
  await harness.subDeck(
    cardDeckId,
    parentId: 'root-a',
    rootId: 'root-a',
    contentType: 'card',
    name: 'Alpha cards',
  );
  await harness.seedSession(deckId: 'root-a');
  await harness.card('card-1', deckId: cardDeckId);
}
