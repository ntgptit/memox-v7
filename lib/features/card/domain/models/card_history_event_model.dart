import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../../study/domain/models/study_action_model.dart';
import '../../../study/domain/models/study_answer_kind_model.dart';
import '../../../study/domain/models/study_mode.dart';
import '../../../study/domain/models/study_outcome_reason_model.dart';
import 'card_history_cursor_model.dart';

/// One recorded turn as the card's history reads it (BR-185).
///
/// **Every field is a stored column of `study_answers`, and none is derived.**
/// BR-76 and AD-11 exist because the obvious derivation is wrong in a case that
/// is not rare: a `scheduled` review answered `remembered` on a box-8 card has
/// `previousBox == nextBox == 8`, so diffing the schedule cannot tell it from a
/// turn that moved nothing. This read model therefore carries the row's own
/// values through untouched, and the widget renders them rather than
/// reconstructing them.
///
/// **It reuses Study's enums instead of restating them.** `StudyAnswerKind`,
/// `StudyMode`, `StudyAction` and `StudyOutcomeReason` are the vocabulary the
/// column was written in; a card-side copy would be a second spelling of one
/// stored value, and the two would drift the first time a mode is added.
/// Importing another feature's `domain/` is allowed — `data/` and
/// `presentation/` are what a feature may never reach into.
///
/// **[schedulerType] and [schedulerGeneration] belong to the row, not to the
/// deck.** The deck knows only its current scheduler and generation; a row from
/// before a Reset or a scheduler change has to be able to say which cycle and
/// which rules it belonged to, and BR-186 groups on exactly that.
class CardHistoryEventModel {
  const CardHistoryEventModel({
    required this.id,
    required this.answeredAt,
    required this.schedulerType,
    required this.schedulerGeneration,
    required this.kind,
    required this.mode,
    required this.action,
    required this.outcomeReason,
    required this.usedHint,
    required this.nextDueAt,
    required this.previousBox,
    required this.nextBox,
    required this.previousEaseFactor,
    required this.nextEaseFactor,
    required this.previousIntervalDays,
    required this.nextIntervalDays,
  });

  final String id;
  final DateTime answeredAt;

  /// The scheduler this turn was graded by — which decides which of the
  /// before→after pairs below are meaningful (AD-08).
  final SchedulerType schedulerType;

  /// The generation this turn belongs to (BR-186).
  final int schedulerGeneration;

  /// What the turn was for (BR-75). Stored, never derived (BR-76).
  final StudyAnswerKind kind;

  /// Which stage produced it (BR-98). Never `browse`, which grades nothing and
  /// writes no row at all (BR-111).
  final StudyMode mode;

  /// The canonical action, never the label the button showed (BR-132).
  final StudyAction action;

  /// Why it ended, when the action does not say (BR-131). Null when the user
  /// answered of their own accord.
  final StudyOutcomeReason? outcomeReason;

  /// `fill` only, and deliberately without effect on [action] (BR-136).
  final bool? usedHint;

  /// The schedule this turn produced. Null when the turn moved nothing, which
  /// is every turn of a `learning` session (BR-144).
  final DateTime? nextDueAt;

  final int? previousBox;
  final int? nextBox;
  final double? previousEaseFactor;
  final double? nextEaseFactor;
  final int? previousIntervalDays;
  final int? nextIntervalDays;

  /// Where a page ending on this event resumes (BR-184).
  ///
  /// On the event rather than on the page so the two can never disagree about
  /// which row the boundary is: the repository builds the page's cursor from
  /// its last event, and a caller that wants to resume from a different row
  /// cannot accidentally hand over a key from a row it did not read.
  CardHistoryCursor get cursor =>
      CardHistoryCursor(answeredAt: answeredAt, id: id);

  /// Whether this turn left the schedule where it found it (BR-144).
  ///
  /// A predicate rather than a widget-side `if` chain, because "no schedule
  /// change" is the *normal* outcome of the learning chain and reads as missing
  /// data unless it is stated. It asks the stored pairs, not the kind: a row
  /// whose scheduler columns are all null moved nothing, whatever it was for.
  bool get hasScheduleChange =>
      previousBox != null ||
      nextBox != null ||
      previousEaseFactor != null ||
      nextEaseFactor != null ||
      previousIntervalDays != null ||
      nextIntervalDays != null;
}
