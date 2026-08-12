import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_conflict_failure.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// Bulk card management against real SQLite (BR-165, BR-166, BR-167).
///
/// The rules under test are the ones that only exist at the boundary: a move
/// crosses two decks and two content types in one transaction, a batch is
/// all-or-nothing, and Select all reads through the same predicate the list
/// does. None of that is observable from a unit test with a fake.
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

  Future<String?> deckOf(String cardId) async {
    final read = await h.cardRepository.getCard(cardId);

    return read.deckId;
  }

  group('moveCards (BR-165)', () {
    test('moves a card between sub-decks of one root', () async {
      final tree = await h.seedTree();
      final moved = await card(tree.leaf.id, 'moved');
      final target = await siblingDeck();

      await h.cardRepository.moveCards(
        cardIds: <String>[moved.id],
        targetDeckId: target,
      );

      expect(await deckOf(moved.id), target);
    });

    test('keeps the card whole: id, faces, flag, tag, state and '
        'history', () async {
      // The point of a move is that nothing else about the card changes. A
      // re-create-and-delete implementation would pass "the card is in the
      // target" and fail every assertion below.
      final tree = await h.seedTree();
      final original = await card(tree.leaf.id, 'intact');
      await h.cardRepository.setCardFlag(cardId: original.id, isFlagged: true);
      await h.cardRepository.addCardTag(
        cardId: original.id,
        name: TagName.parse('greeting').name!,
      );
      final stateBefore = (await h.rawStates(
        original.id,
      )).map((row) => row.data).toList();
      final target = await siblingDeck();

      await h.cardRepository.moveCards(
        cardIds: <String>[original.id],
        targetDeckId: target,
      );

      final after = await h.cardRepository.getCard(original.id);
      expect(after.id, original.id);
      expect(after.front, original.front);
      expect(after.back, original.back);
      expect(after.isFlagged, isTrue);
      expect(after.createdAt, original.createdAt);
      expect(
        (await h.cardRepository.watchCardTags(original.id).first).single.name,
        'greeting',
      );
      expect(
        (await h.rawStates(original.id)).map((row) => row.data).toList(),
        stateBefore,
        reason: 'a move touches no scheduling column (BR-73, BR-74)',
      );
    });

    test('the last card out unsets the source and types the target', () async {
      final tree = await h.seedTree();
      final only = await card(tree.leaf.id, 'only');
      final target = await siblingDeck();

      await h.cardRepository.moveCards(
        cardIds: <String>[only.id],
        targetDeckId: target,
      );

      expect(await h.contentTypeOf(tree.leaf.id), 'unset');
      expect(await h.contentTypeOf(target), 'card');
    });

    test('a source that keeps a card keeps its type', () async {
      final tree = await h.seedTree();
      final first = await card(tree.leaf.id, 'first');
      await card(tree.leaf.id, 'second');
      final target = await siblingDeck();

      await h.cardRepository.moveCards(
        cardIds: <String>[first.id],
        targetDeckId: target,
      );

      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });

    test('a target that already holds cards stays card', () async {
      final tree = await h.seedTree();
      final target = await siblingDeck();
      await card(target, 'resident');
      final moved = await card(tree.leaf.id, 'incoming');

      await h.cardRepository.moveCards(
        cardIds: <String>[moved.id],
        targetDeckId: target,
      );

      expect(await h.contentTypeOf(target), 'card');
    });

    test('refuses the deck the card already sits in', () async {
      final tree = await h.seedTree();
      final only = await card(tree.leaf.id, 'stay');

      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[only.id],
          targetDeckId: tree.leaf.id,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            CardConflictReason.moveTargetIsSameDeck,
          ),
        ),
      );
    });

    test('refuses a root target (BR-58)', () async {
      final tree = await h.seedTree();
      final only = await card(tree.leaf.id, 'stay');

      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[only.id],
          targetDeckId: tree.root.id,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            CardConflictReason.moveTargetIsRoot,
          ),
        ),
      );
      expect(await deckOf(only.id), tree.leaf.id);
    });

    test('refuses a target that holds sub-decks (BR-64)', () async {
      final tree = await h.seedTree();
      final only = await card(tree.leaf.id, 'stay');

      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[only.id],
          targetDeckId: tree.branch.id,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            CardConflictReason.moveTargetHoldsDecks,
          ),
        ),
      );
    });

    test('refuses a cross-root move even on identical schedulers', () async {
      // Both trees run eight_box at generation 1 — "identical by coincidence"
      // is exactly the case BR-165 says is still not a mapping (BR-73/BR-74).
      final tree = await h.seedTree(prefix: 'A-');
      final other = await h.seedTree(prefix: 'X-');
      final moved = await card(tree.leaf.id, 'stay');

      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[moved.id],
          targetDeckId: other.leaf.id,
        ),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.reason,
            'reason',
            CardConflictReason.moveCrossRoot,
          ),
        ),
      );
      expect(await deckOf(moved.id), tree.leaf.id);
    });

    test('refuses a missing target and a missing card', () async {
      final tree = await h.seedTree();
      final only = await card(tree.leaf.id, 'stay');
      final target = await siblingDeck();

      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[only.id],
          targetDeckId: 'nope',
        ),
        throwsA(isA<NotFoundFailure>()),
      );
      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[only.id, 'ghost'],
          targetDeckId: target,
        ),
        throwsA(isA<NotFoundFailure>()),
      );
      expect(await deckOf(only.id), tree.leaf.id);
    });

    test('one invalid card rolls the whole batch back (BR-166)', () async {
      // The card from the other tree is the offender; the two legal ones must
      // not move, and the target must not gain a content type.
      final tree = await h.seedTree(prefix: 'A-');
      final other = await h.seedTree(prefix: 'X-');
      final legalOne = await card(tree.leaf.id, 'one');
      final legalTwo = await card(tree.leaf.id, 'two');
      final foreign = await card(other.leaf.id, 'foreign');
      final target = await siblingDeck();

      await expectLater(
        h.cardRepository.moveCards(
          cardIds: <String>[legalOne.id, legalTwo.id, foreign.id],
          targetDeckId: target,
        ),
        throwsA(isA<ConflictFailure>()),
      );

      expect(await deckOf(legalOne.id), tree.leaf.id);
      expect(await deckOf(legalTwo.id), tree.leaf.id);
      expect(await deckOf(foreign.id), other.leaf.id);
      expect(await h.contentTypeOf(target), 'unset');
      expect(await h.contentTypeOf(tree.leaf.id), 'card');
    });
  });
}
