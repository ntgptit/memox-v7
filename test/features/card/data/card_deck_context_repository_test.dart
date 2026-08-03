import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// The card-side read of deck context on a real SQLite database (W1): the header
/// name and breadcrumb, and the content-type answer the router's auto-forward
/// reads — all through the shared database, never the deck feature's Dart (AD-13).
void main() {
  final h = installDeckRepositoryHarness();

  test(
    'the header reads the deck name and its ancestor path, root first',
    () async {
      final tree = await h.seedTree(); // Root → Branch → Leaf

      final context = await h.cardRepository
          .watchDeckContext(tree.leaf.id)
          .first;

      expect(context.deckName, 'Leaf');
      // Root first, and the deck itself is excluded — it is the name above.
      expect(context.ancestors.map((a) => a.name), <String>['Root', 'Branch']);
      expect(context.ancestors.map((a) => a.id), <String>[
        tree.root.id,
        tree.branch.id,
      ]);
    },
  );

  test('a root deck has a name and no ancestors', () async {
    final tree = await h.seedTree();

    final context = await h.cardRepository.watchDeckContext(tree.root.id).first;

    expect(context.deckName, 'Root');
    expect(context.ancestors, isEmpty);
  });

  test('a rename re-emits the header live (AD-13)', () async {
    final tree = await h.seedTree();
    final stream = h.cardRepository.watchDeckContext(tree.leaf.id);

    expect((await stream.first).deckName, 'Leaf');
    // Through the deck repository so drift's update tracking fires — the header
    // watches the `decks` table, so the title and the breadcrumb move together.
    await h.deckRepository.renameDeck(
      deckId: tree.leaf.id,
      name: DeckName.parse('Renamed').name!,
    );

    expect(
      await stream.map((c) => c.deckName).firstWhere((n) => n == 'Renamed'),
      'Renamed',
    );
  });

  test(
    'readDeckHoldsCards is true only once the deck holds cards (BR-63)',
    () async {
      final tree = await h.seedTree();

      // The leaf starts `unset` — nothing to forward into yet.
      expect(await h.cardRepository.readDeckHoldsCards(tree.leaf.id), isFalse);

      await h.cardRepository.createCard(
        deckId: tree.leaf.id,
        front: cardText('front'),
        back: cardText('back', side: CardSide.back),
      );

      // The first card locked it to `card` (BR-62).
      expect(await h.cardRepository.readDeckHoldsCards(tree.leaf.id), isTrue);
      // A root holds decks, never cards.
      expect(await h.cardRepository.readDeckHoldsCards(tree.root.id), isFalse);
      // A missing deck: nothing to forward into.
      expect(await h.cardRepository.readDeckHoldsCards('gone'), isFalse);
    },
  );
}
