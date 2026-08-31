import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_view_controller.dart';
import 'package:memox/features/deck/presentation/states/deck_list_view_state.dart';

import 'support/fake_deck_repository.dart';

/// The root list's filter and sort — a view of one snapshot, not a second query.
///
/// `applyDeckListView` is pure, so this needs no container, no widget and no
/// fake: a list goes in and a list comes out. That is the whole argument for
/// putting the transform in a function rather than a method on the notifier.
void main() {
  DeckSummary deck(
    String name, {
    required int due,
    required DateTime createdAt,
  }) => fakeSummary(
    id: name,
    name: name,
    totalCardCount: 100,
    dueCardCount: due,
    createdAt: createdAt,
  );

  final oldest = DateTime.utc(2026);
  final middle = DateTime.utc(2026, 6);
  final newest = DateTime.utc(2026, 12);

  List<DeckSummary> sample() => <DeckSummary>[
    deck('banana', due: 3, createdAt: oldest),
    deck('Apple', due: 0, createdAt: newest),
    deck('cherry', due: 7, createdAt: middle),
  ];

  List<String> namesOf(List<DeckSummary> decks) =>
      decks.map((DeckSummary summary) => summary.deck.name).toList();

  group('filter', () {
    test('all keeps every deck', () {
      expect(
        applyDeckListView(
          sample(),
          filter: DeckListFilter.all,
          sort: DeckListSort.dateAdded,
        ),
        hasLength(3),
      );
    });

    test('due keeps only decks with cards due', () {
      final visible = applyDeckListView(
        sample(),
        filter: DeckListFilter.due,
        sort: DeckListSort.name,
      );

      expect(namesOf(visible), <String>['banana', 'cherry']);
    });

    test('due can empty the list, which is a state and not an error', () {
      // BR-29: nothing due is normal. The screen renders its own empty state for
      // this, and the transform's job is only to report it honestly.
      final visible = applyDeckListView(
        <DeckSummary>[deck('Apple', due: 0, createdAt: oldest)],
        filter: DeckListFilter.due,
        sort: DeckListSort.dateAdded,
      );

      expect(visible, isEmpty);
    });
  });

  group('sort', () {
    test('manual retains the persisted repository order', () {
      expect(
        namesOf(
          applyDeckListView(
            sample(),
            filter: DeckListFilter.all,
            sort: DeckListSort.manual,
          ),
        ),
        <String>['banana', 'Apple', 'cherry'],
      );
    });

    test('recent is newest first', () {
      final visible = applyDeckListView(
        sample(),
        filter: DeckListFilter.all,
        sort: DeckListSort.dateAdded,
      );

      expect(namesOf(visible), <String>['Apple', 'cherry', 'banana']);
    });

    test('name ignores case', () {
      // `Apple` before `banana` only if the comparison is case-insensitive —
      // ASCII order would put every capitalised name in its own block ahead of
      // the lowercase ones, which reads as a broken sort rather than a choice.
      final visible = applyDeckListView(
        sample(),
        filter: DeckListFilter.all,
        sort: DeckListSort.name,
      );

      expect(namesOf(visible), <String>['Apple', 'banana', 'cherry']);
    });

    test('ties keep the order the repository gave them', () {
      // Two decks with one name is legal — nothing makes a deck name unique. If
      // the tie broke arbitrarily they would swap places on unrelated rebuilds,
      // which is a list that moves under the user's finger.
      final duplicates = <DeckSummary>[
        deck('same', due: 1, createdAt: newest),
        deck('same', due: 2, createdAt: oldest),
      ];

      final visible = applyDeckListView(
        duplicates,
        filter: DeckListFilter.all,
        sort: DeckListSort.name,
      );

      expect(visible.map((DeckSummary summary) => summary.dueCardCount), <int>[
        1,
        2,
      ]);
    });
  });

  group('the snapshot is not mutated', () {
    test('sorting returns a new list and leaves the input alone', () {
      // The snapshot belongs to the repository's stream. Sorting it in place
      // would reorder the value every other listener is holding.
      final original = sample();
      final before = namesOf(original);

      applyDeckListView(
        original,
        filter: DeckListFilter.all,
        sort: DeckListSort.name,
      );

      expect(namesOf(original), before);
    });
  });

  group('the choices are separate providers', () {
    test('each starts on the view the repository already returns', () {
      // `recent` is the repository's own order and `all` is its whole result, so
      // the first frame after the toolbar existed looked exactly like the last
      // frame before it. A default that changed what was on screen would have
      // been a silent content change dressed as a redesign.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(deckListFilterChoiceProvider), DeckListFilter.all);
      expect(container.read(deckListSortChoiceProvider), DeckListSort.manual);
    });

    test('changing one leaves the other alone', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.listen(deckListFilterChoiceProvider, (_, _) {});
      container.listen(deckListSortChoiceProvider, (_, _) {});

      container
          .read(deckListFilterChoiceProvider.notifier)
          .select(DeckListFilter.due);

      expect(container.read(deckListFilterChoiceProvider), DeckListFilter.due);
      expect(container.read(deckListSortChoiceProvider), DeckListSort.manual);
    });
  });
}
