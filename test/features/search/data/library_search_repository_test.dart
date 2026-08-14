import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/search/domain/models/search_match_rank_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';

import 'support/search_harness.dart';

/// What Global Library Search finds, on a real database (BR-182, BR-185…BR-187).
void main() {
  final h = installSearchHarness();

  test(
    'it matches deck names, card fronts, card backs and tag names',
    () async {
      final DeckEntity root = await h.root('Library');
      final DeckEntity byName = await h.child('Noun decks', root.id);
      final DeckEntity holder = await h.child('Holder', root.id);
      final CardEntity byFront = await h.card(
        holder.id,
        'noun',
        back: 'danh từ',
      );
      final CardEntity byBack = await h.card(holder.id, 'word', back: 'a noun');
      final CardEntity byTag = await h.card(
        holder.id,
        'unrelated',
        back: 'nothing',
        tags: <String>['noun'],
      );

      final LibrarySearchPage page = await h.page('noun');

      expect(page.decks.map((d) => d.deckId), <String>[byName.id]);
      expect(page.cards.map((c) => c.cardId).toSet(), <String>{
        byFront.id,
        byBack.id,
        byTag.id,
      });
    },
  );

  test(
    'it does not match the optional detail fields, and never the schedule',
    () async {
      // BR-182 names four fields. Example, hint and pronunciation are outside the
      // scope on purpose: they are supporting text, and matching them would put a
      // card in the list for a word its front and back do not contain.
      final DeckEntity root = await h.root('Library');
      final DeckEntity holder = await h.child('Holder', root.id);
      final CardEntity card = await h.card(holder.id, 'front', back: 'back');
      // Written straight to the columns: the card write path takes the three
      // details through `CardDetailText`, and going through it would prove
      // nothing about which columns the *search* reads.
      await h.decks.db.customStatement(
        'UPDATE cards SET example = ?, hint = ?, pronunciation = ? WHERE id = ?',
        <Object>['zebra', 'zebra', 'zebra', card.id],
      );

      expect((await h.page('zebra')).isEmpty, isTrue);
    },
  );

  test(
    'a card carrying two matching tags is still one result (BR-187)',
    () async {
      final DeckEntity root = await h.root('Library');
      final DeckEntity holder = await h.child('Holder', root.id);
      final CardEntity card = await h.card(
        holder.id,
        'plain',
        back: 'plain',
        tags: <String>['noun', 'nouns', 'common nouns'],
      );

      final LibrarySearchPage page = await h.page('noun');

      expect(page.cards.map((c) => c.cardId), <String>[card.id]);
      expect(
        page.cards.single.matchedTagName,
        'noun',
        reason: 'the best-ranked matching tag is the one that explains the row',
      );
    },
  );

  test('a card matching on its own text names no tag', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    await h.card(holder.id, 'noun', back: 'x', tags: <String>['verb']);

    expect((await h.page('noun')).cards.single.matchedTagName, isNull);
  });

  test('Unicode case folds on both sides of the comparison (BR-183)', () async {
    // The bug the folded columns exist for: SQLite's `lower()` leaves `Ô` and
    // `Đ` alone, so a card stored in capitals could not be found by typing the
    // lowercase form while a lowercase card could.
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('CÔNG NGHỆ', root.id);
    final CardEntity card = await h.card(
      holder.id,
      'ĐỘNG TỪ',
      back: 'VERB',
      tags: <String>['NGỮ PHÁP'],
    );

    expect((await h.page('công nghệ')).decks.single.deckId, holder.id);
    expect((await h.page('động từ')).cards.single.cardId, card.id);
    expect((await h.page('ngữ pháp')).cards.single.cardId, card.id);
  });

  test('a wildcard character is an ordinary character', () async {
    // `LIKE` would read `%` as "anything", so `100%` would match every card and
    // a lone `%` would return the library. `instr` has no pattern language.
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    final CardEntity literal = await h.card(
      holder.id,
      '100% cotton',
      back: 'x',
    );
    await h.card(holder.id, 'plain', back: 'y');

    expect((await h.page('100%')).cards.map((c) => c.cardId), <String>[
      literal.id,
    ]);
    // A lone `%` finds the one card that literally contains the character —
    // under `LIKE` it would have returned both, which is the whole library.
    expect((await h.page('%')).cards.map((c) => c.cardId), <String>[
      literal.id,
    ]);
    // And `_`, `LIKE`'s single-character wildcard, matches nothing at all.
    expect((await h.page('_')).cards, isEmpty);
  });

  test(
    'decks come before cards, and each group ranks exact, prefix, contains',
    () async {
      final DeckEntity root = await h.root('Library');
      final DeckEntity holder = await h.child('Holder', root.id);
      final DeckEntity exactDeck = await h.child('noun', root.id);
      final DeckEntity prefixDeck = await h.child('nouns and more', root.id);
      final CardEntity exactCard = await h.card(holder.id, 'noun', back: 'x');
      final CardEntity prefixCard = await h.card(holder.id, 'nouny', back: 'y');
      final CardEntity containsCard = await h.card(
        holder.id,
        'a noun here',
        back: 'z',
      );

      final LibrarySearchPage page = await h.page('noun');

      expect(page.decks.map((d) => d.deckId), <String>[
        exactDeck.id,
        prefixDeck.id,
      ]);
      expect(page.cards.map((c) => c.cardId), <String>[
        exactCard.id,
        prefixCard.id,
        containsCard.id,
      ]);
      expect(page.cards.map((c) => c.rank), <SearchMatchRank>[
        SearchMatchRank.exact,
        SearchMatchRank.prefix,
        SearchMatchRank.contains,
      ]);
    },
  );

  test(
    'a back-side exact match outranks a front-side contains match',
    () async {
      // The rank of a card is the best of its fields, not the front's alone.
      final DeckEntity root = await h.root('Library');
      final DeckEntity holder = await h.child('Holder', root.id);
      final CardEntity onBack = await h.card(holder.id, 'zzz', back: 'noun');
      final CardEntity onFront = await h.card(
        holder.id,
        'aaa noun aaa',
        back: 'q',
      );

      expect((await h.page('noun')).cards.map((c) => c.cardId), <String>[
        onBack.id,
        onFront.id,
      ]);
    },
  );

  test('a result carries the path that leads to it', () async {
    final DeckEntity root = await h.root('Korean');
    final DeckEntity mid = await h.child('Grammar', root.id);
    final DeckEntity leaf = await h.child('Noun forms', mid.id);
    await h.card(leaf.id, 'noun card', back: 'x');

    final LibrarySearchPage page = await h.page('noun');

    expect(page.decks.single.deckPath, <String>['Korean', 'Grammar']);
    expect(
      page.cards.single.deckPath,
      <String>['Korean', 'Grammar', 'Noun forms'],
      reason: "a card's path includes the deck it lives in",
    );
  });

  test('an empty query opens no statement at all (BR-184)', () async {
    final DeckEntity root = await h.root('Library');
    await h.child('Noun', root.id);
    h.decks.clearStatements();

    final LibrarySearchPage page = await h.page('   ');

    expect(page, same(LibrarySearchPage.empty));
    expect(
      h.decks.statements,
      isEmpty,
      reason:
          'whitespace is not a cheaper search — it must not reach the database',
    );
  });

  test('a page of results costs two statements, not one per row', () async {
    // The N+1 this design exists to avoid: a path per row, or a tag read per
    // card, is invisible in the result and only a statement count can see it.
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    for (var i = 0; i < 10; i++) {
      await h.card(holder.id, 'noun $i', back: 'x', tags: <String>['noun']);
    }
    h.decks.clearStatements();

    final LibrarySearchPage page = await h.page('noun');

    expect(page.cards, hasLength(10));
    expect(h.decks.countStatements('FROM decks'), 1);
    expect(h.decks.countStatements('WITH matched'), 1);
  });
}
