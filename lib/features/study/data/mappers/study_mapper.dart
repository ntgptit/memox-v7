import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/study_queue_item_entity.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/models/study_direction_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_queue_item_status_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_status_model.dart';
import '../../domain/models/study_entry_summary_model.dart';
import '../../domain/models/study_schedule_model.dart';
import '../../domain/models/study_session_summary_model.dart';
import '../../domain/models/study_turn_model.dart';

/// Drift rows in, domain entities out. Nothing Drift-shaped crosses this file
/// (AD-01).
///
/// Enums are read through their own `fromDbValue`, which is where each one
/// decides whether an unrecognised value degrades or throws. Repeating that
/// decision here would give the same value two behaviours depending on which
/// path read it.
StudySessionEntity studySessionEntityFromRow(
  StudySession row,
) => StudySessionEntity(
  id: row.id,
  deckId: row.deckId,
  rootDeckId: row.rootDeckId,
  schedulerGeneration: row.schedulerGeneration,
  kind: StudySessionKind.fromDbValue(row.sessionKind),
  currentMode: StudyMode.fromDbValue(row.currentMode),
  status: StudySessionStatus.fromDbValue(row.status),
  endReason: row.endReason == null
      ? null
      : StudySessionEndReason.fromDbValue(row.endReason!),
  cursor: row.cursor,
  cardLimit: row.cardLimit,

  // Null stays null: a session outside BR-203's eligibility has no direction
  // to have chosen, and mapping it to a default would put a decision in the
  // entity that nobody made.
  direction: row.direction == null
      ? null
      : StudySessionDirection.fromDbValue(row.direction!),
  startedAt: row.startedAt.toUtc(),
  endedAt: row.endedAt?.toUtc(),
);

StudyQueueItemEntity studyQueueItemEntityFromRow(
  StudyQueueItem row,
) => StudyQueueItemEntity(
  sessionId: row.sessionId,
  mode: StudyMode.fromDbValue(row.mode),
  round: row.round,
  cardId: row.cardId,
  position: row.position,
  status: StudyQueueItemStatus.fromDbValue(row.status),
  availableAt: row.availableAt,
  answersInSession: row.answersInSession,
  remainingMs: row.remainingMs,

  // Stored as INTEGER, because SQLite has no boolean. Converting here rather
  // than letting `0`/`1` reach the domain is the point of the mapper.
  isRevealed: row.isRevealed != 0,

  direction: row.direction == null
      ? null
      : StudyRecallDirection.fromDbValue(row.direction!),
);

StudyCardModel studyCardModelFromRow(Card row) => StudyCardModel(
  id: row.id,
  front: row.front,
  back: row.back,
  example: row.example,
  hint: row.hint,
  pronunciation: row.pronunciation,
  frontFolded: row.frontFolded,
  backFolded: row.backFolded,
);

/// The one summary row, read by name.
///
/// A `QueryRow` rather than a generated companion because the statement behind
/// it is four correlated subqueries — drift generates no class for a shape it
/// did not write. Reading it here keeps the untyped access in the file whose job
/// is exactly that: rows in, domain out.
StudySessionSummaryModel studySessionSummaryFromRow(QueryRow row) {
  final endReason = row.read<String?>('endReason');

  return StudySessionSummaryModel(
    kind: StudySessionKind.fromDbValue(row.read<String>('kind')),
    status: StudySessionStatus.fromDbValue(row.read<String>('status')),
    endReason: endReason == null
        ? null
        : StudySessionEndReason.fromDbValue(endReason),
    finishedCards: row.read<int>('finishedCards'),
    answeredCards: row.read<int>('answeredCards'),
    wrongTurns: row.read<int>('wrongTurns'),
    totalTurns: row.read<int>('totalTurns'),
  );
}

/// The two entry counts and the two mode gates (BR-150, BR-153).
///
/// The nulls are real: a deck with no cards at all produces no rows to count,
/// and SQL says nothing rather than zero.
StudyEntrySummaryModel studyEntrySummaryFromRow(StudyEntryCountsResult row) =>
    StudyEntrySummaryModel(
      newCount: row.newCount ?? 0,
      dueCount: row.dueCount ?? 0,
      fillableCount: row.fillableCount ?? 0,
      distinctMeanings: row.distinctMeanings,
    );

/// A card-s schedule, whichever algorithm wrote it.
///
/// Both algorithms- columns live on one row, and each reads only its own —
/// `eight_box` has no ease factor and `sm2` has no box (AD-08).
StudyScheduleModel studyScheduleFromRow(CardStudyState row) =>
    StudyScheduleModel(
      box: row.currentBox,
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
    );
