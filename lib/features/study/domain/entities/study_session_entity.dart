import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/study_direction_model.dart';
import '../models/study_mode.dart';
import '../models/study_session_kind_model.dart';
import '../models/study_session_status_model.dart';

part 'study_session_entity.freezed.dart';

/// One sitting: a set of cards, a kind, and the stage currently running.
///
/// **A session exists only because the user asked for one** (BR-101). Showing a
/// due count — a badge, a list, a notification — must never create one, which is
/// why nothing here is derived from "what is due right now": [cardLimit] and
/// [schedulerGeneration] are both frozen at the moment of opening.
@freezed
abstract class StudySessionEntity with _$StudySessionEntity {
  const factory StudySessionEntity({
    required String id,

    /// The deck being studied — often a root, sometimes a branch.
    required String deckId,

    /// The root at the moment the session opened.
    required String rootDeckId,

    /// The generation at the moment the session opened (BR-45).
    ///
    /// Every write compares this against the root's current generation and
    /// refuses when they differ (BR-46, BR-84). Without it, a session opened
    /// before a Reset could quietly un-reset the cards it touches.
    required int schedulerGeneration,

    /// Which of the two card sets this session works through (BR-142).
    required StudySessionKind kind,

    /// The stage running right now (BR-98).
    ///
    /// A [StudySessionKind.reviewing] session holds one value for its whole
    /// life; a [StudySessionKind.learning] session walks the algorithm's
    /// `stageSequence`.
    required StudyMode currentMode,

    required StudySessionStatus status,

    /// Null while in progress, and after a normal completion (BR-80).
    required StudySessionEndReason? endReason,

    /// Turns served so far — what BR-26 counts against.
    required int cursor,

    /// The card ceiling, fixed when the session opened (BR-139).
    ///
    /// Changing the setting afterwards must not move a running session, which is
    /// why the number lives here and not on the deck.
    required int cardLimit,

    /// Which way this session asks, chosen before the first turn (BR-182).
    ///
    /// **Null is the feature not being in play**, not a missing value: only a
    /// `reviewing` session of an `sm2` deck running `self_assess` is eligible, and
    /// every other session has no direction to have chosen. Fixed here for the
    /// same reason [cardLimit] is — Resume reads it and asks nothing (BR-186).
    required StudySessionDirection? direction,

    required DateTime startedAt,
    required DateTime? endedAt,
  }) = _StudySessionEntity;

  const StudySessionEntity._();

  /// Whether this session can still take answers.
  bool get isOpen => status == StudySessionStatus.inProgress;

  /// Whether [status] and [endReason] form a pair the matrix allows.
  ///
  /// The repository checks this before writing, so a bad pair fails at the
  /// boundary rather than being found later by invariant 12.
  bool get hasValidOutcome => status.isValidWith(endReason);
}
