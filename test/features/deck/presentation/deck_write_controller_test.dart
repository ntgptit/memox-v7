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

/// The two creation controllers (UC-02, UC-08).
///
/// The behaviour under test is the state machine, not the persistence: what the
/// writes actually do to the tree is asserted against real SQLite in
/// `test/features/deck/data/`. Here the question is whether a double tap sends
/// one write, whether a failure keeps the user's input, and whether an inline
/// error points at a field instead of arriving as a banner.
///
/// Rename, delete, reset and move live in `deck_edit_controller_test.dart`.
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
      expect(
        container.read(createRootDeckControllerProvider).shouldClose,
        isTrue,
      );
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
      expect(state.shouldClose, isFalse);
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
        DeckFormProblem.nameEmpty,
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
        DeckFormProblem.nameTooLong,
      );
      expect(repository.createdRootDecks, isEmpty);
    });

    test('both fields can be wrong at once', () async {
      final container = containerWith(FakeDeckRepository());

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(name: '', schedulerType: null);

      final state = container.read(createRootDeckControllerProvider);
      expect(state.nameProblem, DeckFormProblem.nameEmpty);
      expect(state.isSchedulerMissing, isTrue);
      // Both, in one set. The accessors above are Deck's reading of it; this is
      // what is stored.
      expect(state.problems, <DeckFormProblem>{
        DeckFormProblem.nameEmpty,
        DeckFormProblem.schedulerMissing,
      });
    });

    test('a missing scheduler marks no error under the name field', () async {
      // The grouping the accessors exist for. `nameProblem` filters the set down
      // to the values that belong to the name input, so a form that failed only
      // on the scheduler must leave the name input clean — a plain
      // "are there any problems" check would put a red border under a name the
      // user typed correctly.
      final container = containerWith(FakeDeckRepository());

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(name: 'Japanese', schedulerType: null);

      final state = container.read(createRootDeckControllerProvider);
      expect(state.isSchedulerMissing, isTrue);
      expect(state.nameProblem, isNull);
      expect(state.problems, <DeckFormProblem>{
        DeckFormProblem.schedulerMissing,
      });
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
      expect(state.shouldClose, isFalse);
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
}
