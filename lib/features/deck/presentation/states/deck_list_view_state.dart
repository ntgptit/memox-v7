import '../../domain/models/deck_summary_model.dart';

/// Which decks the root list shows.
///
/// A view concern, not a business rule: the repository returns every root deck and
/// this decides which of them are on screen right now. Nothing here reaches the
/// database, so switching costs no query and cannot disagree with the counts —
/// both come from the same snapshot.
enum DeckListFilter {
  /// Everything the repository returned.
  all,

  /// Only decks with at least one card due (BR-22's definition, already applied
  /// by the aggregate — this filters on the count, it does not re-derive it).
  due,
}

/// The order the root list is shown in.
///
/// The repository's own order is persisted sibling order, which is
/// [DeckListSort.manual].
/// Sorting here rather than in SQL keeps it a view choice: a second screen wanting
/// a different order does not become a second query.
///
/// **Five, since Manual order joined the sort sheet.**
/// Two were all a toggle could carry — a control that cycles has to be pressed
/// once per option, so a third would have made the order the user wanted three
/// taps away and unpredictable in between. A sheet lists them, so the list can
/// answer the questions a learner actually has about their library.
enum DeckListSort {
  /// The persisted sibling order. This is the default so a reorder is visible
  /// immediately and remains visible after reopening the screen.
  manual,

  /// Newest first — the order decks were created in, reversed.
  ///
  /// **It was called `recent`, and the name is what let the bug live.** The
  /// label on it read *Recently studied* while the comparator sorted on
  /// `createdAt`, and nothing in the app records when a deck was last studied
  /// — `DeckEntity` has no such field. A vague name is what makes a reader
  /// re-derive the wrong meaning, so this one says which date it means.
  dateAdded,

  /// By name, case-insensitively.
  name,

  /// Most cards due first — the deck with the biggest backlog leads.
  ///
  /// The undivided due total, the same figure the tile's chip prints (BR-22),
  /// not overdue alone: "what should I open first" is answered by the whole of
  /// today's work, and a deck with 30 due today outranks one with 4 that missed
  /// their day.
  cardsDue,

  /// Least learned first — the deck with the most work left leads.
  ///
  /// Ascending on [DeckSummary.learnedFraction], not on the learned count: a
  /// 600-card deck at 80% has more cards left than a 40-card deck at 10% and is
  /// nonetheless the one closer to done. A deck with no cards has a fraction of
  /// 0 and sorts to the front, which is honest — nothing in it is learned.
  progress,
}

/// Applies the current view choices to one snapshot's decks.
///
/// Pure, and deliberately not a method on the controller: it is the whole of what
/// the toolbar does, and a function taking a list and returning a list is testable
/// without a container, a widget or a fake.
///
/// **Stable and total.** Sorting is on a copy, so the snapshot the repository
/// emitted is never mutated; ties keep the repository's order because
/// `List.sort` is not stable on its own and two decks with the same name would
/// otherwise swap places on unrelated rebuilds.
List<DeckSummary> applyDeckListView(
  List<DeckSummary> decks, {
  required DeckListFilter filter,
  required DeckListSort sort,
}) {
  final visible = switch (filter) {
    DeckListFilter.all => List<DeckSummary>.of(decks),
    DeckListFilter.due =>
      decks.where((DeckSummary summary) => summary.hasDueCards).toList(),
  };

  // Index-carrying comparison rather than `sort`: it makes the repository's order
  // the tiebreak, which is what keeps a list of same-named decks from reshuffling
  // between frames.
  final indexed = <({int index, DeckSummary summary})>[
    for (var i = 0; i < visible.length; i++) (index: i, summary: visible[i]),
  ];

  indexed.sort((a, b) {
    final primary = switch (sort) {
      DeckListSort.manual => 0,
      DeckListSort.dateAdded => b.summary.deck.createdAt.compareTo(
        a.summary.deck.createdAt,
      ),
      DeckListSort.name => a.summary.deck.name.toLowerCase().compareTo(
        b.summary.deck.name.toLowerCase(),
      ),
      // Descending: the biggest backlog leads, because the question this order
      // answers is "where is the work".
      DeckListSort.cardsDue => b.summary.dueCardCount.compareTo(
        a.summary.dueCardCount,
      ),
      // Ascending: the least-finished deck leads, for the same reason.
      DeckListSort.progress => a.summary.learnedFraction.compareTo(
        b.summary.learnedFraction,
      ),
    };
    if (primary != 0) return primary;

    return a.index.compareTo(b.index);
  });

  return <DeckSummary>[for (final entry in indexed) entry.summary];
}
