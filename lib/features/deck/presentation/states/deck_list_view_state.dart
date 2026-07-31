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
/// The repository's own order is by creation, which is [DeckListSort.recent].
/// Sorting here rather than in SQL keeps it a view choice: a second screen wanting
/// a different order does not become a second query.
enum DeckListSort {
  /// Newest first — the order decks were created in, reversed.
  recent,

  /// By name, case-insensitively.
  name,
}

/// Whether the level summary panel is on screen.
///
/// **Three states, not a boolean, because "the user has not said" is not the same
/// as "hide it".** The panel used to default to showing, on the argument that it
/// is the most useful thing on the screen on the day you opened the app to study.
/// That is true of the day there is something to study. On every other day it
/// opened to announce that nothing was waiting and then had to be dismissed by
/// hand — a panel asking for an action in order to say no action is needed.
///
/// [auto] is the answer: the panel follows the level's due count until the user
/// says otherwise, and once they do, their choice sticks and stops following it.
enum DeckSummaryVisibility {
  /// Follow the level: shown where something is due, absent where nothing is.
  auto,

  /// The user opened it. Stays open on a level with nothing due — asking for the
  /// panel is asking for the progress bar inside it, which is worth seeing on a
  /// deck that is finished.
  shown,

  /// The user dismissed it. Stays closed even where something is due; the link
  /// that brings it back is always there.
  hidden,
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
      DeckListSort.recent => b.summary.deck.createdAt.compareTo(
        a.summary.deck.createdAt,
      ),
      DeckListSort.name => a.summary.deck.name.toLowerCase().compareTo(
        b.summary.deck.name.toLowerCase(),
      ),
    };
    if (primary != 0) return primary;

    return a.index.compareTo(b.index);
  });

  return <DeckSummary>[for (final entry in indexed) entry.summary];
}
