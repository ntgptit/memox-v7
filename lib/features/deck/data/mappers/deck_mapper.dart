import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/deck_entity.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../../domain/models/deck_summary_model.dart';
import '../../domain/models/scheduler_type_model.dart';

/// Maps a `decks` row to the domain entity.
///
/// The row is read tolerantly: an enum value this build has never seen maps to
/// `unknown` instead of crashing every list screen (the write direction fails
/// fast — see `SchedulerType.dbValue`). Timestamps come back in UTC, which is how
/// they were written and the only zone `due_at` maths is safe in.
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

/// The root level: every root deck, and no parent.
///
/// The counts stop being SQL here: nothing above this line sees a
/// `RootDeckSummariesResult`, which is what keeps the aggregate replaceable
/// without touching presentation (AD-01).
///
/// A root's scheduler is its own column — it is the deck the rule attaches to
/// (BR-06), so there is nothing to resolve.
///
/// `nextDueAt` is the same scalar on every row: one subquery, evaluated once by
/// SQLite and repeated across the join, so reading it off the first row is not a
/// guess about which row to trust. No rows means no root decks, which means no
/// cards anywhere (a card's deck is a foreign key), which means nothing can become
/// due — so `null` there is the truth and not a missing value.
///
/// `.toUtc()` because drift reads a stored `DateTime` back through
/// `DateTime.fromMillisecondsSinceEpoch`, which produces a **local** value for the
/// right instant. The instant is correct either way, but a local `DateTime` in a
/// domain model breaks equality against the UTC values everything else uses.
DeckListSnapshot rootLevelFromRows(List<RootDeckSummariesResult> rows) =>
    DeckListSnapshot(
      parent: null,
      decks: <DeckSummary>[
        for (final RootDeckSummariesResult row in rows)
          DeckSummary(
            deck: deckEntityFromRow(row.d),
            totalCardCount: row.totalCardCount,
            dueCardCount: row.dueCardCount,
            schedulerType: SchedulerType.fromDbValue(row.d.schedulerType ?? ''),
          ),
      ],
      nextDueAt: rows.isEmpty ? null : rows.first.nextDueAt?.toUtc(),
    );

/// One deck and what is directly inside it, each child carrying its subtree's
/// aggregate.
///
/// The `LEFT JOIN` gives one row per child, or a single row with a null `child`
/// when there are none — so the two cases the screen must not confuse are
/// distinguishable here:
///
/// * **no rows at all** — the deck does not exist, which surfaces as
///   [NotFoundFailure]. The screen renders a way back, not a retry (UC-03 E1).
/// * **one row, `child` null** — the deck exists and is empty, so reset may be
///   offered (BR-68).
///
/// `rows.first.parent` is the same deck in every row by construction: the join is
/// keyed on `parent.id = :parentId`.
///
/// The scheduler comes from the row's `inheritedSchedulerType`, which the query
/// read from the child's **root**. A sub-deck's own column is NULL by rule (BR-06),
/// so using it would leave every deck below the first level with no study mode on
/// screen — which is exactly the kind of blank the unified list exists to remove.
DeckListSnapshot childLevelFromRows(List<ChildDeckLevelResult> rows) {
  if (rows.isEmpty) {
    throw const NotFoundFailure(message: 'That deck no longer exists.');
  }

  return DeckListSnapshot(
    parent: deckEntityFromRow(rows.first.parent),
    decks: <DeckSummary>[
      for (final ChildDeckLevelResult row in rows)
        if (row.child case final Deck child)
          DeckSummary(
            deck: deckEntityFromRow(child),
            totalCardCount: row.totalCardCount,
            dueCardCount: row.dueCardCount,
            schedulerType: SchedulerType.fromDbValue(
              row.inheritedSchedulerType ?? '',
            ),
          ),
    ],
    nextDueAt: rows.first.nextDueAt?.toUtc(),
  );
}
