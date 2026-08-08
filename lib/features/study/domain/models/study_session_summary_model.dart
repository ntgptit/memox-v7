import 'package:freezed_annotation/freezed_annotation.dart';

import 'study_session_kind_model.dart';
import 'study_session_status_model.dart';

part 'study_session_summary_model.freezed.dart';

/// What a finished session amounts to.
///
/// **[status] and [endReason] are part of the summary, not context around it.**
/// A session that stopped because a write failed and one that ran out of cards
/// produce the same counts, and showing those counts alone turns a failure into
/// an achievement. The screen needs both facts at the same moment, so they come
/// from the same read (AD-13).
@freezed
abstract class StudySessionSummaryModel with _$StudySessionSummaryModel {
  const factory StudySessionSummaryModel({
    required StudySessionKind kind,
    required StudySessionStatus status,
    required StudySessionEndReason? endReason,

    /// Cards with nothing left pending anywhere in the session.
    ///
    /// For a `learning` session this is the number that finished the whole
    /// stage chain and became schedulable (BR-144) — the one number that says
    /// what the session was for.
    required int finishedCards,

    /// Distinct cards that produced at least one graded turn.
    ///
    /// Not the same as [finishedCards]: `browse` writes no row at all (BR-111),
    /// and a card can be answered in an early stage without reaching the end of
    /// the chain.
    required int answeredCards,

    /// Turns answered with the algorithm's wrong action (BR-107).
    required int wrongTurns,

    /// Every graded turn, wrong ones included.
    required int totalTurns,
  }) = _StudySessionSummaryModel;

  const StudySessionSummaryModel._();

  /// Whether this session reached its natural end.
  ///
  /// The one place the distinction is drawn, so a widget cannot decide that
  /// `abandoned` is close enough to `completed` to celebrate.
  bool get hasCompleted => status == StudySessionStatus.completed;
}
