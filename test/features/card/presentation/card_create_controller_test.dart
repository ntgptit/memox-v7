import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/presentation/controllers/card_create_controller.dart';
import 'package:memox/features/card/presentation/states/card_submit_state.dart';

import 'support/fake_card_repository.dart';

/// The create controller's state machine (UC-04, W4).
///
/// The same three questions Deck's write controllers answer: does it refuse a
/// second submit while the first is in flight, keep the user's input on failure,
/// and turn a validation failure into per-field problems rather than re-deriving
/// them.
void main() {
  ProviderContainer containerWith(FakeCardRepository repository) {
    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  test(
    'a valid submit reaches the repository and reports savedAndClose',
    () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);

      await container
          .read(cardCreateProvider('deck-1').notifier)
          .submit(rawFront: 'ephemeral', rawBack: 'lasting a short time');

      expect(repository.creates.single.front, 'ephemeral');
      expect(
        container.read(cardCreateProvider('deck-1')).outcome,
        SubmitOutcome.savedAndClose,
      );
    },
  );

  test(
    'save-and-add-another reports savedAndContinue and stays submittable',
    () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);
      final controller = container.read(cardCreateProvider('deck-1').notifier);

      await controller.submit(
        rawFront: 'one',
        rawBack: 'first',
        disposition: SubmitDisposition.addAnother,
      );

      final state = container.read(cardCreateProvider('deck-1'));
      expect(state.outcome, SubmitOutcome.savedAndContinue);
      expect(
        state.canSubmit,
        isTrue,
        reason: 'the emptied form must accept the next card',
      );
    },
  );

  test('a double submit creates one card, not two', () async {
    // The guard a just-created card at the top of the list depends on: two taps
    // on Save must not write two rows.
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.createGate = Completer<void>();
    final container = containerWith(repository);
    final controller = container.read(cardCreateProvider('deck-1').notifier);

    final first = controller.submit(rawFront: 'a', rawBack: 'b');
    // Second tap while the first is still held open by the gate.
    final second = controller.submit(rawFront: 'a', rawBack: 'b');
    repository.createGate!.complete();
    await Future.wait(<Future<void>>[first, second]);

    expect(repository.creates, hasLength(1));
  });

  group('validation surfaces as per-field problems (BR-07, BR-08)', () {
    test(
      'an empty front is refused before the repository is touched',
      () async {
        final repository = FakeCardRepository();
        addTearDown(repository.dispose);
        final container = containerWith(repository);

        await container
            .read(cardCreateProvider('deck-1').notifier)
            .submit(rawFront: '   ', rawBack: 'has a back');

        final state = container.read(cardCreateProvider('deck-1'));
        expect(state.frontProblem, CardValidationProblem.frontEmpty);
        expect(state.backProblem, isNull);
        expect(
          repository.creates,
          isEmpty,
          reason: 'a refused form never reaches the write',
        );
      },
    );

    test('both blank report both problems in one attempt', () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);

      await container
          .read(cardCreateProvider('deck-1').notifier)
          .submit(rawFront: '', rawBack: '');

      final state = container.read(cardCreateProvider('deck-1'));
      expect(state.frontProblem, CardValidationProblem.frontEmpty);
      expect(state.backProblem, CardValidationProblem.backEmpty);
    });

    test('the front takes its own 60 limit, not the back 240', () async {
      // The regression the split limits guard: 100 characters is fine as a back
      // and refused as a front.
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);

      await container
          .read(cardCreateProvider('deck-1').notifier)
          .submit(rawFront: 'x' * 100, rawBack: 'ok');

      expect(
        container.read(cardCreateProvider('deck-1')).frontProblem,
        CardValidationProblem.frontTooLong,
      );
    });
  });

  test('a persistence failure keeps the failure and the form', () async {
    // UC-04 E3: the write failed, the content is the user's, and it stays.
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.nextCreateFailure = const DatabaseFailure(message: 'disk full');
    final container = containerWith(repository);

    await container
        .read(cardCreateProvider('deck-1').notifier)
        .submit(rawFront: 'kept', rawBack: 'also kept');

    final state = container.read(cardCreateProvider('deck-1'));
    expect(state.failure, isA<DatabaseFailure>());
    expect(state.hasProblem, isFalse, reason: 'no field is at fault');
    expect(state.canSubmit, isTrue, reason: 'the user can retry');
  });
}
