import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_result_model.dart';

import 'support/search_harness.dart';

/// The one thing a result row needs from `content_type`.
///
/// `library_search_mapper.dart` compares the stored column against the literal
/// `'card'` rather than importing the Deck feature's enum for one comparison.
/// A literal is only safe while something proves it against a deck the Deck
/// repository actually wrote — otherwise a rename of the value would quietly
/// draw folder icons over every deck of cards.
void main() {
  final h = installSearchHarness();

  test('a deck that holds cards is marked as one', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity holder = await h.child('Noun holder', root.id);
    // Creating the first card is what sets `content_type = 'card'` (BR-62).
    await h.card(holder.id, 'anything', back: 'x');

    final LibrarySearchPage page = await h.page('noun holder');

    expect(page.decks.single.isCardDeck, isTrue);
  });

  test('a deck that holds sub-decks is not', () async {
    final DeckEntity root = await h.root('Library');
    final DeckEntity branch = await h.child('Noun branch', root.id);
    await h.child('Leaf', branch.id);

    expect((await h.page('noun branch')).decks.single.isCardDeck, isFalse);
  });

  test('a deck with nothing in it yet is not', () async {
    // `unset` can still become either kind (BR-61), and until it does there is
    // no reason to promise the user a deck of cards.
    final DeckEntity root = await h.root('Library');
    await h.child('Noun unset', root.id);

    expect((await h.page('noun unset')).decks.single.isCardDeck, isFalse);
  });

  test('a root deck is a deck of decks, always', () async {
    // BR-58: a root holds only sub-decks and never changes.
    await h.root('Noun root');

    final DeckSearchHit hit = (await h.page('noun root')).decks.single;

    expect(hit.isCardDeck, isFalse);
    expect(hit.deckPath, isEmpty);
  });
}
