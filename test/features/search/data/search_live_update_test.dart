import 'dart:async';

import 'package:drift/drift.dart' show Table, TableInfo, Variable;

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_name_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';

import 'support/search_harness.dart';

/// BR-189: a result already on screen corrects itself when the library changes.
///
/// **This is the half a `.watch()` on the card query cannot do.** Renaming an
/// ancestor touches only `decks`, and moving a card touches only `cards` — so a
/// stream whose dependency set is taken from the generated `readsFrom` of the
/// card statement would leave a stale path on screen with nothing to correct it.
void main() {
  final h = installSearchHarness();

  /// Subscribes to a live search and returns the emissions as they arrive.
  ({Stream<LibrarySearchPage> stream, Future<void> Function() close}) live(
    String query,
  ) {
    final controller = StreamController<LibrarySearchPage>();
    final StreamSubscription<LibrarySearchPage> subscription = h.repository
        .watchSearchPage(
          query: SearchQuery.parse(query),
          after: LibrarySearchCursor.start,
          pageSize: 20,
        )
        .listen(controller.add, onError: controller.addError);
    addTearDown(subscription.cancel);

    return (
      stream: controller.stream,
      close: () async {
        await subscription.cancel();
        await controller.close();
      },
    );
  }

  test(
    'renaming an ancestor updates the path of a card already listed',
    () async {
      final DeckEntity root = await h.root('Korean');
      final DeckEntity holder = await h.child('Grammar', root.id);
      await h.card(holder.id, 'noun card', back: 'x');

      final feed = live('noun');
      final Stream<LibrarySearchPage> emissions = feed.stream;
      final Future<List<LibrarySearchPage>> collected = emissions
          .take(2)
          .toList();

      // Let the first read land before the write, so the two emissions are
      // "before" and "after" rather than one combined snapshot.
      await Future<void>.delayed(Duration.zero);
      await h.decks.deckRepository.renameDeck(
        deckId: root.id,
        name: DeckName.parse('Korean 1').name!,
      );

      final List<LibrarySearchPage> pages = await collected;
      await feed.close();

      expect(pages.first.cards.single.deckPath, <String>['Korean', 'Grammar']);
      expect(pages.last.cards.single.deckPath, <String>['Korean 1', 'Grammar']);
    },
  );

  test('moving a card to another deck moves its path with it', () async {
    final DeckEntity root = await h.root('Korean');
    final DeckEntity from = await h.child('Old home', root.id);
    final DeckEntity to = await h.child('New home', root.id);
    final CardEntity card = await h.card(from.id, 'noun card', back: 'x');

    final feed = live('noun');
    final Future<List<LibrarySearchPage>> collected = feed.stream
        .take(2)
        .toList();

    await Future<void>.delayed(Duration.zero);
    await h.decks.cardRepository.moveCards(
      cardIds: <String>[card.id],
      targetDeckId: to.id,
    );

    final List<LibrarySearchPage> pages = await collected;
    await feed.close();

    expect(pages.first.cards.single.deckPath, <String>['Korean', 'Old home']);
    expect(pages.last.cards.single.deckPath, <String>['Korean', 'New home']);
  });

  test('deleting a card removes it from a live result set', () async {
    final DeckEntity root = await h.root('Korean');
    final DeckEntity holder = await h.child('Holder', root.id);
    final CardEntity card = await h.card(holder.id, 'noun card', back: 'x');

    final feed = live('noun');
    final Future<List<LibrarySearchPage>> collected = feed.stream
        .take(2)
        .toList();

    await Future<void>.delayed(Duration.zero);
    await h.decks.cardRepository.deleteCard(card.id);

    final List<LibrarySearchPage> pages = await collected;
    await feed.close();

    expect(pages.first.cards, hasLength(1));
    expect(pages.last.cards, isEmpty);
  });

  test('deleting a deck takes its cards out of the results too', () async {
    // Cascade, not a second delete: `ON DELETE CASCADE` removes the cards with
    // the deck, and the search has to notice both.
    final DeckEntity root = await h.root('Korean');
    final DeckEntity holder = await h.child('Noun holder', root.id);
    await h.card(holder.id, 'noun card', back: 'x');

    final feed = live('noun');
    final Future<List<LibrarySearchPage>> collected = feed.stream
        .take(2)
        .toList();

    await Future<void>.delayed(Duration.zero);
    await h.decks.deckRepository.deleteDeck(holder.id);

    final List<LibrarySearchPage> pages = await collected;
    await feed.close();

    expect(pages.first.decks, hasLength(1));
    expect(pages.first.cards, hasLength(1));
    expect(pages.last.isEmpty, isTrue);
  });

  test('renaming a tag updates a card that matched only through it', () async {
    // BR-189 names tag rename beside deck rename and move. The mechanism is the
    // `tags` table being in the watched set; without this test that half of the
    // rule was mechanism-only, which is the shape of gap a device suite catches
    // three months late.
    //
    // **Written as SQL, because tag rename has no repository method yet** — tag
    // management is its own feature. The two columns are exactly what a rename
    // must write: the stored name and the folded name that search compares
    // (BR-93, BR-183).
    final DeckEntity root = await h.root('Korean');
    final DeckEntity holder = await h.child('Holder', root.id);
    await h.card(
      holder.id,
      'unrelated',
      back: 'nothing',
      tags: <String>['noun'],
    );

    final feed = live('noun');
    final Future<List<LibrarySearchPage>> collected = feed.stream
        .take(2)
        .toList();

    await Future<void>.delayed(Duration.zero);
    await h.decks.db.customUpdate(
      'UPDATE tags SET name = ?, name_folded = ? WHERE name_folded = ?',
      variables: const <Variable<Object>>[
        Variable<String>('verb'),
        Variable<String>('verb'),
        Variable<String>('noun'),
      ],
      // `customUpdate` with `updates`, not `customStatement`: a raw statement
      // that does not declare which tables it touched invalidates no stream,
      // so the search would never learn of it. A real tag-rename repository
      // goes through the typed API and declares this for free; the migration
      // code states it by hand for the same reason.
      updates: <TableInfo<Table, Object?>>{h.decks.db.tags},
    );

    final List<LibrarySearchPage> pages = await collected;
    await feed.close();

    expect(pages.first.cards, hasLength(1));
    expect(
      pages.last.cards,
      isEmpty,
      reason: 'the card matched through the tag, and the tag no longer matches',
    );
  });

  test('cancelling the subscription stops the reads', () async {
    final DeckEntity root = await h.root('Korean');
    final DeckEntity holder = await h.child('Holder', root.id);
    await h.card(holder.id, 'noun card', back: 'x');

    final feed = live('noun');
    final Completer<LibrarySearchPage> first = Completer<LibrarySearchPage>();
    final StreamSubscription<LibrarySearchPage> subscription = feed.stream
        .listen(first.complete);
    await first.future;
    await subscription.cancel();
    await feed.close();
    h.decks.clearStatements();

    await h.card(holder.id, 'noun another', back: 'x');

    expect(
      h.decks.countStatements('WITH matched'),
      0,
      reason: 'a cancelled search must not keep querying behind the screen',
    );
  });
}
