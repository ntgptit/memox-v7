import 'package:drift/drift.dart' show Value;

import '../../../../core/database/app_database.dart';
import '../../../../core/error/failure.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/failures/card_conflict_failure.dart';

/// Review-state initialisation per scheduler (BR-09 table).
const int _eightBoxInitialBox = 1;
const double _sm2InitialEaseFactor = 2.5;
const int _sm2InitialIntervalDays = 0;
const int _sm2InitialRepetitions = 0;

/// The study state a card is born with (BR-09), per scheduler.
///
/// A mapper, not repository logic: it turns the root's scheduler meta into the
/// one `CardReviewStatesCompanion` the create transaction inserts, and each
/// scheduler fills only its own columns.
CardReviewStatesCompanion initialReviewStateFromScheduler(
  String cardId,
  ({SchedulerType type, int version, int generation}) scheduler,
) {
  final base = CardReviewStatesCompanion.insert(
    cardId: cardId,
    schedulerType: scheduler.type.dbValue,
    schedulerVersion: scheduler.version,
    schedulerGeneration: scheduler.generation,
  );

  return switch (scheduler.type) {
    // BR-09 initialisation table: each scheduler fills only its own columns.
    SchedulerType.eightBox => base.copyWith(
      currentBox: const Value<int?>(_eightBoxInitialBox),
    ),
    SchedulerType.sm2 => base.copyWith(
      easeFactor: const Value<double?>(_sm2InitialEaseFactor),
      intervalDays: const Value<int?>(_sm2InitialIntervalDays),
      repetitions: const Value<int?>(_sm2InitialRepetitions),
    ),
    // Unreachable: _resolveRootScheduler already refused it.
    SchedulerType.unknown => throw const ConflictFailure(
      message: 'This deck uses a study mode this app version does not know.',
      reason: CardConflictReason.unknownScheduler,
    ),
  };
}
