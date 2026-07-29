import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/deck_repository_impl.dart';
import 'package:memox/features/deck/data/local/deck_dao.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/domain/scheduler_type_model.dart';

import '../../../../database/support/test_database.dart';

/// Shared harness for the repository integration tests.
///
/// One real in-memory SQLite database and one repository per test, with a
/// deterministic id sequence (`gen-1`, `gen-2`, …) and a mutable fixed clock —
/// no test ever reads the wall clock. Raw readers go through `customSelect` on
/// purpose: asserting what is *in the table* must not depend on the mappers
/// under test.
final class DeckRepositoryHarness {
  late AppDatabase db;
  late DeckRepositoryImpl repository;
  int idCounter = 0;
  DateTime currentInstant = testNow;

  Future<QueryRow?> rawDeck(String id) => db
      .customSelect(
        'SELECT * FROM decks WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>(id)],
      )
      .getSingleOrNull();

  Future<QueryRow?> rawCard(String id) => db
      .customSelect(
        'SELECT * FROM cards WHERE id = ?',
        variables: <Variable<Object>>[Variable<String>(id)],
      )
      .getSingleOrNull();

  Future<List<QueryRow>> rawStates(String cardId) => db
      .customSelect(
        'SELECT * FROM card_review_states WHERE card_id = ?',
        variables: <Variable<Object>>[Variable<String>(cardId)],
      )
      .get();

  Future<int> countAll(String table) async {
    final row = await db
        .customSelect('SELECT COUNT(*) AS c FROM $table')
        .getSingle();

    return row.read<int>('c');
  }

  Future<String> contentTypeOf(String deckId) async =>
      (await rawDeck(deckId))!.read<String>('content_type');

  /// root → branch → leaf, three levels (BR-55). The leaf stays `unset` so
  /// individual tests decide what it becomes.
  Future<({DeckEntity root, DeckEntity branch, DeckEntity leaf})> seedTree({
    SchedulerType scheduler = SchedulerType.eightBox,
    String prefix = '',
  }) async {
    final root = await repository.createRootDeck(
      name: '${prefix}Root',
      schedulerType: scheduler,
    );
    final branch = await repository.createSubDeck(
      name: '${prefix}Branch',
      parentDeckId: root.id,
    );
    final leaf = await repository.createSubDeck(
      name: '${prefix}Leaf',
      parentDeckId: branch.id,
    );

    return (root: root, branch: branch, leaf: leaf);
  }
}

/// Registers a fresh database + repository per test and returns the harness
/// whose fields each test reads.
DeckRepositoryHarness installDeckRepositoryHarness() {
  final harness = DeckRepositoryHarness();
  setUp(() {
    harness.db = openTestDatabase();
    harness.idCounter = 0;
    harness.currentInstant = testNow;
    harness.repository = DeckRepositoryImpl(
      DeckDao(harness.db),
      idGenerator: () => 'gen-${++harness.idCounter}',
      clock: () => harness.currentInstant,
    );
  });

  return harness;
}
