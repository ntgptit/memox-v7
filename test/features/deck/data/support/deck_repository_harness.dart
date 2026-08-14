import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/tag_catalog_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../../database/support/test_database.dart';

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

  /// The tag catalog, over the **same** database (M99.23, UC-12).
  ///
  /// Built here rather than in each catalog test so that a rename or a delete
  /// is provably acting on the rows the card repository just wrote — two
  /// databases would let a merge test pass against tags nothing was linked to.
  late TagCatalogRepositoryImpl tagCatalogRepository;
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
    harness.deckRepository = DeckRepositoryImpl(
      DeckDao(harness.db),
      study: StudyRepositoryImpl(StudyDao(harness.db)),
      idGenerator: nextId,
      clock: clock,
    );
    harness.cardRepository = CardRepositoryImpl(
      harness.db,
      idGenerator: nextId,
      clock: clock,
    );
    // No clock and no id generator: a catalog operation mints nothing and
    // stamps nothing (BR-188).
    harness.tagCatalogRepository = TagCatalogRepositoryImpl(harness.db);
  });

  return harness;
}
