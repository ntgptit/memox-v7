import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/query_log_interceptor.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_detail_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../database/support/test_database.dart';

/// `watchDeckDetail` — one read interaction for the deck screen (UC-06 step 4).
///
/// **What this file exists to prove, and why a behaviour test could not.** The
/// screen used to get its deck and its children from two statements: the
/// controller watched `childDecks`, then awaited `getDeckById` per emission. Every
/// behavioural assertion about that version passed. It rendered the right title
/// and the right rows, and a comment in the controller said the two facts "arrive
/// together". They did not — they were two snapshots, and a write landing between
/// them produced a screen composed of two different instants.
///
/// A test that only reads the emitted values cannot tell the two designs apart.
/// So this one counts statements, through a real `QueryInterceptor` on real
/// SQLite: the claim "one read" is measured, not asserted in prose.
void main() {
  late List<String> lines;
  late AppDatabase db;
  late DeckRepositoryImpl repository;
  int idCounter = 0;

  setUp(() {
    lines = <String>[];
    db = AppDatabase(
      NativeDatabase.memory().interceptWith(
        QueryLogInterceptor(sink: lines.add),
      ),
    );
    addTearDown(db.close);
    idCounter = 0;
    repository = DeckRepositoryImpl(
      DeckDao(db),
      idGenerator: () => 'gen-${++idCounter}',
      clock: () => testNow,
    );
  });

  /// Statements the log recorded that read rows.
  ///
  /// Reads only: an `UPDATE` goes through `runUpdate` and never carries the word,
  /// so a rename driven below appears in the log without inflating this count.
  List<String> reads() =>
      lines.where((String line) => line.contains('SELECT')).toList();

  /// Renames a deck without going through the repository.
  ///
  /// Deliberately raw. `renameDeck` reads the row first to check it exists, and
  /// that read would land in the same log this test is counting — so the write
  /// used to *trigger* a re-emission must not itself be a read. `updates:` is what
  /// tells drift to invalidate the streams watching `decks`.
  Future<void> rawRename(String deckId, String name) => db.customUpdate(
    'UPDATE decks SET name = ? WHERE id = ?',
    variables: <Variable<Object>>[
      Variable<String>(name),
      Variable<String>(deckId),
    ],
    updates: <TableInfo<Table, dynamic>>{db.decks},
  );

  /// Subscribes and returns the list every emission lands in.
  List<DeckDetail> watch(String deckId) {
    final emissions = <DeckDetail>[];
    final subscription = repository
        .watchDeckDetail(deckId)
        .listen(emissions.add);
    addTearDown(subscription.cancel);

    return emissions;
  }

  Future<DeckEntity> seedRoot(String name) => repository.createRootDeck(
    name: DeckName.parse(name).name!,
    schedulerType: SchedulerType.eightBox,
  );

  group('one read interaction', () {
    test('a re-emission costs exactly one statement, not two', () async {
      // The whole point of the change, measured. Two statements here would mean
      // the deck and the children came from two snapshots again.
      final root = await seedRoot('Japanese');
      await repository.createSubDeck(
        name: DeckName.parse('Hiragana').name!,
        parentDeckId: root.id,
      );

      final emissions = watch(root.id);
      await pumpEventQueue();
      expect(emissions, hasLength(1));

      // Everything before this line — the seeding, the first emission — is noise
      // for this assertion.
      lines.clear();
      await rawRename(root.id, 'Japanese N5');
      await pumpEventQueue();

      expect(emissions, hasLength(2));
      expect(emissions.last.deck.name, 'Japanese N5');
      expect(
        reads(),
        hasLength(1),
        reason:
            'One re-emission must run one statement. Two would mean the deck '
            'and its children were read separately again, which is the '
            'mixed-snapshot bug this method replaced. Statements seen: '
            '${reads()}',
      );
    });

    test('the deck and the children come from the same statement', () async {
      // The structural half of the claim: one statement produced both halves of
      // the read model, so there is no instant at which one was current and the
      // other was not.
      final root = await seedRoot('Japanese');
      await repository.createSubDeck(
        name: DeckName.parse('Hiragana').name!,
        parentDeckId: root.id,
      );

      lines.clear();
      final detail = await repository.watchDeckDetail(root.id).first;

      expect(detail.deck.name, 'Japanese');
      expect(detail.childDecks.map((DeckEntity d) => d.name), <String>[
        'Hiragana',
      ]);
      expect(reads(), hasLength(1));
      expect(reads().single, contains('FROM decks AS deck'));
    });
  });

  group('what the stream emits', () {
    test('a childless deck emits an empty list, not an error', () async {
      // The `LEFT JOIN` case. One row comes back with a null child, and the
      // difference between that and no rows at all is what keeps "empty" and
      // "gone" apart.
      final root = await seedRoot('Empty');

      final detail = await repository.watchDeckDetail(root.id).first;

      expect(detail.deck.id, root.id);
      expect(detail.childDecks, isEmpty);
    });

    test('children are ordered by creation, oldest first', () async {
      final root = await seedRoot('Japanese');
      for (final String name in <String>['First', 'Second', 'Third']) {
        await repository.createSubDeck(
          name: DeckName.parse(name).name!,
          parentDeckId: root.id,
        );
      }

      final detail = await repository.watchDeckDetail(root.id).first;

      expect(detail.childDecks.map((DeckEntity d) => d.name), <String>[
        'First',
        'Second',
        'Third',
      ]);
    });

    test('renaming the deck re-emits with the new name', () async {
      final root = await seedRoot('Before');
      final emissions = watch(root.id);
      await pumpEventQueue();

      await repository.renameDeck(
        deckId: root.id,
        name: DeckName.parse('After').name!,
      );
      await pumpEventQueue();

      expect(emissions.last.deck.name, 'After');
    });

    test('adding a child re-emits with it listed', () async {
      final root = await seedRoot('Japanese');
      final emissions = watch(root.id);
      await pumpEventQueue();
      expect(emissions.last.childDecks, isEmpty);

      await repository.createSubDeck(
        name: DeckName.parse('Hiragana').name!,
        parentDeckId: root.id,
      );
      await pumpEventQueue();

      expect(emissions.last.childDecks.map((DeckEntity d) => d.name), <String>[
        'Hiragana',
      ]);
    });

    test('deleting a child re-emits without it', () async {
      final root = await seedRoot('Japanese');
      final child = await repository.createSubDeck(
        name: DeckName.parse('Hiragana').name!,
        parentDeckId: root.id,
      );
      final emissions = watch(root.id);
      await pumpEventQueue();
      expect(emissions.last.childDecks, hasLength(1));

      await repository.deleteDeck(child.id);
      await pumpEventQueue();

      expect(emissions.last.childDecks, isEmpty);
    });

    test('moving a child away re-emits without it', () async {
      // The interesting variant of removal: the child still exists, it is just
      // somewhere else now. A read keyed on the child rather than on the parent
      // would miss this.
      final root = await seedRoot('Japanese');
      final other = await repository.createSubDeck(
        name: DeckName.parse('Other').name!,
        parentDeckId: root.id,
      );
      final moving = await repository.createSubDeck(
        name: DeckName.parse('Moving').name!,
        parentDeckId: root.id,
      );

      final emissions = watch(root.id);
      await pumpEventQueue();
      expect(emissions.last.childDecks, hasLength(2));

      await repository.moveDeck(
        deckId: moving.id,
        targetParentDeckId: other.id,
      );
      await pumpEventQueue();

      expect(emissions.last.childDecks.map((DeckEntity d) => d.name), <String>[
        'Other',
      ]);
    });

    test('mayOfferReset follows the children in the same emission', () async {
      // The reason the two facts must share a snapshot at all: this getter reads
      // both. A deck whose type came from before a create and whose children came
      // from after it would offer an action the repository then refuses.
      final root = await seedRoot('Japanese');
      final branch = await repository.createSubDeck(
        name: DeckName.parse('Branch').name!,
        parentDeckId: root.id,
      );

      final emissions = watch(branch.id);
      await pumpEventQueue();
      expect(emissions.last.mayOfferReset, isTrue);

      await repository.createSubDeck(
        name: DeckName.parse('Leaf').name!,
        parentDeckId: branch.id,
      );
      await pumpEventQueue();

      expect(emissions.last.mayOfferReset, isFalse);
    });
  });

  group('not found', () {
    test('a deck that never existed errors as NotFoundFailure', () async {
      await expectLater(
        repository.watchDeckDetail('nope').first,
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test(
      'a deck deleted while watched errors rather than emitting empty',
      () async {
        // UC-03 E1. "No rows" must not be mistaken for "a deck with no children" —
        // the screen renders a way back for one and an empty state for the other.
        final root = await seedRoot('Doomed');
        final emissions = <DeckDetail>[];
        final errors = <Object>[];
        final subscription = repository
            .watchDeckDetail(root.id)
            .listen(emissions.add, onError: errors.add);
        addTearDown(subscription.cancel);
        await pumpEventQueue();
        expect(emissions, hasLength(1));

        await repository.deleteDeck(root.id);
        await pumpEventQueue();

        expect(emissions, hasLength(1), reason: 'no further value emissions');
        expect(errors.single, isA<NotFoundFailure>());
      },
    );
  });
}
