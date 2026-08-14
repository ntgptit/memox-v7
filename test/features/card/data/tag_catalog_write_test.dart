import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart'
    show CardSide;
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// The tag catalog's **writes** on a real SQLite database (UC-12,
/// BR-185…BR-188).
///
/// **Real SQLite rather than a fake, and for these rules there is no choice.**
/// `INSERT OR IGNORE` deduplicating against a primary key, a rollback leaving
/// the original graph, and "the cascade did not fire, the statement did" are
/// claims about the database — a fake repository would answer them from Dart it
/// wrote itself.
void main() {
  final h = installDeckRepositoryHarness();

  TagName tagName(String raw) => TagName.parse(raw).name!;

  Future<DeckEntity> seedDeck() async => (await h.seedTree()).leaf;

  Future<CardEntity> seedCard(String deckId, String front) =>
      h.cardRepository.createCard(
        deckId: deckId,
        front: cardText(front),
        back: cardText('back of $front', side: CardSide.back),
      );

  /// The tag that owns [name]'s folded form, read straight out of the table.
  Future<String?> tagIdNamed(String name) async {
    final row = await h.db
        .customSelect(
          'SELECT id FROM tags WHERE name_folded = ?',
          variables: <Variable<Object>>[Variable<String>(TagName.fold(name))],
        )
        .getSingleOrNull();

    return row?.read<String>('id');
  }

  Future<List<String>> tagIdsOfCard(String cardId) async {
    final rows = await h.db
        .customSelect(
          'SELECT tag_id FROM card_tags WHERE card_id = ? ORDER BY tag_id',
          variables: <Variable<Object>>[Variable<String>(cardId)],
        )
        .get();

    return <String>[for (final row in rows) row.read<String>('tag_id')];
  }

  Future<List<TagCatalogEntry>> catalog({String? search}) =>
      h.tagCatalogRepository.watchTagCatalog(searchTerm: search).first;

  group('rename without a collision keeps the tag (BR-185)', () {
    test('the id and every link survive', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('nuon'));
      final id = (await tagIdNamed('nuon'))!;

      final outcome = await h.tagCatalogRepository.renameTag(
        tagId: id,
        name: tagName('noun'),
      );

      expect(outcome, TagRenameOutcome.renamed);
      expect(await tagIdNamed('noun'), id, reason: 'same row, new name');
      expect(await tagIdsOfCard(card.id), <String>[id]);
      expect(await h.countAll('tags'), 1);
      expect(await h.countAll('card_tags'), 1);
    });

    test('changing only the case is a re-spelling, not a merge', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));
      final id = (await tagIdNamed('noun'))!;

      final outcome = await h.tagCatalogRepository.renameTag(
        tagId: id,
        name: tagName('Noun'),
      );

      expect(outcome, TagRenameOutcome.renamed);
      expect((await catalog()).single.name, 'Noun');
      expect(await h.countAll('tags'), 1);
    });

    test('a tag that is gone refuses with a typed reason', () async {
      await expectLater(
        h.tagCatalogRepository.renameTag(
          tagId: 'no-such-tag',
          name: tagName('noun'),
        ),
        throwsA(
          isA<NotFoundFailure>().having(
            (NotFoundFailure f) => f.reason,
            'reason',
            TagCatalogProblem.tagMissing,
          ),
        ),
      );
    });
  });

  group('rename onto an existing name merges (BR-186)', () {
    test('links move, the source row is deleted, the target keeps its '
        'id and spelling', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: tagName('nouns'),
      );
      final other = await seedCard(deck.id, 'b');
      await h.cardRepository.addCardTag(
        cardId: other.id,
        name: tagName('Noun'),
      );
      final source = (await tagIdNamed('nouns'))!;
      final target = (await tagIdNamed('noun'))!;

      final outcome = await h.tagCatalogRepository.renameTag(
        tagId: source,
        name: tagName('noun'),
      );

      expect(outcome, TagRenameOutcome.merged);
      expect(await h.countAll('tags'), 1);
      expect(await tagIdNamed('noun'), target, reason: 'target keeps its id');
      expect((await catalog()).single.name, 'Noun', reason: 'and its spelling');
      expect(await tagIdsOfCard(card.id), <String>[target]);
      expect(await tagIdsOfCard(other.id), <String>[target]);
      expect((await catalog()).single.cardCount, 2);
    });

    test('a card carrying both ends up with one link, not two', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: tagName('nouns'),
      );
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));
      final source = (await tagIdNamed('nouns'))!;
      final target = (await tagIdNamed('noun'))!;

      await h.tagCatalogRepository.renameTag(
        tagId: source,
        name: tagName('noun'),
      );

      expect(await tagIdsOfCard(card.id), <String>[target]);
      expect(await h.countAll('card_tags'), 1);
    });

    test('a card already at ten tags does not go over (BR-94)', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      for (var i = 0; i < 10; i++) {
        await h.cardRepository.addCardTag(
          cardId: card.id,
          name: tagName('tag-$i'),
        );
      }
      expect(await tagIdsOfCard(card.id), hasLength(10));

      // Merging two of the card's own tags: it trades one for one, then loses
      // the duplicate — a merge can only ever lower a card's count.
      await h.tagCatalogRepository.renameTag(
        tagId: (await tagIdNamed('tag-0'))!,
        name: tagName('tag-1'),
      );

      expect(await tagIdsOfCard(card.id), hasLength(9));
      expect(await h.countAll('tags'), 9);
    });

    test('a card at ten tags holding the source but NOT the target stays '
        'at ten (BR-94)', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      for (var i = 0; i < 10; i++) {
        await h.cardRepository.addCardTag(
          cardId: card.id,
          name: tagName('tag-$i'),
        );
      }
      // The target exists but this card does not carry it, so the card trades
      // one for one. This is the only case where the count would transiently
      // reach eleven if the statements ran in the other order — and it is the
      // case the "a merge never raises a count" argument is load-bearing for.
      final other = await seedCard(deck.id, 'b');
      await h.cardRepository.addCardTag(
        cardId: other.id,
        name: tagName('target'),
      );

      await h.tagCatalogRepository.renameTag(
        tagId: (await tagIdNamed('tag-0'))!,
        name: tagName('target'),
      );

      expect(await tagIdsOfCard(card.id), hasLength(10));
      expect(
        await tagIdsOfCard(card.id),
        contains(await tagIdNamed('target')),
        reason: 'it traded tag-0 for the target, not added it',
      );
      expect(await tagIdsOfCard(other.id), hasLength(1));
    });

    test('merging a tag into one it does not share cards with keeps '
        'every card at its own count', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      for (var i = 0; i < 10; i++) {
        await h.cardRepository.addCardTag(
          cardId: card.id,
          name: tagName('tag-$i'),
        );
      }
      final other = await seedCard(deck.id, 'b');
      await h.cardRepository.addCardTag(
        cardId: other.id,
        name: tagName('lonely'),
      );

      // `lonely` merges into a tag the ten-tag card already has: that card
      // gains nothing, and the other card trades one for one.
      await h.tagCatalogRepository.renameTag(
        tagId: (await tagIdNamed('lonely'))!,
        name: tagName('tag-0'),
      );

      expect(await tagIdsOfCard(card.id), hasLength(10));
      expect(await tagIdsOfCard(other.id), hasLength(1));
    });
  });

  group('delete unlinks and deletes nothing else (BR-187, BR-188)', () {
    test('every card keeps its content, its flag and its schedule', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.setCardFlag(cardId: card.id, isFlagged: true);
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));
      final before = await h.rawCard(card.id);
      final statesBefore = await h.rawStates(card.id);

      await h.tagCatalogRepository.deleteTag((await tagIdNamed('noun'))!);

      expect(await h.countAll('tags'), 0);
      expect(await h.countAll('card_tags'), 0);
      expect(await h.countAll('cards'), 1, reason: 'the card is untouched');
      final after = await h.rawCard(card.id);
      expect(after!.data, before!.data, reason: 'no column of it was written');
      expect(
        (await h.rawStates(card.id)).single.data,
        statesBefore.single.data,
        reason: 'and neither was its schedule',
      );
    });

    test('a card whose only tag is deleted still exists', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('only'));

      await h.tagCatalogRepository.deleteTag((await tagIdNamed('only'))!);

      expect(await h.rawCard(card.id), isNotNull);
      expect(await h.contentTypeOf(deck.id), 'card');
    });

    test('a tag no card carries deletes cleanly', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: tagName('orphan'),
      );
      final id = (await tagIdNamed('orphan'))!;
      await h.cardRepository.removeCardTag(cardId: card.id, tagId: id);

      await h.tagCatalogRepository.deleteTag(id);

      expect(await h.countAll('tags'), 0);
    });

    test('a tag that is gone refuses with a typed reason', () async {
      await expectLater(
        h.tagCatalogRepository.deleteTag('no-such-tag'),
        throwsA(
          isA<NotFoundFailure>().having(
            (NotFoundFailure f) => f.reason,
            'reason',
            TagCatalogProblem.tagMissing,
          ),
        ),
      );
    });
  });

  group('rollback leaves the original graph (BR-186, BR-187)', () {
    /// Makes the **last** statement of both flows fail, and nothing before it.
    ///
    /// A trigger rather than dropping a table: `DROP TABLE tags` fires the
    /// `ON DELETE CASCADE` on `card_tags` on the way out, so the fixture the
    /// assertion is about is destroyed by the setup. This aborts the delete of
    /// the tag row after the links have already been rewritten — which is
    /// precisely the half-merged state BR-186 forbids, and the only way to
    /// prove the rollback undoes it.
    Future<void> failTagDeletes() => h.db.customStatement(
      'CREATE TRIGGER refuse_tag_delete BEFORE DELETE ON tags '
      "BEGIN SELECT RAISE(ABORT, 'refused'); END",
    );

    test('a merge that fails at the last statement changes nothing', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(
        cardId: card.id,
        name: tagName('nouns'),
      );
      final other = await seedCard(deck.id, 'b');
      await h.cardRepository.addCardTag(
        cardId: other.id,
        name: tagName('noun'),
      );
      final source = (await tagIdNamed('nouns'))!;
      final target = (await tagIdNamed('noun'))!;
      await failTagDeletes();

      await expectLater(
        h.tagCatalogRepository.renameTag(tagId: source, name: tagName('noun')),
        throwsA(isA<Failure>()),
      );

      expect(await h.countAll('tags'), 2, reason: 'both tags still there');
      expect(await h.countAll('card_tags'), 2);
      expect(await tagIdsOfCard(card.id), <String>[
        source,
      ], reason: 'the moved links were moved back');
      expect(await tagIdsOfCard(other.id), <String>[target]);
    });

    test('a delete that fails leaves every link in place', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a');
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName('noun'));
      final id = (await tagIdNamed('noun'))!;
      await failTagDeletes();

      await expectLater(
        h.tagCatalogRepository.deleteTag(id),
        throwsA(isA<Failure>()),
      );

      // The unlink runs first and would otherwise have stuck: a tag still in
      // the catalog with a count of zero, on cards that visibly carry it.
      expect(await h.countAll('tags'), 1);
      expect(await tagIdsOfCard(card.id), <String>[id]);
    });
  });
}
