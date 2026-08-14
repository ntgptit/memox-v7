@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../card/data/support/card_text_fixture.dart';
import '../../../../support/trash_wiring.dart';

/// The web runtime proof M4.2 left open: the production web connection —
/// `sqlite3.wasm` plus the drift worker, opened by `AppDatabase.open()` —
/// executes real inserts and real typed queries, recursion included.
///
/// Run with: `flutter test --platform chrome
/// test/features/deck/data/web/deck_repository_web_test.dart`
///
/// Deliberately NOT accepted as evidence: asserting the wasm file exists,
/// compiling the queries, or a mocked executor. This opens the database and
/// reads its own writes back.
void main() {
  // Stable ids so the fixture can be recognised — and removed — across runs
  // against the same persistent browser storage.
  const fixtureIds = <String>[
    'web-smoke-root',
    'web-smoke-branch',
    'web-smoke-leaf',
    'web-smoke-card',
  ];
  final fixedInstant = DateTime.utc(2026, 7, 29, 12);

  test('production web database round-trips repository writes', () async {
    final db = AppDatabase.open();

    var nextIdIndex = 0;
    String nextId() => fixtureIds[nextIdIndex++];
    DateTime clock() => fixedInstant;
    final repository = DeckRepositoryImpl(
      DeckDao(db),
      trash: contentTrashForTest(db, clock: clock),
      study: StudyRepositoryImpl(StudyDao(db)),
      idGenerator: nextId,
      clock: clock,
    );
    final cardRepository = CardRepositoryImpl(
      db,
      trash: contentTrashForTest(db, clock: clock),
      idGenerator: nextId,
      clock: clock,
    );

    // A previous run may have left the fixture behind (web storage is
    // persistent) — start clean so this run's asserts mean something.
    await db.customStatement(
      "DELETE FROM decks WHERE id = '${fixtureIds.first}'",
    );

    try {
      // Real writes through the production connection.
      final root = await repository.createRootDeck(
        name: DeckName.parse('Web smoke root').name!,
        schedulerType: SchedulerType.eightBox,
      );
      final branch = await repository.createSubDeck(
        name: DeckName.parse('Web smoke branch').name!,
        parentDeckId: root.id,
      );
      final leaf = await repository.createSubDeck(
        name: DeckName.parse('Web smoke leaf').name!,
        parentDeckId: branch.id,
      );
      final card = await cardRepository.createCard(
        deckId: leaf.id,
        front: cardText('web front'),
        back: cardText('web back', side: CardSide.back),
      );

      // Typed named query, executed for real.
      final rereadRoot = await db.deckById(root.id).getSingle();
      expect(rereadRoot.name, 'Web smoke root');
      expect(rereadRoot.rootDeckId, root.id);
      expect(rereadRoot.schedulerType, 'eight_box');

      // The recursive CTE runs on the wasm build too.
      final subtree = await db.subtreeDeckIds(root.id).get();
      expect(subtree.toSet(), <String>{root.id, branch.id, leaf.id});

      // BR-09 held over the web path: exactly one study state, box 1.
      final state = await db.studyStateByCard(card.id).getSingle();
      expect(state.currentBox, 1);
      expect(state.dueAt, isNull);

      // And the repository's watch() emits over this connection as well.
      final firstEmission = await repository.watchRootDecks().first;
      expect(firstEmission.map((DeckEntity d) => d.id), contains(root.id));
    } finally {
      // Leave the storage the way we found it, so reruns start clean even
      // when an assert above failed.
      await db.customStatement(
        "DELETE FROM decks WHERE id = '${fixtureIds.first}'",
      );
      await db.close();
    }
  });
}
