import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/controllers/card_flag_controller.dart';

import 'support/fake_card_repository.dart';

/// The flag controller (BR-92): it seeds from the card, toggles optimistically,
/// and reverts a failed write so the mark never disagrees with the row.
void main() {
  ProviderContainer containerWith(FakeCardRepository repository) {
    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  test('it seeds from the card current flag', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1', isFlagged: true);
    final container = containerWith(repository);

    final value = await container.read(cardFlagProvider('card-1').future);

    expect(value, isTrue);
  });

  test('toggling flips the value and writes it', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    final container = containerWith(repository);
    await container.read(cardFlagProvider('card-1').future);

    await container.read(cardFlagProvider('card-1').notifier).toggle();

    expect(repository.flagWrites.single, (id: 'card-1', isFlagged: true));
    expect(container.read(cardFlagProvider('card-1')).value, isTrue);
  });

  test('a failed write reverts the optimistic value', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    repository.nextFlagFailure = const DatabaseFailure(message: 'locked');
    final container = containerWith(repository);
    await container.read(cardFlagProvider('card-1').future);

    await container.read(cardFlagProvider('card-1').notifier).toggle();

    expect(
      container.read(cardFlagProvider('card-1')).value,
      isFalse,
      reason: 'the mark must not show flagged when the write did not land',
    );
  });
}
