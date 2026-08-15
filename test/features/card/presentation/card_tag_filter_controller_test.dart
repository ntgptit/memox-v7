import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/presentation/controllers/card_list_tag_filter_controller.dart';
import 'package:memox/features/card/presentation/controllers/card_list_window_controller.dart';
import 'package:memox/features/card/presentation/controllers/card_selection_controller.dart';

import 'support/fake_card_repository.dart';

/// The tag filter as an input-state notifier (BR-231, BR-232).
///
/// These are the two consequences a widget test cannot see directly: a window
/// grown over one result set does not survive into another, and a selection
/// built under one predicate is not carried into a different one.
void main() {
  const deckId = 'deck-1';

  ProviderContainer containerWith(FakeCardRepository repository) {
    final container = ProviderContainer(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  test('starts with no tag predicate at all (BR-231)', () {
    final container = containerWith(FakeCardRepository());

    expect(container.read(cardListTagFilterProvider(deckId)), TagFilter.none);
    expect(container.read(cardListTagFilterProvider(deckId)).isActive, isFalse);
  });

  test('applying a selection resets the window (BR-232)', () {
    final container = containerWith(FakeCardRepository());
    // Keep the window alive, then grow it — a window opened over 142 cards
    // describes nothing over the 12 that carry a tag.
    container.listen(cardListWindowProvider(deckId), (_, _) {});
    container.read(cardListWindowProvider(deckId).notifier).grow();
    final grown = container.read(cardListWindowProvider(deckId));
    expect(grown, greaterThan(kCardWindowSize));

    container
        .read(cardListTagFilterProvider(deckId).notifier)
        .apply(TagFilter.of(const <String>['t1']));

    expect(container.read(cardListWindowProvider(deckId)), kCardWindowSize);
  });

  test('applying the same selection twice does not reset the window', () {
    final container = containerWith(FakeCardRepository());
    final tags = TagFilter.of(const <String>['t1']);
    container.read(cardListTagFilterProvider(deckId).notifier).apply(tags);
    container.listen(cardListWindowProvider(deckId), (_, _) {});
    container.read(cardListWindowProvider(deckId).notifier).grow();
    final grown = container.read(cardListWindowProvider(deckId));

    // Re-applying an equal value is not a change; resetting on it would make
    // reopening the sheet and pressing Apply lose the reader's place.
    container
        .read(cardListTagFilterProvider(deckId).notifier)
        .apply(TagFilter.of(const <String>['t1']));

    expect(container.read(cardListWindowProvider(deckId)), grown);
  });

  test('a change to the tag filter clears the selection (BR-232)', () {
    final container = containerWith(FakeCardRepository());
    container.listen(cardSelectionProvider(deckId), (_, _) {});
    container.read(cardSelectionProvider(deckId).notifier).beginWith('c1');
    expect(container.read(cardSelectionProvider(deckId)).isSelecting, isTrue);

    container
        .read(cardListTagFilterProvider(deckId).notifier)
        .apply(TagFilter.of(const <String>['t1']));

    // A selection made under one predicate and acted on under another is a
    // mutation the user did not agree to.
    expect(container.read(cardSelectionProvider(deckId)).isSelecting, isFalse);
  });

  test('select all reads the ids under the live tag filter (BR-167)', () async {
    final repository = FakeCardRepository()..idsMatching = <String>['c1', 'c2'];
    final container = containerWith(repository);
    final tags = TagFilter.of(const <String>['t1', 't2']);
    container.read(cardListTagFilterProvider(deckId).notifier).apply(tags);

    await container
        .read(cardSelectionProvider(deckId).notifier)
        .includeAllMatching();

    expect(repository.idsMatchingCalls.single.tags, tags);
  });

  group('the draft is separate from what is applied (M4.14 T5)', () {
    test('editing the draft does not touch the applied filter', () {
      final container = containerWith(FakeCardRepository());

      container
          .read(cardListTagFilterDraftProvider(deckId).notifier)
          .select(TagFilter.of(const <String>['t1']));

      expect(container.read(cardListTagFilterProvider(deckId)), TagFilter.none);
    });

    test('two decks do not share a filter', () {
      final container = containerWith(FakeCardRepository());

      container
          .read(cardListTagFilterProvider(deckId).notifier)
          .apply(TagFilter.of(const <String>['t1']));

      expect(
        container.read(cardListTagFilterProvider('deck-2')),
        TagFilter.none,
      );
    });
  });
}
