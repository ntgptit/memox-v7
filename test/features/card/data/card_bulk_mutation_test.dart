import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// Bulk mutation and Select all against real SQLite (BR-166, BR-167).
///
/// Split from `card_move_repository_test.dart` at the file-size guard; that
/// file owns the move rules, this one owns delete, flag, tag and the Select
/// all read. All of them are boundary behaviour a fake cannot show: a batch is
/// all-or-nothing, and Select all runs through the same predicate as the list.
void main() {
  final h = installDeckRepositoryHarness();

  /// A card in [deckId] with a distinct front, so assertions can name it.
  Future<CardEntity> card(String deckId, String front) =>
      h.cardRepository.createCard(
        deckId: deckId,
        front: cardText(front),
        back: cardText('back', side: CardSide.back),
      );

  /// A second card-capable deck beside the tree's leaf, in the same root.
  Future<String> siblingDeck({String name = 'Target'}) async {
    final deck = await h.deckRepository.createSubDeck(
      name: DeckName.parse(name).name!,
      parentDeckId: (await h.deckRepository.watchAllDecks().first)
          .firstWhere((d) => d.contentType.name == 'deck' && !d.isRoot)
          .id,
    );

    return deck.id;
  }

  group('deleteCards (BR-166)', () {
    test('deleting the last cards unsets the deck', () async {
      final tree = await h.seedTree();
      final first = await card(tree.leaf.id, 'one');
      final second = await card(tree.leaf.id, 'two');

      await h.cardRepository.deleteCards(<String>[first.id, second.id]);

      // Two tombstones, no visible cards, and the deck unlocked (BR-186).
      // Nothing is gone: every study state is still there for a restore to
      // bring back (BR-185).
      expect(await h.activeCardCount(tree.leaf.id), 0);
      expect(await h.countAll('cards'), 2);
      expect(await h.countAll('card_study_states'), 2);
      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
      // **One batch per card, not one for the pair** (BR-182): each is
      // separately restorable, so each is its own row in Trash.
      final firstBatch = await h.deleteBatchOfCard(first.id);
      final secondBatch = await h.deleteBatchOfCard(second.id);
      expect(firstBatch, isNotNull);
      expect(secondBatch, isNotNull);
      expect(firstBatch, isNot(secondBatch));
    });

    test('deleting some of them keeps the type', () async {
      final tree = await h.seedTree();
      final first = await card(tree.leaf.id, 'one');
      await card(tree.leaf.id, 'two');

      await h.cardRepository.deleteCards(<String>[first.id]);

      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });

    test('a missing id refuses the batch and deletes nothing', () async {
      final tree = await h.seedTree();
      final present = await card(tree.leaf.id, 'one');

      await expectLater(
        h.cardRepository.deleteCards(<String>[present.id, 'ghost']),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(await h.countAll('cards'), 1);
    });
  });

  group('setCardsFlag (BR-166)', () {
    test('is explicit and idempotent in both directions', () async {
      final tree = await h.seedTree();
      final one = await card(tree.leaf.id, 'one');
      final two = await card(tree.leaf.id, 'two');
      await h.cardRepository.setCardFlag(cardId: two.id, isFlagged: true);

      // A mixed selection, set — not toggled: both end up flagged.
      await h.cardRepository.setCardsFlag(
        cardIds: <String>[one.id, two.id],
        isFlagged: true,
      );
      expect((await h.cardRepository.getCard(one.id)).isFlagged, isTrue);
      expect((await h.cardRepository.getCard(two.id)).isFlagged, isTrue);

      // Again, same value: nothing moves.
      await h.cardRepository.setCardsFlag(
        cardIds: <String>[one.id, two.id],
        isFlagged: true,
      );
      expect((await h.cardRepository.getCard(one.id)).isFlagged, isTrue);

      await h.cardRepository.setCardsFlag(
        cardIds: <String>[one.id, two.id],
        isFlagged: false,
      );
      expect((await h.cardRepository.getCard(one.id)).isFlagged, isFalse);
      expect((await h.cardRepository.getCard(two.id)).isFlagged, isFalse);
    });
  });

  group('addTagToCards (BR-93, BR-94, BR-166)', () {
    test('reuses the folded name and is idempotent per card', () async {
      final tree = await h.seedTree();
      final one = await card(tree.leaf.id, 'one');
      final two = await card(tree.leaf.id, 'two');
      await h.cardRepository.addCardTag(
        cardId: one.id,
        name: TagName.parse('Greeting').name!,
      );

      await h.cardRepository.addTagToCards(
        cardIds: <String>[one.id, two.id],
        name: TagName.parse('greeting').name!,
      );

      // One tag row, two links: the folded name owns the tag (BR-93).
      expect(await h.countAll('tags'), 1);
      expect(await h.countAll('card_tags'), 2);
    });

    test('one card at the cap refuses the whole batch', () async {
      final tree = await h.seedTree();
      final full = await card(tree.leaf.id, 'full');
      final empty = await card(tree.leaf.id, 'empty');
      for (var i = 0; i < 10; i++) {
        await h.cardRepository.addCardTag(
          cardId: full.id,
          name: TagName.parse('tag$i').name!,
        );
      }

      await expectLater(
        h.cardRepository.addTagToCards(
          cardIds: <String>[empty.id, full.id],
          name: TagName.parse('eleventh').name!,
        ),
        throwsA(isA<ValidationFailure>()),
      );

      // The innocent card gained nothing: all or nothing (BR-166).
      expect(await h.cardRepository.watchCardTags(empty.id).first, isEmpty);
    });
  });

  group('readCardIdsMatching (BR-167)', () {
    test('answers through the list predicate, not the window', () async {
      final tree = await h.seedTree();
      final flagged = await card(tree.leaf.id, 'flagged');
      await card(tree.leaf.id, 'plain');
      await h.cardRepository.setCardFlag(cardId: flagged.id, isFlagged: true);

      final all = await h.cardRepository.readCardIdsMatching(tree.leaf.id);
      final onlyFlagged = await h.cardRepository.readCardIdsMatching(
        tree.leaf.id,
        filter: CardListFilter.flagged,
      );

      expect(all, hasLength(2));
      expect(onlyFlagged, <String>[flagged.id]);
    });

    test('honours the search term the list is showing', () async {
      final tree = await h.seedTree();
      final match = await card(tree.leaf.id, 'riverbank');
      await card(tree.leaf.id, 'unrelated');

      final ids = await h.cardRepository.readCardIdsMatching(
        tree.leaf.id,
        searchTerm: 'river',
      );

      expect(ids, <String>[
        match.id,
      ], reason: 'the same folded search the list uses (S1)');
    });
  });

  group('watchMoveTargets (BR-165)', () {
    test('offers same-root card and unset decks, never root, deck or '
        'self', () async {
      final tree = await h.seedTree();
      await h.seedTree(prefix: 'X-');
      final sibling = await siblingDeck(name: 'Sibling');

      final targets = await h.cardRepository
          .watchMoveTargets(tree.leaf.id)
          .first;

      expect(targets.map((t) => t.deckId), <String>[sibling]);
    });

    test('an empty list is the honest answer for a lone leaf', () async {
      final tree = await h.seedTree();

      expect(
        await h.cardRepository.watchMoveTargets(tree.leaf.id).first,
        isEmpty,
      );
    });
  });
}
