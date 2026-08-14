import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_validation_failure.dart'
    show CardSide;
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';

import 'support/card_text_fixture.dart';
import '../../deck/data/support/deck_repository_harness.dart';

/// The multi-tag filter on a real SQLite database (BR-183, BR-184).
///
/// **The whole point of these tests is the shape of the SQL**, and no fake can
/// answer for it: an `INNER JOIN card_tags` returns the right set of cards and
/// the wrong number of rows, so a card carrying three selected tags is counted
/// three times and eats three places in the window. Only a real query shows
/// that.
void main() {
  final h = installDeckRepositoryHarness();

  TagName tagName(String raw) => TagName.parse(raw).name!;

  Future<DeckEntity> seedDeck() async => (await h.seedTree()).leaf;

  Future<CardEntity> seedCard(
    String deckId,
    String front, {
    List<String> tags = const <String>[],
    bool isFlagged = false,
  }) async {
    final card = await h.cardRepository.createCard(
      deckId: deckId,
      front: cardText(front),
      back: cardText('back of $front', side: CardSide.back),
    );
    for (final tag in tags) {
      await h.cardRepository.addCardTag(cardId: card.id, name: tagName(tag));
    }
    if (isFlagged) {
      await h.cardRepository.setCardFlag(cardId: card.id, isFlagged: true);
    }

    return card;
  }

  Future<String> tagId(String name) async {
    final entries = await h.tagCatalogRepository.watchTagCatalog().first;

    return entries
        .firstWhere((e) => TagName.fold(e.name) == TagName.fold(name))
        .id;
  }

  Future<List<String>> fronts(
    String deckId, {
    required TagFilter tags,
    CardListFilter filter = CardListFilter.all,
    String? search,
    int limit = 50,
  }) async {
    final items = await h.cardRepository
        .watchCardListItems(
          deckId,
          limit: limit,
          filter: filter,
          searchTerm: search,
          now: h.currentInstant,
          tags: tags,
        )
        .first;

    return <String>[
      for (final CardListItemModel item in items) item.card.front,
    ];
  }

  Future<int> count(
    String deckId, {
    required TagFilter tags,
    CardListFilter filter = CardListFilter.all,
    String? search,
  }) => h.cardRepository
      .watchFilteredCardCount(
        deckId,
        filter: filter,
        searchTerm: search,
        now: h.currentInstant,
        tags: tags,
      )
      .first;

  group('no tag selected is the identity (BR-183)', () {
    test('the list and the count are what they were without tags', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun']);
      await seedCard(deck.id, 'b');

      expect(await fronts(deck.id, tags: TagFilter.none), hasLength(2));
      expect(await count(deck.id, tags: TagFilter.none), 2);
    });
  });

  group('OR within the selected tags (BR-183)', () {
    test('one tag selects the cards that carry it', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun']);
      await seedCard(deck.id, 'b', tags: <String>['verb']);
      await seedCard(deck.id, 'c');

      final noun = TagFilter.of(<String>[await tagId('noun')]);

      expect(await fronts(deck.id, tags: noun), <String>['a']);
      expect(await count(deck.id, tags: noun), 1);
    });

    test('two tags widen — a card with either matches', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun']);
      await seedCard(deck.id, 'b', tags: <String>['verb']);
      await seedCard(deck.id, 'c', tags: <String>['adjective']);

      final both = TagFilter.of(<String>[
        await tagId('noun'),
        await tagId('verb'),
      ]);

      // AND would return nothing here, and that is the reading the rule
      // rejects: two tags are "either of these", not "both of these".
      expect((await fronts(deck.id, tags: both)).toSet(), <String>{'a', 'b'});
      expect(await count(deck.id, tags: both), 2);
    });

    test('a card carrying every selected tag appears exactly once', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun', 'verb', 'adjective']);
      await seedCard(deck.id, 'b', tags: <String>['noun']);

      final three = TagFilter.of(<String>[
        await tagId('noun'),
        await tagId('verb'),
        await tagId('adjective'),
      ]);

      // A join would return card `a` three times: once per matching link.
      expect(await fronts(deck.id, tags: three), <String>['b', 'a']);
      expect(await count(deck.id, tags: three), 2);
    });

    test(
      'a tag id nothing carries matches nothing, and does not throw',
      () async {
        final deck = await seedDeck();
        await seedCard(deck.id, 'a', tags: <String>['noun']);

        // The stale-id case BR-186/BR-187 leave behind: it narrows to nothing
        // rather than erroring, which is what makes Clear a recovery rather than
        // a restart.
        final gone = TagFilter.of(const <String>['deleted-tag']);

        expect(await fronts(deck.id, tags: gone), isEmpty);
        expect(await count(deck.id, tags: gone), 0);
      },
    );
  });

  group('AND with the state filter and the search term (BR-183)', () {
    test('tag AND flagged', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun'], isFlagged: true);
      await seedCard(deck.id, 'b', tags: <String>['noun']);
      await seedCard(deck.id, 'c', isFlagged: true);

      final noun = TagFilter.of(<String>[await tagId('noun')]);

      expect(
        await fronts(deck.id, tags: noun, filter: CardListFilter.flagged),
        <String>['a'],
      );
      expect(
        await count(deck.id, tags: noun, filter: CardListFilter.flagged),
        1,
      );
    });

    test('tag AND search term', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'công nghệ', tags: <String>['noun']);
      await seedCard(deck.id, 'công việc', tags: <String>['verb']);
      await seedCard(deck.id, 'khác', tags: <String>['noun']);

      final noun = TagFilter.of(<String>[await tagId('noun')]);

      expect(await fronts(deck.id, tags: noun, search: 'CÔNG'), <String>[
        'công nghệ',
      ]);
      expect(await count(deck.id, tags: noun, search: 'CÔNG'), 1);
    });

    test('tag AND new', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun']);
      await seedCard(deck.id, 'b', tags: <String>['verb']);

      final noun = TagFilter.of(<String>[await tagId('noun')]);

      // Every freshly created card is new (BR-90), so this narrows by the tag
      // and by nothing else — which is exactly the composition being checked.
      expect(
        await fronts(deck.id, tags: noun, filter: CardListFilter.isNew),
        <String>['a'],
      );
    });
  });

  group('the window is a window of cards (BR-183)', () {
    test('a limit counts cards, not matching links', () async {
      final deck = await seedDeck();
      for (var i = 0; i < 4; i++) {
        await seedCard(deck.id, 'card-$i', tags: <String>['noun', 'verb']);
      }

      final both = TagFilter.of(<String>[
        await tagId('noun'),
        await tagId('verb'),
      ]);

      // Eight links, four cards. A join with `LIMIT 3` returns three *rows*,
      // which is two cards — the page silently shrinks.
      expect(await fronts(deck.id, tags: both, limit: 3), hasLength(3));
      expect(await count(deck.id, tags: both), 4);
    });

    test('the count and the list agree on the same predicate', () async {
      final deck = await seedDeck();
      await seedCard(deck.id, 'a', tags: <String>['noun', 'verb']);
      await seedCard(deck.id, 'b', tags: <String>['verb']);
      await seedCard(deck.id, 'c');

      final both = TagFilter.of(<String>[
        await tagId('noun'),
        await tagId('verb'),
      ]);

      expect(
        (await fronts(deck.id, tags: both)).length,
        await count(deck.id, tags: both),
      );
    });
  });

  group('select all uses the same predicate (BR-167, BR-183)', () {
    test('the ids are the tag-filtered set, not the whole deck', () async {
      final deck = await seedDeck();
      final a = await seedCard(deck.id, 'a', tags: <String>['noun', 'verb']);
      await seedCard(deck.id, 'b');

      final both = TagFilter.of(<String>[
        await tagId('noun'),
        await tagId('verb'),
      ]);

      final ids = await h.cardRepository.readCardIdsMatching(
        deck.id,
        now: h.currentInstant,
        tags: both,
      );

      // One id, not two: a card matching two selected tags must not be named
      // twice, or a bulk delete would run over it twice.
      expect(ids, <String>[a.id]);
    });
  });

  group('the tag-filtered reads stay live', () {
    test('untagging the last matching card re-emits an empty list '
        'and a zero count', () async {
      final deck = await seedDeck();
      final card = await seedCard(deck.id, 'a', tags: <String>['noun']);
      final noun = TagFilter.of(<String>[await tagId('noun')]);

      final lists = <List<CardListItemModel>>[];
      final counts = <int>[];
      final listSub = h.cardRepository
          .watchCardListItems(
            deck.id,
            limit: 50,
            now: h.currentInstant,
            tags: noun,
          )
          .listen(lists.add);
      final countSub = h.cardRepository
          .watchFilteredCardCount(deck.id, now: h.currentInstant, tags: noun)
          .listen(counts.add);
      await pumpEventQueue();

      await h.cardRepository.removeCardTag(
        cardId: card.id,
        tagId: noun.tagIds.single,
      );
      await pumpEventQueue();
      await listSub.cancel();
      await countSub.cancel();

      // Both reads depend on `card_tags` only through an expression drift
      // inlines, so neither gets it from the generated `readsFrom`. Without the
      // repair the row stays on screen and the header keeps quoting 1.
      expect(lists.first, hasLength(1));
      expect(lists.last, isEmpty);
      expect(counts.first, 1);
      expect(counts.last, 0);
    });
  });
}
