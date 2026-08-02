import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/presentation/controllers/card_write_controller.dart';
import 'package:memox/features/card/presentation/states/card_submit_state.dart';

import 'support/fake_card_repository.dart';

/// The edit and delete controllers' state machines (UC-04 A1, A5).
///
/// The same questions the create controller answers, plus the two that are new
/// here: an edit reports `savedAndClose` (it has no add-another), and a delete
/// surfaces a failure without inventing a field problem.
void main() {
  ProviderContainer containerWith(FakeCardRepository repository) {
    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  group('CardEdit', () {
    test('a valid edit reaches the repository and closes', () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);

      await container
          .read(cardEditProvider('card-1').notifier)
          .submit(rawFront: 'updated', rawBack: 'new back');

      expect(repository.updates.single.id, 'card-1');
      expect(repository.updates.single.front, 'updated');
      expect(
        container.read(cardEditProvider('card-1')).outcome,
        SubmitOutcome.savedAndClose,
      );
    });

    test('an empty front is refused before the write', () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);

      await container
          .read(cardEditProvider('card-1').notifier)
          .submit(rawFront: '   ', rawBack: 'has a back');

      final state = container.read(cardEditProvider('card-1'));
      expect(state.frontProblem, CardValidationProblem.frontEmpty);
      expect(
        repository.updates,
        isEmpty,
        reason: 'a refused form never reaches the write',
      );
    });

    test(
      'a persistence failure keeps the failure and stays submittable',
      () async {
        final repository = FakeCardRepository();
        addTearDown(repository.dispose);
        repository.nextCreateFailure = const DatabaseFailure(
          message: 'disk full',
        );
        final container = containerWith(repository);

        await container
            .read(cardEditProvider('card-1').notifier)
            .submit(rawFront: 'kept', rawBack: 'also kept');

        final state = container.read(cardEditProvider('card-1'));
        expect(state.failure, isA<DatabaseFailure>());
        expect(state.hasProblem, isFalse);
        expect(state.canSubmit, isTrue);
      },
    );
  });

  group('CardDelete', () {
    test('a delete reaches the repository and closes', () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);

      await container.read(cardDeleteProvider('card-1').notifier).submit();

      expect(repository.deletes.single, 'card-1');
      expect(
        container.read(cardDeleteProvider('card-1')).outcome,
        SubmitOutcome.savedAndClose,
      );
    });

    test('a delete failure surfaces without a field problem', () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      repository.nextCreateFailure = const DatabaseFailure(message: 'locked');
      final container = containerWith(repository);

      await container.read(cardDeleteProvider('card-1').notifier).submit();

      final state = container.read(cardDeleteProvider('card-1'));
      expect(state.failure, isA<DatabaseFailure>());
      expect(state.hasProblem, isFalse, reason: 'delete has no field to blame');
    });

    test('a double submit deletes once', () async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      final container = containerWith(repository);
      final controller = container.read(cardDeleteProvider('card-1').notifier);

      await Future.wait(<Future<void>>[
        controller.submit(),
        controller.submit(),
      ]);

      expect(repository.deletes, hasLength(1));
    });
  });
}
