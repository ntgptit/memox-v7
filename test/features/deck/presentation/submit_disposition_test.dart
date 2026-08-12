import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/failures/deck_validation_failure.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/deck/presentation/states/deck_submit_state.dart';
import 'package:memox/features/deck/presentation/controllers/deck_write_controller.dart';

import 'support/fake_deck_repository.dart';

/// The success policy: *saved and close* versus *saved and add another*.
///
/// **Deck has no add-another form.** These tests exist because M4.11's card editor
/// does (`docs/wbs.md`: "*Add another* giữ editor mở và xoá form sau khi lưu"), and
/// cloning Deck's close-on-success pattern into it reproduces three bugs at once:
/// the editor closes when it should not; if it does not close, the widget's
/// `TextEditingController` still holds the record just saved; and `canSubmit` stays
/// false so the next entry cannot be submitted.
///
/// The state machine is what those bugs live in, so the state machine is what is
/// tested here. The widget half of the contract — clear the draft, clear the field
/// errors, return to idle, refocus the first field — is specified in
/// `assets/feature_blueprint.md` and belongs to the first form that actually needs
/// it. Testing it against a form that does not exist would be testing a mock of
/// the thing rather than the thing.
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

  group('the disposition to outcome mapping', () {
    test('is one-to-one and total', () {
      // A getter on the enum rather than a switch at each call site: the pairing
      // cannot then differ between two controllers.
      expect(SubmitDisposition.close.outcome, SubmitOutcome.savedAndClose);
      expect(
        SubmitDisposition.addAnother.outcome,
        SubmitOutcome.savedAndContinue,
      );
      // If a third disposition is ever added, the switch inside `outcome` fails
      // to compile rather than falling through to a default.
      expect(SubmitDisposition.values, hasLength(2));
    });
  });

  group('close is the default', () {
    test(
      'an omitted disposition closes, so existing callers are unchanged',
      () {
        final container = containerWith(FakeDeckRepository());

        final notifier = container.read(
          createRootDeckControllerProvider.notifier,
        );

        return notifier
            .submit(name: 'Japanese', schedulerType: SchedulerType.sm2)
            .then((_) {
              final state = container.read(createRootDeckControllerProvider);
              expect(state.outcome, SubmitOutcome.savedAndClose);
              expect(state.shouldClose, isTrue);
              expect(state.shouldClearDraft, isFalse);
            });
      },
    );

    test('the four non-repeating operations always close', () async {
      // Rename, delete and move have nothing to add another of, so they
      // take no disposition at all — the type makes the wrong call impossible
      // rather than merely unlikely.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(renameDeckControllerProvider('deck-1').notifier)
          .submit(name: 'Renamed');
      await container
          .read(deleteDeckControllerProvider('deck-2').notifier)
          .submit();
      await container
          .read(moveDeckControllerProvider('deck-4').notifier)
          .submit(targetParentDeckId: 'target');

      for (final state in <DeckSubmitState>[
        container.read(renameDeckControllerProvider('deck-1')),
        container.read(deleteDeckControllerProvider('deck-2')),
        container.read(moveDeckControllerProvider('deck-4')),
      ]) {
        expect(state.outcome, SubmitOutcome.savedAndClose);
      }
    });
  });

  group('addAnother', () {
    test('reports savedAndContinue, not savedAndClose', () async {
      final container = containerWith(FakeDeckRepository());

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(
            name: 'Japanese',
            schedulerType: SchedulerType.sm2,
            disposition: SubmitDisposition.addAnother,
          );

      final state = container.read(createRootDeckControllerProvider);
      expect(state.outcome, SubmitOutcome.savedAndContinue);
      // The bug this exists to prevent: a widget that closes on "succeeded"
      // rather than on "should close" would dismiss an editor the user asked to
      // keep open.
      expect(state.shouldClose, isFalse);
      expect(state.shouldClearDraft, isTrue);
    });

    test('leaves the next submit possible without an explicit reset', () async {
      // `canSubmit` used to be `!isSubmitting && !isDone`, which latched shut on
      // any success. An add-another form would have accepted exactly one entry
      // and then silently ignored every tap.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      await notifier.submit(
        name: 'First',
        schedulerType: SchedulerType.sm2,
        disposition: SubmitDisposition.addAnother,
      );
      expect(
        container.read(createRootDeckControllerProvider).canSubmit,
        isTrue,
      );

      await notifier.submit(
        name: 'Second',
        schedulerType: SchedulerType.sm2,
        disposition: SubmitDisposition.addAnother,
      );

      expect(repository.createdRootDecks.map((deck) => deck.name), <String>[
        'First',
        'Second',
      ]);
    });

    test(
      'close still latches, so a closing form cannot double-submit',
      () async {
        final repository = FakeDeckRepository();
        final container = containerWith(repository);
        final notifier = container.read(
          createRootDeckControllerProvider.notifier,
        );

        await notifier.submit(name: 'First', schedulerType: SchedulerType.sm2);
        expect(
          container.read(createRootDeckControllerProvider).canSubmit,
          isFalse,
        );

        await notifier.submit(name: 'Second', schedulerType: SchedulerType.sm2);

        expect(repository.createdRootDecks, hasLength(1));
      },
    );

    test('the double-submit guard still holds within one entry', () async {
      // Repeating is allowed *sequentially*, not concurrently: two taps on one
      // entry must still write once.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      await Future.wait<void>(<Future<void>>[
        notifier.submit(
          name: 'Japanese',
          schedulerType: SchedulerType.sm2,
          disposition: SubmitDisposition.addAnother,
        ),
        notifier.submit(
          name: 'Japanese',
          schedulerType: SchedulerType.sm2,
          disposition: SubmitDisposition.addAnother,
        ),
      ]);

      expect(repository.createdRootDecks, hasLength(1));
    });

    test('a sub-deck creator takes the disposition too', () async {
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createSubDeckControllerProvider('parent-1').notifier)
          .submit(name: 'Hiragana', disposition: SubmitDisposition.addAnother);

      expect(
        container.read(createSubDeckControllerProvider('parent-1')).outcome,
        SubmitOutcome.savedAndContinue,
      );
    });
  });

  group('failure never looks like either success', () {
    test('a validation failure reports no outcome at all', () async {
      // The widget must not clear a draft the user has to fix.
      final repository = FakeDeckRepository();
      final container = containerWith(repository);

      await container
          .read(createRootDeckControllerProvider.notifier)
          .submit(
            name: '   ',
            schedulerType: SchedulerType.sm2,
            disposition: SubmitDisposition.addAnother,
          );

      final state = container.read(createRootDeckControllerProvider);
      expect(state.nameProblem, DeckValidationProblem.nameEmpty);
      expect(state.outcome, isNull);
      expect(state.shouldClearDraft, isFalse);
      expect(state.shouldClose, isFalse);
      expect(repository.createdRootDecks, isEmpty);
    });

    test(
      'a persistence failure reports no outcome, so the draft survives',
      () async {
        // The rule the blueprint states: clear only after the repository confirmed
        // the write. A draft cleared optimistically is a record the user typed and
        // lost.
        final container = containerWith(
          FakeDeckRepository(
            writeFailure: const DatabaseFailure(message: 'disk full'),
          ),
        );

        await container
            .read(createRootDeckControllerProvider.notifier)
            .submit(
              name: 'Japanese',
              schedulerType: SchedulerType.sm2,
              disposition: SubmitDisposition.addAnother,
            );

        final state = container.read(createRootDeckControllerProvider);
        expect(state.failure, isA<DatabaseFailure>());
        expect(state.outcome, isNull);
        expect(state.shouldClearDraft, isFalse);
        // And it can be retried without a reset, because nothing latched.
        expect(state.canSubmit, isTrue);
      },
    );
  });

  group('reset', () {
    test('returns an add-another form to idle', () async {
      // What the widget calls after it has cleared its own draft.
      final container = containerWith(FakeDeckRepository());
      final notifier = container.read(
        createRootDeckControllerProvider.notifier,
      );

      await notifier.submit(
        name: 'Japanese',
        schedulerType: SchedulerType.sm2,
        disposition: SubmitDisposition.addAnother,
      );
      notifier.reset();

      expect(
        container.read(createRootDeckControllerProvider),
        const DeckSubmitState(),
      );
    });
  });
}
