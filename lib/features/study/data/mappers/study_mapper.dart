import '../../../../core/database/app_database.dart';
import '../../domain/entities/study_queue_item_entity.dart';
import '../../domain/entities/study_session_entity.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_queue_item_status_model.dart';
import '../../domain/models/study_session_kind_model.dart';
import '../../domain/models/study_session_status_model.dart';

/// Drift rows in, domain entities out. Nothing Drift-shaped crosses this file
/// (AD-01).
///
/// Enums are read through their own `fromDbValue`, which is where each one
/// decides whether an unrecognised value degrades or throws. Repeating that
/// decision here would give the same value two behaviours depending on which
/// path read it.
StudySessionEntity studySessionEntityFromRow(StudySession row) =>
    StudySessionEntity(
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
);
