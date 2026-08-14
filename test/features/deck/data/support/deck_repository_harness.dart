import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../../database/support/test_database.dart';
import '../../../../support/trash_wiring.dart';

/// Shared harness for the repository integration tests.
///
/// One real in-memory SQLite database per test, with both repositories on
/// top of it, a deterministic id sequence (`gen-1`, `gen-2`, …) shared across
/// them, and a mutable fixed clock — no test ever reads the wall clock. Raw
/// readers go through `customSelect` on purpose: asserting what is *in the
/// table* must not depend on the mappers under test.
final class DeckRepositoryHarness {
  late AppDatabase db;
  late DeckRepositoryImpl deckRepository;
  late CardRepositoryImpl cardRepository;
  int idCounter = 0;
  DateTime currentInstant = testNow;

  /// Every statement the database has run, newest last — the production query
  /// interceptor, kept for what it can prove rather than for what it prints.
  ///
  /// Use it for claims about *how many* reads an operation costs. A repository
  /// that reads a card's tags one card at a time returns exactly the records a
  /// single grouped read returns, so no assertion on the result can tell the
  /// two apart; only the statement count can.
  final List<String> statements = <String>[];

  /// [statements] since the last [clearStatements], counting only the ones
  /// whose text contains [fragment] — so a test names the read it means rather
  /// than the transaction boundaries and pragmas around it.
  int countStatements(String fragment) =>
      statements.where((String line) => line.contains(fragment)).length;

  /// Drops everything recorded so far, so a count covers the operation under
  /// test and not the seeding before it.
  void clearStatements() => statements.clear();

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
        'SELECT * FROM card_study_states WHERE card_id = ?',
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

  /// Cards a deck still shows (BR-183). Since v8 a deleted card keeps its row,
  /// so `countAll('cards')` and "cards the user can see" are two questions.
  Future<int> activeCardCount(String deckId) async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM cards '
          'WHERE deck_id = ? AND delete_batch_id IS NULL',
          variables: <Variable<Object>>[Variable<String>(deckId)],
        )
        .getSingle();

    return row.read<int>('c');
  }

  /// Decks the tree still shows (BR-183).
  Future<int> activeDeckCount() async {
    final row = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM decks WHERE delete_batch_id IS NULL',
        )
        .getSingle();

    return row.read<int>('c');
  }

  /// The batch a row was marked with, or null while it is active.
  Future<String?> deleteBatchOfCard(String cardId) async =>
      (await rawCard(cardId))?.read<String?>('delete_batch_id');

  Future<String?> deleteBatchOfDeck(String deckId) async =>
      (await rawDeck(deckId))?.read<String?>('delete_batch_id');

  /// root → branch → leaf, three levels (BR-55). The leaf stays `unset` so
  /// individual tests decide what it becomes.
  Future<({DeckEntity root, DeckEntity branch, DeckEntity leaf})> seedTree({
    SchedulerType scheduler = SchedulerType.eightBox,
    String prefix = '',
  }) async {
    final root = await deckRepository.createRootDeck(
      name: DeckName.parse('${prefix}Root').name!,
      schedulerType: scheduler,
    );
    final branch = await deckRepository.createSubDeck(
      name: DeckName.parse('${prefix}Branch').name!,
      parentDeckId: root.id,
    );
    final leaf = await deckRepository.createSubDeck(
      name: DeckName.parse('${prefix}Leaf').name!,
      parentDeckId: branch.id,
    );

    return (root: root, branch: branch, leaf: leaf);
  }

  /// A root with a strictly linear chain of sub-decks below it, [totalLevels]
  /// decks tall counting the root as level 1 (BR-55). Returns the chain from
  /// root (index 0) to deepest leaf.
  Future<List<DeckEntity>> seedChain(
    int totalLevels, {
    String prefix = 'chain-',
  }) async {
    final decks = <DeckEntity>[
      await deckRepository.createRootDeck(
        name: DeckName.parse('${prefix}1').name!,
        schedulerType: SchedulerType.eightBox,
      ),
    ];
    for (var level = 2; level <= totalLevels; level++) {
      decks.add(
        await deckRepository.createSubDeck(
          name: DeckName.parse('$prefix$level').name!,
          parentDeckId: decks.last.id,
        ),
      );
    }

    return decks;
  }
}

/// Registers a fresh database + repositories per test and returns the harness
/// whose fields each test reads.
DeckRepositoryHarness installDeckRepositoryHarness() {
  final harness = DeckRepositoryHarness();
  setUp(() {
    harness.statements.clear();
    harness.db = openTestDatabase(log: harness.statements.add);
    harness.idCounter = 0;
    harness.currentInstant = testNow;
    String nextId() => 'gen-${++harness.idCounter}';
    DateTime clock() => harness.currentInstant;
    final trash = contentTrashForTest(
      harness.db,
      clock: clock,
      idGenerator: nextId,
    );
    harness.deckRepository = DeckRepositoryImpl(
      DeckDao(harness.db),
      study: StudyRepositoryImpl(StudyDao(harness.db)),
      trash: trash,
      idGenerator: nextId,
      clock: clock,
    );
    harness.cardRepository = CardRepositoryImpl(
      harness.db,
      trash: trash,
      idGenerator: nextId,
      clock: clock,
    );
  });

  return harness;
}
