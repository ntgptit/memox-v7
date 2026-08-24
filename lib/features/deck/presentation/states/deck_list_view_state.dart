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

/// How much of the level summary hero is on screen.
///
/// **Two states, because the hero now has two jobs and only one of them is the
/// default.** The panel used to answer four questions at once and stood 320px
/// tall on a 852px screen — 38% of the viewport for a screen whose subject is
/// the list underneath it. Collapsed, it answers the one question the user
/// actually opened the app with ("how much is waiting, and can I start now");
/// the resting figures and the learned line are a disclosure away.
///
/// **It replaced a three-state visibility choice, and the dismiss button with
/// it** (owner decision, 2026-08-25). The reason the panel was dismissible was
/// that it was in the way of the list; at 18% of the viewport it no longer is,
/// and a chevron cannot mean "hide me" and "show me more" at the same time.
enum DeckSummaryDetail {
  /// The default: one figure line and the CTA.
  collapsed,

  /// The resting figures — New and Scheduled — plus the learned line above the
  /// progress track.
  expanded,
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
