import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';

import 'support/search_harness.dart';

/// BR-186 and BR-188: decks before cards, and a keyset that neither repeats a
/// row nor steps over one.
void main() {
  final h = installSearchHarness();

  /// Walks every page a query produces and returns the card ids in the order a
  /// reader would see them.
  Future<List<String>> walkCards(String query, {int pageSize = 2}) async {
    final ids = <String>[];
    var cursor = LibrarySearchCursor.start;
    // Bounded so a cursor that fails to advance fails the test instead of
    // hanging the suite.
    for (var page = 0; page < 10; page++) {
      final LibrarySearchPage read = await h.page(
        query,
        pageSize: pageSize,
        after: cursor,
      );
      ids.addAll(read.cards.map((c) => c.cardId));
      cursor = read.cursor;
      if (!read.hasMore) break;
    }

    return ids;
  }

  test('decks are exhausted before the first card appears', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('noun holder', root.id);
    final DeckEntity a = await h.child('noun a', root.id);
    final DeckEntity b = await h.child('noun b', root.id);
    final CardEntity card = await h.card(holder.id, 'noun card', back: 'x');

    // A page of two: the three matching decks fill page one and part of page
    // two, and the card cannot appear until the deck group has run out.
    final LibrarySearchPage first = await h.page('noun', pageSize: 2);

    expect(first.decks, hasLength(2));
    expect(first.cards, isEmpty, reason: 'a card may not jump a deck');
    expect(first.hasMore, isTrue);

    final LibrarySearchPage second = await h.page(
      'noun',
      pageSize: 2,
      after: first.cursor,
    );

    expect(second.decks.map((d) => d.deckId), <String>[holder.id]);
    expect(second.cards.map((c) => c.cardId), <String>[card.id]);
    expect(<String>[a.id, b.id], containsAll(first.decks.map((d) => d.deckId)));
  });

  test('paging a card group covers every row exactly once', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    final ids = <String>[];
    for (var i = 0; i < 7; i++) {
      // The same instant for all of them, so `created_at` cannot break the tie
      // and the id has to — the case the fourth cursor column exists for.
      ids.add((await h.card(holder.id, 'noun $i', back: 'x')).id);
    }

    final List<String> walked = await walkCards('noun', pageSize: 3);

    expect(walked, hasLength(7));
    expect(walked.toSet(), ids.toSet());
    expect(
      walked.toSet(),
      hasLength(walked.length),
      reason: 'no row appears twice across pages',
    );
  });

  test('a card created above the boundary does not shift a later page', () async {
    // The offset failure: with `LIMIT … OFFSET` a row inserted above the window
    // pushes everything down by one, so the last row of page 1 reappears at the
    // top of page 2 and one row is never seen.
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    for (var i = 1; i <= 4; i++) {
      await h.card(holder.id, 'noun b$i', back: 'x');
    }

    final LibrarySearchPage first = await h.page('noun', pageSize: 2);
    // Sorts above every row of page 1: `noun a` precedes `noun b1`.
    await h.card(holder.id, 'noun a', back: 'x');

    final LibrarySearchPage second = await h.page(
      'noun',
      pageSize: 2,
      after: first.cursor,
    );

    expect(
      second.cards.map((c) => c.front),
      <String>['noun b3', 'noun b4'],
      reason:
          'the boundary is the last row seen, not a count of rows before it',
    );
    expect(
      second.cards
          .map((c) => c.cardId)
          .toSet()
          .intersection(first.cards.map((c) => c.cardId).toSet()),
      isEmpty,
    );
  });

  test('the last page reports that the search is finished', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Holder', root.id);
    await h.card(holder.id, 'noun one', back: 'x');
    await h.card(holder.id, 'noun two', back: 'x');

    final LibrarySearchPage page = await h.page('noun');

    expect(page.cards, hasLength(2));
    expect(page.hasMore, isFalse);
    expect(page.cursor.isExhausted, isTrue);
  });

  test('a query that matches nothing is an empty finished page', () async {
    final DeckEntity root = await h.root('Library');
    await h.child('Holder', root.id);

    final LibrarySearchPage page = await h.page('zzzz');

    expect(page.isEmpty, isTrue);
    expect(page.hasMore, isFalse);
  });
}
