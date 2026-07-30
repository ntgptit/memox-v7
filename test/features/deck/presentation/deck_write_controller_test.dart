import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/domain/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/deck_submit_state.dart';
import 'package:memox/features/deck/presentation/deck_write_controller.dart';

import 'support/fake_deck_repository.dart';

/// The six deck mutations, one controller each.
///
/// The behaviour under test is the state machine, not the persistence: what the
/// writes actually do to the tree is asserted against real SQLite in
/// `test/features/deck/data/`. Here the question is whether a double tap sends
/// one write, whether a failure keeps the user's input, and whether an inline
/// error points at a field instead of arriving as a banner.
void main() {
  ProviderContainer containerWith(FakeDeckRepository repository) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        deckRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('create root deck (UC-02)', () {
    test('writes the name and the chosen scheduler', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      await notifier.submit(
        name: '  Japanese  ',
        schedulerType: SchedulerType.sm2,
      );

      expect(repository.createdRootDecks, hasLength(1));
      // Trimming is the repository's job via `validateName`; the controller
      // passes what was typed so the rule has one owner.
      expect(repository.createdRootDecks.single.name, '  Japanese  ');
      expect(repository.createdRootDecks.single.scheduler, SchedulerType.sm2);
      expect(container.read(createRootDeckControllerProvider).isDone, isTrue);
    });

    test('both schedulers are accepted', () async {
      for (final scheduler in <SchedulerType>[
        SchedulerType.eightBox,
        SchedulerType.sm2,
      ]) {
        final repository = FakeDeckRepository();
        final container = containerWith(repository);

        await container
            .read(createRootDeckControllerProvider.notifier)
            .submit(name: 'Deck', schedulerType: scheduler);

        expect(repository.createdRootDecks.single.scheduler, scheduler);
      }
    });

    test('a missing scheduler is an inline error and writes nothing', () async {
      // BR-11: no implicit default. Passing `eightBox` as a placeholder is
      // exactly the silent default the rule forbids, so "not chosen" has to be
      // representable and has to be refused.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(name: 'Japanese', schedulerType: null);

      final state = container.read(createRootDeckControllerProvider);
      expect(state.isSchedulerMissing, isTrue);
      expect(state.nameProblem, isNull);
      expect(state.isDone, isFalse);
      expect(repository.createdRootDecks, isEmpty);
    });

    test('an empty name is an inline error and writes nothing', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(name: '   ', schedulerType: SchedulerType.sm2);

      expect(
        container.read(createRootDeckControllerProvider).nameProblem,
        DeckNameProblem.empty,
      );
      expect(repository.createdRootDecks, isEmpty);
    });

    test('an over-length name is an inline error and writes nothing', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(
            name: 'a' * (DeckEntity.maxNameLength + 1),
            schedulerType: SchedulerType.sm2,
          );

      expect(
        container.read(createRootDeckControllerProvider).nameProblem,
        DeckNameProblem.tooLong,
      );
      expect(repository.createdRootDecks, isEmpty);
    });

    test('both fields can be wrong at once', () async {
      final container = containerWith(FakeDeckRepository());

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(name: '', schedulerType: null);

      final state = container.read(createRootDeckControllerProvider);
      expect(state.nameProblem, DeckNameProblem.empty);
      expect(state.isSchedulerMissing, isTrue);
    });

    test('a persistence failure is reported and does not report done', () async {
      // UC-02 E4. The form keeps the typed text because the widget owns it; what
      // matters here is that the state says "failed", not "finished".
      final repository = FakeDeckRepository(
        writeFailure: const DatabaseFailure(message: 'disk full'),
      );
      final container = containerWith(repository);

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(name: 'Japanese', schedulerType: SchedulerType.sm2);

      final state = container.read(createRootDeckControllerProvider);
      expect(state.failure, isA<DatabaseFailure>());
      expect(state.isDone, isFalse);
      expect(state.isSubmitting, isFalse);
    });

    test('a second submit while the first is in flight is ignored', () async {
      // The double-submit guard. Without it a double tap creates two decks, and
      // the user sees one because the list dedupes nothing.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      final first = notifier.submit(
        name: 'Japanese',
        schedulerType: SchedulerType.sm2,
      );
      final second = notifier.submit(
        name: 'Japanese',
        schedulerType: SchedulerType.sm2,
      );
      await Future.wait<void>(<Future<void>>[first, second]);

      expect(repository.createdRootDecks, hasLength(1));
    });

    test('a submit after success is ignored until reset', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      await notifier.submit(name: 'A', schedulerType: SchedulerType.sm2);
      await notifier.submit(name: 'B', schedulerType: SchedulerType.sm2);
      expect(repository.createdRootDecks, hasLength(1));

      notifier.reset();
      await notifier.submit(name: 'B', schedulerType: SchedulerType.sm2);

      expect(repository.createdRootDecks, hasLength(2));
    });

    test('reset clears a failure so the form reopens clean', () async {
      final container = containerWith(
        FakeDeckRepository(writeFailure: const DatabaseFailure(message: 'x')),
      );
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      await notifier.submit(name: 'A', schedulerType: SchedulerType.sm2);
      notifier.reset();

      expect(
        container.read(createRootDeckControllerProvider),
        const DeckSubmitState(),
      );
    });
  });

  group('create sub-deck (UC-08)', () {
    test('writes the name under the parent, with no scheduler', () async {
      // A sub-deck must not carry scheduler columns (BR-06), which is why this
      // controller has no scheduler parameter at all rather than passing null.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createSubDeckControllerProvider('parent-1').notifier)
          .submit(name: 'Branch');

      expect(repository.createdSubDecks.single.name, 'Branch');
      expect(repository.createdSubDecks.single.parentDeckId, 'parent-1');
    });

    test('a depth refusal from the repository surfaces as a conflict', () async {
      // BR-55. The UI does not know the parent's depth — the repository refuses
      // before writing anything, and the form shows the conflict.
      final repository = FakeDeckRepository(
        writeFailure: const ConflictFailure(message: 'too deep'),
      );
      final container = containerWith(repository);

      await container
          .read(createSubDeckControllerProvider('parent-1').notifier)
          .submit(name: 'Branch');

      expect(
        container.read(createSubDeckControllerProvider('parent-1')).failure,
        isA<ConflictFailure>(),
      );
    });

    test('two parents keep independent state', () async {
      // The reason these are families. One form failing must not put the other
      // deck's form into an error state.
      final container = containerWith(
        FakeDeckRepository(writeFailure: const DatabaseFailure(message: 'x')),
      );

      await container
          .read(createSubDeckControllerProvider('a').notifier)
          .submit(name: 'One');

      expect(
        container.read(createSubDeckControllerProvider('a')).failure,
        isNotNull,
      );
      expect(
        container.read(createSubDeckControllerProvider('b')).failure,
        isNull,
      );
    });

    test('an empty name writes nothing', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createSubDeckControllerProvider('parent-1').notifier)
          .submit(name: ' ');

      expect(repository.createdSubDecks, isEmpty);
    });
  });

  group('rename (UC-03, BR-01)', () {
    test('writes the new name', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(renameDeckControllerProvider('deck-1').notifier)
          .submit(name: 'Renamed');

      expect(repository.renames.single.deckId, 'deck-1');
      expect(repository.renames.single.name, 'Renamed');
    });

    test('validation blocks the write', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(renameDeckControllerProvider('deck-1').notifier)
          .submit(name: '');

      expect(repository.renames, isEmpty);
      expect(
        container.read(renameDeckControllerProvider('deck-1')).nameProblem,
        DeckNameProblem.empty,
      );
    });

    test('a deck deleted elsewhere reports not-found (UC-03 E1)', () async {
      final container = containerWith(
        FakeDeckRepository(
          writeFailure: const NotFoundFailure(message: 'gone'),
        ),
      );

      await container
          .read(renameDeckControllerProvider('deck-1').notifier)
          .submit(name: 'Renamed');

      expect(
        container.read(renameDeckControllerProvider('deck-1')).failure,
        isA<NotFoundFailure>(),
      );
    });

    test('double submit sends one rename', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        renameDeckControllerProvider('deck-1').notifier,
      );

      await Future.wait<void>(<Future<void>>[
        notifier.submit(name: 'A'),
        notifier.submit(name: 'A'),
      ]);

      expect(repository.renames, hasLength(1));
    });
  });

  group('delete (UC-03, BR-03)', () {
    test('deletes and reports done', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(deleteDeckControllerProvider('deck-1').notifier)
          .submit();

      expect(repository.deletes, <String>['deck-1']);
      expect(
        container.read(deleteDeckControllerProvider('deck-1')).isDone,
        isTrue,
      );
    });

    test('double confirm sends one delete', () async {
      // Confirming twice would send a second delete that fails against data the
      // first already removed — an error for an action that worked.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        deleteDeckControllerProvider('deck-1').notifier,
      );

      await Future.wait<void>(<Future<void>>[
        notifier.submit(),
        notifier.submit(),
      ]);

      expect(repository.deletes, hasLength(1));
    });

    test('a failure leaves the dialog able to retry', () async {
      final container = containerWith(
        FakeDeckRepository(writeFailure: const DatabaseFailure(message: 'x')),
      );
      final notifier = container.read(
        deleteDeckControllerProvider('deck-1').notifier,
      );

      await notifier.submit();
      final failed = container.read(deleteDeckControllerProvider('deck-1'));

      expect(failed.failure, isNotNull);
      expect(failed.isDone, isFalse);
      // Not submitting and not done, so the confirm button works again.
      expect(failed.canSubmit, isTrue);
    });
  });

  group('reset content type (UC-03 A3, BR-68)', () {
    test('resets and reports done', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(resetContentTypeControllerProvider('deck-1').notifier)
          .submit();

      expect(repository.resets, <String>['deck-1']);
    });

    test('a non-empty deck is refused by the repository, not by the UI', () async {
      // The tree can change between the dialog opening and the confirm landing,
      // so the repository is the boundary that decides. A conflict arriving here
      // is the system working, not a crash.
      final container = containerWith(
        FakeDeckRepository(
          writeFailure: const ConflictFailure(message: 'still has cards'),
        ),
      );

      await container
          .read(resetContentTypeControllerProvider('deck-1').notifier)
          .submit();

      expect(
        container.read(resetContentTypeControllerProvider('deck-1')).failure,
        isA<ConflictFailure>(),
      );
    });
  });

  group('move (UC-09)', () {
    test('submits the chosen target', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(moveDeckControllerProvider('deck-1').notifier)
          .submit(targetParentDeckId: 'target-1');

      expect(repository.moves.single.deckId, 'deck-1');
      expect(repository.moves.single.target, 'target-1');
    });

    test(
      'an illegal move refused by the repository surfaces as a conflict',
      () async {
        // The picker disables what it can already tell is illegal, but a stale
        // picker must never widen what the database accepts — so the refusal has
        // to be renderable.
        final container = containerWith(
          FakeDeckRepository(
            writeFailure: const ConflictFailure(message: 'different mode'),
          ),
        );

        await container
            .read(moveDeckControllerProvider('deck-1').notifier)
            .submit(targetParentDeckId: 'target-1');

        final state = container.read(moveDeckControllerProvider('deck-1'));
        expect(state.failure, isA<ConflictFailure>());
        expect(state.isDone, isFalse);
      },
    );

    test('double tap on two targets sends one move', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        moveDeckControllerProvider('deck-1').notifier,
      );

      await Future.wait<void>(<Future<void>>[
        notifier.submit(targetParentDeckId: 'a'),
        notifier.submit(targetParentDeckId: 'b'),
      ]);

      expect(repository.moves, hasLength(1));
    });
  });

  group('mutation independence', () {
    test('a failed delete leaves rename untouched', () async {
      // CLAUDE.md names one shared `isLoading` as a bug. This is the shape it
      // would break in: two operations on the same deck, one failed.
      final container = containerWith(
        FakeDeckRepository(writeFailure: const DatabaseFailure(message: 'x')),
      );

      await container
          .read(deleteDeckControllerProvider('deck-1').notifier)
          .submit();

      expect(
        container.read(deleteDeckControllerProvider('deck-1')).failure,
        isNotNull,
      );
      expect(
        container.read(renameDeckControllerProvider('deck-1')),
        const DeckSubmitState(),
      );
    });
  });
}
