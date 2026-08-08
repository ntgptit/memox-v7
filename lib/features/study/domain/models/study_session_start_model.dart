import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../deck/domain/models/scheduler_type_model.dart';
import '../entities/study_session_entity.dart';
import 'study_action_model.dart';
import 'study_turn_model.dart';

part 'study_session_start_model.freezed.dart';

/// Everything a screen needs the moment a session opens.
///
/// **One interaction, one read** (AD-13). Opening a session used to take three
/// calls — open it, ask the deck which algorithm it runs, then fetch the card
/// set — and three reads are three snapshots: a Reset landing between them would
/// leave the screen holding a session from before it and a card set from after.
@freezed
abstract class StudySessionStartModel with _$StudySessionStartModel {
  const factory StudySessionStartModel({
    required StudySessionEntity session,

    /// The deck's algorithm, so a graded mode can ask it what right and wrong
    /// mean (BR-107) rather than guessing.
    required SchedulerType schedulerType,

    /// The buttons this algorithm offers (BR-30).
    required List<StudyAction> actions,

    /// The whole card set, for the stages that lay out a board or draw
    /// distractors (BR-121, BR-153). Fixed for the session's life (BR-102).
    required List<StudyCardModel> cards,
  }) = _StudySessionStartModel;
}
