import '../../../core/database/app_database.dart';
import '../domain/card_review_state_entity.dart';
import '../../deck/domain/models/scheduler_type_model.dart';

/// Maps a `card_review_states` row to the domain entity.
///
/// The scheduler type is read tolerantly — an unrecognised value becomes
/// `unknown` rather than an exception — while writing `unknown` back is
/// impossible by construction (`SchedulerType.dbValue` throws).
CardReviewStateEntity cardReviewStateEntityFromRow(CardReviewState row) =>
    CardReviewStateEntity(
      cardId: row.cardId,
      schedulerType: SchedulerType.fromDbValue(row.schedulerType),
      schedulerVersion: row.schedulerVersion,
      schedulerGeneration: row.schedulerGeneration,
      dueAt: row.dueAt?.toUtc(),
      lastReviewedAt: row.lastReviewedAt?.toUtc(),
      reviewCount: row.reviewCount,
      lapseCount: row.lapseCount,
      currentBox: row.currentBox,
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      repetitions: row.repetitions,
    );
