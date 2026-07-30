import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/deck_detail_model.dart';
import '../../domain/models/root_deck_list_snapshot_model.dart';
import '../../domain/models/root_deck_summary_model.dart';
import '../../domain/models/scheduler_type_model.dart';

/// Maps a `decks` row to the domain entity.
///
/// The row is read tolerantly: an enum value this build has never seen maps to
/// `unknown` instead of crashing every list screen (the write direction fails
/// fast — see `SchedulerType.dbValue`). Timestamps come back in UTC, which is
/// how they were written and the only zone `due_at` maths is safe in.
DeckEntity deckEntityFromRow(Deck row) {
  final schedulerType = row.schedulerType;

  return DeckEntity(
    id: row.id,
    name: row.name,
    parentDeckId: row.parentDeckId,
    rootDeckId: row.rootDeckId,
    contentType: DeckContentType.fromDbValue(row.contentType),
    schedulerType: schedulerType == null
        ? null
        : SchedulerType.fromDbValue(schedulerType),
    schedulerGeneration: row.schedulerGeneration,
    firstReviewAt: row.firstReviewAt?.toUtc(),
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );
}

/// Maps the `deckDetail` result set to the deck-screen read model.
///
/// The `LEFT JOIN` gives one row per child, or a single row with a null `child`
/// when there are none — so the two cases the screen must not confuse are
/// distinguishable here:
///
/// * **no rows at all** — the deck does not exist, which surfaces as
///   [NotFoundFailure]. The screen renders a way back, not a retry (UC-03 E1).
/// * **one row, `child` null** — the deck exists and has no children, so reset
///   may be offered (BR-68).
///
/// `rows.first.deck` is the same deck in every row by construction: the join is
/// keyed on `deck.id = :deckId`.
DeckDetail deckDetailFromRows(List<DeckDetailResult> rows) {
  if (rows.isEmpty) {
    throw const NotFoundFailure(message: 'That deck no longer exists.');
  }

  return DeckDetail(
    deck: deckEntityFromRow(rows.first.deck),
    childDecks: rows
        .map((DeckDetailResult row) => row.child)
        .nonNulls
        .map(deckEntityFromRow)
        .toList(growable: false),
  );
}

/// Maps an aggregate row to the root-list read model (UC-06).
///
/// The counts stop being SQL here: nothing above this line sees a
/// `RootDeckSummariesResult`, which is what keeps the aggregate replaceable
/// without touching presentation (AD-01).
RootDeckSummary rootDeckSummaryFromRow(RootDeckSummariesResult row) =>
    RootDeckSummary(
      deck: deckEntityFromRow(row.d),
      totalCardCount: row.totalCardCount,
      dueCardCount: row.dueCardCount,
    );

/// Maps the aggregate result set to the list read model.
///
/// `nextDueAt` is the same scalar on every row — one subquery, evaluated once by
/// SQLite and repeated across the join — so reading it off the first row is not a
/// guess about which row to trust.
///
/// No rows means no root decks, which means no cards anywhere (a card's deck is a
/// foreign key), which means nothing can become due. So `null` there is the truth
/// and not a missing value.
/// `.toUtc()` for the same reason every other timestamp in this file gets it:
/// drift reads a stored `DateTime` back through
/// `DateTime.fromMillisecondsSinceEpoch`, which produces a **local** value for the
/// right instant. The instant is correct either way, but a local `DateTime` in a
/// domain model breaks equality against the UTC values everything else uses — and
/// `due_at` arithmetic is only safe in one zone.
RootDeckListSnapshot rootDeckListFromRows(List<RootDeckSummariesResult> rows) =>
    RootDeckListSnapshot(
      decks: rows.map(rootDeckSummaryFromRow).toList(growable: false),
      nextDueAt: rows.isEmpty ? null : rows.first.nextDueAt?.toUtc(),
    );
