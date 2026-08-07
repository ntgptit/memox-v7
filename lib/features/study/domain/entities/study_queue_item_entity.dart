import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/study_mode.dart';
import '../models/study_queue_item_status_model.dart';

part 'study_queue_item_entity.freezed.dart';

/// One card's place in one round of one stage (BR-102, BR-113).
///
/// **The queue is data, not controller state.** It carries rules — the ordering
/// of BR-23, the comeback of BR-26, the ceiling of BR-104 — and a rule-bearing
/// structure inside `presentation/` is a rule out of reach of every check that
/// can actually be run. Surviving the OS reclaiming the app (BR-103) is the
/// bonus, not the reason.
@freezed
abstract class StudyQueueItemEntity with _$StudyQueueItemEntity {
  const factory StudyQueueItemEntity({
    required String sessionId,

    /// The stage this row belongs to. Each stage gets its own queue over the
    /// same card set, shuffled independently (BR-113).
    required StudyMode mode,

    /// The round within the stage (BR-115).
    ///
    /// Always 1 for [StudyMode.browse] and [StudyMode.selfAssess]: they do not
    /// use rounds, they repeat through BR-26.
    required int round,

    required String cardId,

    /// Order inside this round (BR-23, BR-117).
    ///
    /// **Immutable once the round is built** — that is what [availableAt] is
    /// for.
    required int position,

    required StudyQueueItemStatus status,

    /// The lowest session cursor at which this card may be served again
    /// (BR-26).
    ///
    /// A forgotten card sets it to `cursor + 3`; nothing else moves. Rewriting
    /// [position] and shifting everything after it would turn one `forgotten`
    /// into a burst of updates and lose the original order — one number
    /// replacing one number does not.
    required int availableAt,

    /// Turns graded so far in this session.
    ///
    /// Zero means the next one is `scheduled` (BR-77), and it is what BR-104's
    /// ceiling of three counts.
    required int answersInSession,

    /// `recall` only: the time left on a turn in progress (BR-133).
    ///
    /// Stored so Resume continues the turn instead of restarting it. A new turn
    /// in a later round is a different turn and starts at the full twenty
    /// seconds.
    required int? remainingMs,

    /// `recall` only: whether the answer has already been revealed (BR-133), so
    /// Resume does not hide it again.
    required bool isRevealed,
  }) = _StudyQueueItemEntity;
}
