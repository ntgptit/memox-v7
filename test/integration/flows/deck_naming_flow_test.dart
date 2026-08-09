import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

import '../../features/deck/data/support/deck_repository_harness.dart';

/// `HOST-FLOW` for BR-02 — the last rule in the catalog that no host test
/// mentioned. Scenario: IT-DECK-002.
///
/// **A `MAY` is worth a test precisely because it looks like an oversight.**
/// BR-02 says deck names may repeat, and every instinct of a person adding a
/// unique index says otherwise — a name is what the user reads, so surely two
/// decks called "Korean" is a mistake to prevent. It is not: the same name
/// under two different roots is the ordinary way a tree gets organised, and a
/// uniqueness constraint added "for safety" would refuse a shape the product
/// deliberately allows.
///
/// Nothing here would fail loudly. A unique index would simply start rejecting
/// a legal action, and the report would arrive as "I cannot create my deck",
/// weeks later, from somebody who had no reason to suspect the schema.
void main() {
  final h = installDeckRepositoryHarness();

  test(
    'IT-DECK-002 · two root decks may carry the same name (BR-02)',
    () async {
      final first = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Korean').name!,
        schedulerType: SchedulerType.eightBox,
      );
      final second = await h.deckRepository.createRootDeck(
        name: DeckName.parse('Korean').name!,
        schedulerType: SchedulerType.sm2,
      );

      expect(first.id, isNot(second.id));
      expect(first.name, second.name);
      expect(
        second.schedulerType,
        SchedulerType.sm2,
        reason:
            'and they are genuinely two decks — the second keeps its own '
            'scheduler, so this is not the first one being returned again',
      );
    },
  );

  test('a sub-deck may repeat its parent name, and its sibling name', () async {
    // The case the tree makes ordinary: `Korean > Vocabulary` and
    // `Japanese > Vocabulary` are the shape a learner actually builds.
    final root = await h.deckRepository.createRootDeck(
      name: DeckName.parse('Korean').name!,
      schedulerType: SchedulerType.eightBox,
    );

    final a = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Korean').name!,
      parentDeckId: root.id,
    );
    final b = await h.deckRepository.createSubDeck(
      name: DeckName.parse('Korean').name!,
      parentDeckId: root.id,
    );

    expect(a.id, isNot(b.id));
    expect(<String>[root.name, a.name, b.name], everyElement('Korean'));
  });
}
