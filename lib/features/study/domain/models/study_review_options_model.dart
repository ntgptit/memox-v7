import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';
import 'study_direction_model.dart';
import 'study_mode.dart';
import 'study_session_kind_model.dart';

part 'study_review_options_model.freezed.dart';

/// What the entry point has to know before it can start a review.
///
/// **One read returning both facts, not two use cases composed in a screen**
/// (AD-13). The modes come from the root deck's algorithm and so does the
/// algorithm's own name; asked separately they are two snapshots, and a scheduler
/// change landing between them would let the screen offer `self_assess` from
/// before it and skip the direction question from after it — which is the exact
/// pair that decides whether BR-203 applies.
@freezed
abstract class StudyReviewOptionsModel with _$StudyReviewOptionsModel {
  const factory StudyReviewOptionsModel({
    /// The modes this deck may be reviewed in (BR-146). Never contains `browse`.
    required List<StudyMode> modes,

    /// The root deck's algorithm (BR-06).
    required SchedulerType schedulerType,
  }) = _StudyReviewOptionsModel;

  const StudyReviewOptionsModel._();

  /// Whether starting a review in [mode] must ask for a direction first
  /// (BR-203).
  ///
  /// Delegated rather than restated: the screen asking the question by hand is
  /// the third copy of a three-term conjunction, and the copy that forgets a term
  /// is the one that puts a chooser in front of an `eight_box` deck.
  bool isDirectionChoiceRequiredFor(StudyMode mode) =>
      isReverseDirectionEligible(
        kind: StudySessionKind.reviewing,
        schedulerType: schedulerType,
        mode: mode,
      );
}
