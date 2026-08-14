import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_batch_entity.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

import '../../../../database/support/test_database.dart';
import '../../../../support/trash_wiring.dart';

/// A real SQLite database with the three repositories a Trash test needs, all
/// sharing one connection and one movable clock.
///
/// **The production wiring, not doubles.** Every rule under test — the batch,
/// the cascade, the content-type reset, the session invalidation, the
/// thirty-day boundary — is behaviour of SQL and of transactions. A faked
/// repository would assert that the code calls the API it was written to call,
/// which is the one thing that cannot be wrong here.
final class TrashHarness {
  late AppDatabase db;
  late DeckRepository deckRepository;
  late CardRepository cardRepository;
  late TrashRepository trashRepository;
  late TrashDao dao;

  /// Movable, so the retention boundary can be crossed without waiting thirty
  /// days and without any layer reading the wall clock (AD-06).
  late DateTime now;

  int idCounter = 0;

  String nextId() => 'gen-${++idCounter}';

  // ---- reads a test asserts on -------------------------------------------

  Future<List<TrashBatchEntity>> batches() =>
      trashRepository.watchBatches().first;

  Future<TrashBatchEntity> onlyBatch() async {
    final all = await batches();
    expect(all, hasLength(1));

    return all.single;
  }

  Future<String?> deckBatchOf(String deckId) async =>
      (await db
              .customSelect(
                'SELECT delete_batch_id FROM decks WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(deckId)],
              )
              .getSingleOrNull())
          ?.read<String?>('delete_batch_id');

  Future<String?> cardBatchOf(String cardId) async =>
      (await db
              .customSelect(
                'SELECT delete_batch_id FROM cards WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(cardId)],
              )
              .getSingleOrNull())
          ?.read<String?>('delete_batch_id');

  Future<String?> parentOf(String deckId) async =>
      (await db
              .customSelect(
                'SELECT parent_deck_id FROM decks WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(deckId)],
              )
              .getSingleOrNull())
          ?.read<String?>('parent_deck_id');

  Future<String?> rootOf(String deckId) async =>
      (await db
              .customSelect(
                'SELECT root_deck_id FROM decks WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(deckId)],
              )
              .getSingleOrNull())
          ?.read<String?>('root_deck_id');

  Future<String?> deckOfCard(String cardId) async =>
      (await db
              .customSelect(
                'SELECT deck_id FROM cards WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(cardId)],
              )
              .getSingleOrNull())
          ?.read<String?>('deck_id');

  Future<String> contentTypeOf(String deckId) async =>
      (await db
              .customSelect(
                'SELECT content_type FROM decks WHERE id = ?',
                variables: <Variable<Object>>[Variable<String>(deckId)],
              )
              .getSingle())
          .read<String>('content_type');

  Future<int> countAll(String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS c FROM $table').getSingle())
          .read<int>('c');

  Future<int> countBatches() => countAll('delete_batches');

  /// Every invariant, against this database — the cheapest way to prove a write
  /// left the graph consistent rather than merely doing what the test asked.
  Future<List<String>> invariantOffenders(Map<String, String> queries) async {
    final offenders = <String>[];
    for (final entry in queries.entries) {
      final rows = await db.customSelect(entry.value).get();
      if (rows.isEmpty) continue;
      offenders.add(entry.key);
    }

    return offenders;
  }

  // ---- fixtures -----------------------------------------------------------

  /// root → branch → leaf, with the leaf holding [cardCount] cards.
  Future<
    ({
      DeckEntity root,
      DeckEntity branch,
      DeckEntity leaf,
      List<String> cardIds,
    })
  >
  seedTree({
    int cardCount = 1,
    String prefix = '',
    SchedulerType scheduler = SchedulerType.eightBox,
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

    final cardIds = <String>[];
    for (var index = 0; index < cardCount; index++) {
      final card = await cardRepository.createCard(
        deckId: leaf.id,
        front: CardText.parse(
          '$prefix front $index',
          side: CardSide.front,
        ).text!,
        back: CardText.parse('$prefix back $index', side: CardSide.back).text!,
      );
      cardIds.add(card.id);
    }

    return (root: root, branch: branch, leaf: leaf, cardIds: cardIds);
  }
}

/// Installs the harness for the enclosing group.
TrashHarness installTrashHarness() {
  final harness = TrashHarness();
  setUp(() {
    harness.db = openTestDatabase();
    harness.idCounter = 0;
    harness.now = testNow;
    DateTime clock() => harness.now;

    final trash = contentTrashForTest(
      harness.db,
      clock: clock,
      idGenerator: harness.nextId,
    );
    harness.dao = TrashDao(harness.db);
    harness.deckRepository = DeckRepositoryImpl(
      DeckDao(harness.db),
      study: StudyRepositoryImpl(StudyDao(harness.db)),
      trash: trash,
      idGenerator: harness.nextId,
      clock: clock,
    );
    harness.cardRepository = CardRepositoryImpl(
      harness.db,
      trash: trash,
      idGenerator: harness.nextId,
      clock: clock,
    );
    harness.trashRepository = TrashRepositoryImpl(harness.dao, clock: clock);
  });

  return harness;
}
