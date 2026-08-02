import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/controllers/card_flag_controller.dart';

import 'support/fake_card_repository.dart';

/// The flag read and its command (BR-92): the stream seeds from the card, the
/// command writes, and the stream re-emits the written value.
void main() {
  ProviderContainer containerWith(FakeCardRepository repository) {
    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  test('cardFlag seeds from the card current flag', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1', isFlagged: true);
    final container = containerWith(repository);
    // Keep the autoDispose stream alive while its first value resolves.
    final sub = container.listen(cardFlagProvider('card-1'), (_, _) {});
    addTearDown(sub.close);

    final value = await container.read(cardFlagProvider('card-1').future);

    expect(value, isTrue);
  });

  test('SetCardFlag writes the target value and reports success', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    final container = containerWith(repository);
    // Keep the stream alive across the write.
    final sub = container.listen(cardFlagProvider('card-1'), (_, _) {});
    addTearDown(sub.close);

    await container
        .read(setCardFlagProvider('card-1').notifier)
        .submit(isFlagged: true);

    expect(repository.flagWrites.single, (id: 'card-1', isFlagged: true));
    expect(
      container.read(setCardFlagProvider('card-1')).outcome,
      SubmitOutcome.savedAndClose,
    );
  });

  test('a failed write surfaces on the command state', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.nextFlagFailure = const DatabaseFailure(message: 'locked');
    final container = containerWith(repository);

    await container
        .read(setCardFlagProvider('card-1').notifier)
        .submit(isFlagged: true);

    expect(
      container.read(setCardFlagProvider('card-1')).failure,
      isA<DatabaseFailure>(),
    );
  });
}
