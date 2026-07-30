import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/presentation/states/deck_submit_state.dart';
import 'package:memox/features/deck/presentation/controllers/deck_write_controller.dart';

import 'support/fake_deck_repository.dart';

/// The controllers that change an existing deck: rename, delete, reset content
/// type and move (UC-03, UC-09).
///
/// Split from `deck_write_controller_test.dart`, which keeps the two creation
/// controllers. Same question in both: does the state machine refuse a second
/// submit, keep the user's input on failure, and stay independent of its
/// siblings.
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
        DeckFormProblem.nameEmpty,
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
        container.read(deleteDeckControllerProvider('deck-1')).shouldClose,
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
      expect(failed.shouldClose, isFalse);
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
        expect(state.shouldClose, isFalse);
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
