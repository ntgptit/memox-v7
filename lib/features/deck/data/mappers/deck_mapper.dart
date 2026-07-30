import '../../../../core/database/app_database.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/entities/deck_entity.dart';
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
