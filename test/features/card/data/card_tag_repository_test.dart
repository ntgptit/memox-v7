import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// Tag integration on a real SQLite database (BR-93, BR-94): find-or-create by
/// folded name, the idempotent link, the ten-tag cap inside the write, and
/// detach leaving the tag row for reuse. Split from `card_repository_test.dart`
/// so neither file outgrows the size limit, and along a real seam — tags are
/// their own concern.
void main() {
  final h = installDeckRepositoryHarness();

  Future<({DeckEntity leaf, CardEntity card})> seedCard() async {
    final tree = await h.seedTree();
    final card = await h.cardRepository.createCard(
      deckId: tree.leaf.id,
      front: cardText('front'),
      back: cardText('back', side: CardSide.back),
    );

    return (leaf: tree.leaf, card: card);
  }

  TagName tagName(String raw) => TagName.parse(raw).name!;

  test('addCardTag mints a tag and links it', () async {
    final seeded = await seedCard();

    await h.cardRepository.addCardTag(
      cardId: seeded.card.id,
      name: tagName('noun'),
    );

    expect(await h.countAll('tags'), 1);
    expect(await h.countAll('card_tags'), 1);
  });

  test(
    'a name that already exists is reused, not duplicated (BR-93)',
    () async {
      final seeded = await seedCard();
      final second = await h.cardRepository.createCard(
        deckId: seeded.leaf.id,
        front: cardText('front 2'),
        back: cardText('back 2', side: CardSide.back),
      );

      // `Noun` then `noun` — the fold makes them the same tag.
      await h.cardRepository.addCardTag(
        cardId: seeded.card.id,
        name: tagName('Noun'),
      );
      await h.cardRepository.addCardTag(
        cardId: second.id,
        name: tagName('noun'),
      );

      expect(await h.countAll('tags'), 1, reason: 'one tag, shared');
      expect(await h.countAll('card_tags'), 2, reason: 'two cards carry it');
    },
  );

  test('adding a tag the card already has is a no-op', () async {
    final seeded = await seedCard();

    await h.cardRepository.addCardTag(
      cardId: seeded.card.id,
      name: tagName('noun'),
    );
    await h.cardRepository.addCardTag(
      cardId: seeded.card.id,
      name: tagName('noun'),
    );

    expect(await h.countAll('card_tags'), 1);
  });

  test('the eleventh tag is refused (BR-94)', () async {
    final seeded = await seedCard();
    for (var i = 0; i < kMaxTagsPerCard; i++) {
      await h.cardRepository.addCardTag(
        cardId: seeded.card.id,
        name: tagName('tag-$i'),
      );
    }

    await expectLater(
      h.cardRepository.addCardTag(
        cardId: seeded.card.id,
        name: tagName('one-too-many'),
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (ValidationFailure f) => f.problems,
          'problems',
          contains(TagValidationProblem.tooManyTags),
        ),
      ),
    );
    expect(await h.countAll('card_tags'), kMaxTagsPerCard);
  });

  test('removeCardTag detaches but leaves the tag row', () async {
    final seeded = await seedCard();
    await h.cardRepository.addCardTag(
      cardId: seeded.card.id,
      name: tagName('noun'),
    );
    final tag =
        (await h.cardRepository.watchCardTags(seeded.card.id).first).single;

    await h.cardRepository.removeCardTag(cardId: seeded.card.id, tagId: tag.id);

    expect(await h.countAll('card_tags'), 0);
    expect(await h.countAll('tags'), 1, reason: 'the tag survives for reuse');
  });
}
