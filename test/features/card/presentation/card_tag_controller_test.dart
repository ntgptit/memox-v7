import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/state/submit_outcome.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/presentation/controllers/card_tag_controller.dart';
import 'package:memox/features/card/presentation/states/card_tag_state.dart';

import 'support/fake_card_repository.dart';

/// The tag entry controller (BR-93, BR-94): what it forwards, what it refuses,
/// and how a repository refusal reaches the field.
void main() {
  ProviderContainer containerWith(FakeCardRepository repository) {
    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  test('a valid add reaches the repository and clears the field', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    final container = containerWith(repository);

    await container.read(cardTagEntryProvider('card-1').notifier).add('noun');

    expect(repository.tagAdds.single, (id: 'card-1', name: 'noun'));
    expect(
      container.read(cardTagEntryProvider('card-1')).outcome,
      SubmitOutcome.savedAndContinue,
      reason: 'the field stays open for the next tag',
    );
  });

  test('a blank tag is refused before the repository (BR-93)', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    final container = containerWith(repository);

    await container.read(cardTagEntryProvider('card-1').notifier).add('   ');

    expect(
      container.read(cardTagEntryProvider('card-1')).problem,
      TagValidationProblem.nameEmpty,
    );
    expect(repository.tagAdds, isEmpty);
  });

  test('the ten-tag cap surfaces as a field problem (BR-94)', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.nextTagFailure = const ValidationFailure(
      message: 'too many',
      problems: <TagValidationProblem>{TagValidationProblem.tooManyTags},
    );
    final container = containerWith(repository);

    await container
        .read(cardTagEntryProvider('card-1').notifier)
        .add('eleventh');

    expect(
      container.read(cardTagEntryProvider('card-1')).problem,
      TagValidationProblem.tooManyTags,
    );
  });

  test('remove forwards the ids', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    final container = containerWith(repository);

    await container
        .read(cardTagEntryProvider('card-1').notifier)
        .remove('tag-1');

    expect(repository.tagRemoves.single, (id: 'card-1', tagId: 'tag-1'));
  });
}
