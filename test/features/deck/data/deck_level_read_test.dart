// `isNull` collides with drift's SQL builder of the same name; the matcher is
// what this file means every time.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/query_log_interceptor.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../../database/support/test_database.dart';

/// `watchDeckList` with a parent — one read interaction for a level inside a
/// deck (UC-06 step 4).
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
///
/// The claim got *larger* when the two deck screens became one. A child row now
/// carries its whole subtree's card total and due count, computed by a recursive
/// CTE — three more aggregates that a naive implementation would have fetched
/// per row, turning one statement into one-plus-N. The count below is what stops
/// that.
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
  ///
  /// One entry per *statement*, not per `SELECT` keyword — the interceptor logs a
  /// statement as one line, so the recursive CTE's inner selects do not each
  /// count.
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

  Stream<DeckListSnapshot> levelOf(String deckId) =>
      repository.watchDeckList(parentDeckId: deckId, now: testNow);

  /// Subscribes and returns the list every emission lands in.
  List<DeckListSnapshot> watch(String deckId) {
    final emissions = <DeckListSnapshot>[];
    final subscription = levelOf(deckId).listen(emissions.add);
    addTearDown(subscription.cancel);

    return emissions;
  }

  List<String> namesOf(DeckListSnapshot snapshot) =>
      snapshot.decks.map((DeckSummary summary) => summary.deck.name).toList();

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
      expect(emissions.last.parent?.name, 'Japanese N5');
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
      final level = await levelOf(root.id).first;

      expect(level.parent?.name, 'Japanese');
      expect(namesOf(level), <String>['Hiragana']);
      expect(reads(), hasLength(1));
      expect(reads().single, contains('FROM decks AS parent'));
    });

    test('the subtree aggregates are in that same statement', () async {
      // The 1+N guard. Three children, each with a subtree of its own, and still
      // one statement: the counts come from the recursive CTE, not from a query
      // per row.
      final root = await seedRoot('Japanese');
      for (final String name in <String>['A', 'B', 'C']) {
        final branch = await repository.createSubDeck(
          name: DeckName.parse(name).name!,
          parentDeckId: root.id,
        );
        await repository.createSubDeck(
          name: DeckName.parse('$name-leaf').name!,
          parentDeckId: branch.id,
        );
      }

      lines.clear();
      final level = await levelOf(root.id).first;

      expect(level.decks, hasLength(3));
      expect(reads(), hasLength(1), reason: 'statements seen: ${reads()}');
    });
  });

  group('what the stream emits', () {
    test('a childless deck emits an empty list, not an error', () async {
      // The `LEFT JOIN` case. One row comes back with a null child, and the
      // difference between that and no rows at all is what keeps "empty" and
      // "gone" apart.
      final root = await seedRoot('Empty');

      final level = await levelOf(root.id).first;

      expect(level.parent?.id, root.id);
      expect(level.decks, isEmpty);
    });

    test('children are ordered by creation, oldest first', () async {
      final root = await seedRoot('Japanese');
      for (final String name in <String>['First', 'Second', 'Third']) {
        await repository.createSubDeck(
          name: DeckName.parse(name).name!,
          parentDeckId: root.id,
        );
      }

      final level = await levelOf(root.id).first;

      expect(namesOf(level), <String>['First', 'Second', 'Third']);
    });

    test('a child carries the scheduler resolved from its root (BR-06)', () async {
      // A sub-deck's own `scheduler_type` column is NULL by rule, so a summary
      // built from the entity alone would say "unknown" on every row below the
      // first level. The query resolves it through `root_deck_id`; this is that
      // resolution, end to end.
      final root = await repository.createRootDeck(
        name: DeckName.parse('Japanese').name!,
        schedulerType: SchedulerType.sm2,
      );
      final branch = await repository.createSubDeck(
        name: DeckName.parse('Branch').name!,
        parentDeckId: root.id,
      );
      await repository.createSubDeck(
        name: DeckName.parse('Leaf').name!,
        parentDeckId: branch.id,
      );

      final level = await levelOf(branch.id).first;

      expect(level.decks.single.deck.schedulerType, isNull);
      expect(level.decks.single.schedulerType, SchedulerType.sm2);
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

      expect(emissions.last.parent?.name, 'After');
    });

    test('adding a child re-emits with it listed', () async {
      final root = await seedRoot('Japanese');
      final emissions = watch(root.id);
      await pumpEventQueue();
      expect(emissions.last.decks, isEmpty);

      await repository.createSubDeck(
        name: DeckName.parse('Hiragana').name!,
        parentDeckId: root.id,
      );
      await pumpEventQueue();

      expect(namesOf(emissions.last), <String>['Hiragana']);
    });

    test('deleting a child re-emits without it', () async {
      final root = await seedRoot('Japanese');
      final child = await repository.createSubDeck(
        name: DeckName.parse('Hiragana').name!,
        parentDeckId: root.id,
      );
      final emissions = watch(root.id);
      await pumpEventQueue();
      expect(emissions.last.decks, hasLength(1));

      await repository.deleteDeck(child.id);
      await pumpEventQueue();

      expect(emissions.last.decks, isEmpty);
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
      expect(emissions.last.decks, hasLength(2));

      await repository.moveDeck(
        deckId: moving.id,
        targetParentDeckId: other.id,
      );
      await pumpEventQueue();

      expect(namesOf(emissions.last), <String>['Other']);
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
      await expectLater(levelOf('nope').first, throwsA(isA<NotFoundFailure>()));
    });

    test(
      'a deck deleted while watched errors rather than emitting empty',
      () async {
        // UC-03 E1. "No rows" must not be mistaken for "a deck with no children" —
        // the screen renders a way back for one and an empty state for the other.
        final root = await seedRoot('Doomed');
        final emissions = <DeckListSnapshot>[];
        final errors = <Object>[];
        final subscription = levelOf(
          root.id,
        ).listen(emissions.add, onError: errors.add);
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
