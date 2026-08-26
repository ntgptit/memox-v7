import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../study/domain/models/study_action_model.dart';
import '../../../../study/domain/models/study_answer_kind_model.dart';
import '../../../../study/domain/models/study_mode.dart';
import '../../../../study/domain/models/study_outcome_reason_model.dart';
import '../../../domain/models/card_history_event_model.dart';

/// Copy for the history timeline, in one place.
///
/// **It maps Study's enums with Card's own file, deliberately.** The words come
/// from the same ARB keys the session screen uses — `studyModeSelfAssess`,
/// `studyActionRemembered` — so the two surfaces cannot call one stored value
/// two different things. What is not shared is the mapping *file*: a feature may
/// read another feature's `domain/` and never its `presentation/`, and
/// `study_labels_widget.dart` lives in the half Card may not reach into.
///
/// Dates and times go through [MaterialLocalizations], which already formats for
/// the active locale — so nothing here concatenates a date by hand (M4.15 W6).
/// The separator between them is an ARB string for the same reason.
extension CardHistoryLabels on BuildContext {
  /// The name of the stage a turn came from (BR-98).
  ///
  /// **A `switch`, where `study_labels_widget.dart` uses a `Map`.** That file
  /// chose the map to keep AD-18's single-dispatch habit; the guard's scope
  /// exempts `presentation/` outright, and a map needs a fallback — which was
  /// `mode.name`, an untranslated enum identifier one step from the screen. A
  /// switch expression over an enum is exhaustive by the compiler, so a mode
  /// added later fails the build instead of shipping its identifier to a
  /// reader.
  ///
  /// [StudyMode.unknown] is a read-only value for a stored string this build
  /// does not recognise, so it has no name to show: it renders as the same
  /// placeholder an unrecorded schedule column uses, rather than as the word
  /// "unknown".
  String cardHistoryMode(StudyMode mode) => switch (mode) {
    StudyMode.browse => l10n.studyModeBrowse,
    StudyMode.selfAssess => l10n.studyModeSelfAssess,
    StudyMode.match => l10n.studyModeMatch,
    StudyMode.guess => l10n.studyModeGuess,
    StudyMode.recall => l10n.studyModeRecall,
    StudyMode.fill => l10n.studyModeFill,
    StudyMode.unknown => _absentValue,
  };

  /// The stored kind of the turn (BR-75, BR-76).
  String cardHistoryKind(StudyAnswerKind kind) => switch (kind) {
    StudyAnswerKind.learning => l10n.cardHistoryKindLearning,
    StudyAnswerKind.scheduled => l10n.cardHistoryKindScheduled,
    StudyAnswerKind.relearning => l10n.cardHistoryKindRelearning,
  };

  /// The canonical action, in the same words the review buttons use (BR-132).
  String cardHistoryAction(StudyAction action) => switch (action) {
    StudyAction.forgotten => l10n.studyActionForgotten,
    StudyAction.remembered => l10n.studyActionRemembered,
    StudyAction.again => l10n.studyActionAgain,
    StudyAction.hard => l10n.studyActionHard,
    StudyAction.good => l10n.studyActionGood,
    StudyAction.easy => l10n.studyActionEasy,
  };

  /// A stored UTC instant as the reader's local date and time.
  ///
  /// `toLocal()` here and nowhere else: the database stores UTC (AD-06), and a
  /// timeline that showed UTC would put a 23:00 review on the wrong day for
  /// most of the world.
  String cardHistoryTimestamp(DateTime utc) {
    final local = utc.toLocal();
    final materialL10n = MaterialLocalizations.of(this);

    return l10n.cardHistoryEventTime(
      materialL10n.formatMediumDate(local),
      materialL10n.formatTimeOfDay(
        TimeOfDay.fromDateTime(local),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(this),
      ),
    );
  }

  /// A stored UTC instant as a date alone — for schedule fields, where the time
  /// of day is an artefact of when the review happened rather than a fact about
  /// the schedule.
  String cardHistoryDate(DateTime utc) =>
      MaterialLocalizations.of(this).formatMediumDate(utc.toLocal());

  /// The before→after lines of one event, in the vocabulary of the scheduler
  /// **that row was graded by** (BR-242).
  ///
  /// Driven by which columns the row actually filled rather than by
  /// [CardHistoryEventModel.schedulerType]: a card whose deck changed scheduler
  /// still has older rows written under the previous one, and those rows must
  /// read in their own terms. Asking the data is what makes that automatic.
  List<CardHistoryScheduleLine> cardHistoryScheduleLines(
    CardHistoryEventModel event,
  ) => _scheduleLines(event, spoken: false);

  /// The colour a stored action is drawn in (BR-132, M4.15 W4).
  ///
  /// **Three semantic tokens for six actions, and the grouping is the
  /// scheduler's own.** `eight_box` records `forgotten`/`remembered`; SM-2
  /// records four grades, and BR-132 already treats `again` as the relearning
  /// answer and the other three as passes. So the timeline says *what happened*
  /// — it did not stick, it stuck, it stuck but it was work — rather than
  /// minting a colour per button. `hard` is the only one that needed a third
  /// word, and `warning` is the token the app already spends on "due, not
  /// late".
  ///
  /// Colour is never the only signal here: the word itself is on the line
  /// beside the dot, in this same colour (D5).
  Color cardHistoryActionColor(StudyAction action) {
    final semantic = semanticColors;

    return switch (action) {
      StudyAction.forgotten || StudyAction.again => semantic.danger,
      StudyAction.hard => semantic.warning,
      StudyAction.remembered ||
      StudyAction.good ||
      StudyAction.easy => semantic.success,
    };
  }

  /// The same lines, in words a screen reader can say (M4.15 W6).
  ///
  /// **One builder, two renderings, and that is the point.** Which columns
  /// produce which line is a BR-242 question and must be stated once; only the
  /// phrasing differs, so the spoken form is a flag rather than a second
  /// function that could drift from this one the first time a field is added.
  List<String> cardHistoryScheduleLinesSemantics(CardHistoryEventModel event) =>
      _scheduleLines(
        event,
        spoken: true,
      ).map((line) => line.text).toList(growable: false);

  /// The stage name, spoken.
  ///
  /// Differs from [cardHistoryMode] only for [StudyMode.unknown]: the visible
  /// line shows the same en dash an unrecorded column uses, and a lone en dash
  /// inside a spoken sentence is a silent gap that reads as data that failed to
  /// load.
  String cardHistoryModeSemantics(StudyMode mode) => mode == StudyMode.unknown
      ? l10n.cardHistoryModeUnknownSemantics
      : cardHistoryMode(mode);

  List<CardHistoryScheduleLine> _scheduleLines(
    CardHistoryEventModel event, {
    required bool spoken,
  }) {
    String box(String from, String to) => spoken
        ? l10n.cardHistoryBoxChangeSemantics(from, to)
        : l10n.cardHistoryBoxChange(from, to);
    String ease(String from, String to) => spoken
        ? l10n.cardHistoryEaseChangeSemantics(from, to)
        : l10n.cardHistoryEaseChange(from, to);
    String interval(String from, String to) => spoken
        ? l10n.cardHistoryIntervalChangeSemantics(from, to)
        : l10n.cardHistoryIntervalChange(from, to);
    final absent = spoken ? l10n.cardHistoryAbsentValueSemantics : _absentValue;

    final lines = <CardHistoryScheduleLine>[
      if (event.previousBox != null || event.nextBox != null)
        CardHistoryScheduleLine(
          box(
            _number(event.previousBox, absent),
            _number(event.nextBox, absent),
          ),
          isProgression: true,
        ),
      if (event.previousEaseFactor != null || event.nextEaseFactor != null)
        CardHistoryScheduleLine(
          ease(
            _ease(event.previousEaseFactor, absent),
            _ease(event.nextEaseFactor, absent),
          ),
          isProgression: true,
        ),
      if (event.previousIntervalDays != null || event.nextIntervalDays != null)
        CardHistoryScheduleLine(
          interval(
            _days(event.previousIntervalDays, absent),
            _days(event.nextIntervalDays, absent),
          ),
          isProgression: true,
        ),
      if (event.nextDueAt != null)
        CardHistoryScheduleLine(
          l10n.cardHistoryNextDueLabel(cardHistoryDate(event.nextDueAt!)),
        ),
    ];
    // Said, not left blank: a learning turn records history and moves no
    // schedule (BR-144), and an event with no lines under it reads as data that
    // failed to load rather than as the normal shape of that turn.
    if (lines.isEmpty) {
      return <CardHistoryScheduleLine>[
        CardHistoryScheduleLine(l10n.cardHistoryScheduleUnchanged),
      ];
    }

    return lines;
  }

  /// The marks a turn carries beyond its action (BR-131, BR-136).
  ///
  /// The outcome goes through a `switch` on the value rather than a null check:
  /// `StudyOutcomeReason` has one member today, so "not null" and "timed out"
  /// happen to agree — and the day a second reason is stored, BR-242 says the
  /// row's own value is what shows. A null check would silently label it
  /// `Timed out`; the switch fails the build instead.
  List<String> cardHistoryMarks(CardHistoryEventModel event) {
    final outcome = event.outcomeReason;
    final marks = <String>[];
    if (outcome != null) {
      marks.add(switch (outcome) {
        StudyOutcomeReason.timeout => l10n.cardHistoryTimedOutLabel,
      });
    }
    if (event.usedHint ?? false) marks.add(l10n.cardHistoryHintUsedLabel);

    return marks;
  }

  /// A half of a before→after pair that the row left null.
  ///
  /// [absent] rather than `0`: a null column means the scheduler did not record
  /// that side, and printing a zero would claim a value the row does not hold.
  /// It is passed in because the drawn form is an en dash and the spoken form
  /// is a phrase.
  String _number(int? value, String absent) => value?.toString() ?? absent;

  String _days(int? value, String absent) =>
      value == null ? absent : l10n.cardDetailDayCount(value);

  /// Two decimals, which is the resolution SM-2's ease factor is reasoned about
  /// at; the raw double would print a long tail nobody can compare at a glance.
  String _ease(double? value, String absent) =>
      value?.toStringAsFixed(2) ?? absent;
}

/// The stand-in for a side of a pair the row did not record.
///
/// A named constant, not a literal in four places, and not an ARB string: an en
/// dash is punctuation and reads the same in every language this app ships.
const String _absentValue = '–';

/// One before→after line of an event's schedule, and whether it is the card
/// *moving along its ladder*.
///
/// **A flag rather than the widget matching on the text.** Only the progression
/// lines — `Box 2 → 3`, an ease or an interval change — are drawn in the accent;
/// `Next due` and `Schedule unchanged` are facts about the timetable, not steps
/// forward, and colouring them the same would spend the accent on every line and
/// so on none. Which line is which is a BR-242 question, so it is answered where
/// the lines are built.
@immutable
class CardHistoryScheduleLine {
  const CardHistoryScheduleLine(this.text, {this.isProgression = false});

  final String text;
  final bool isProgression;
}
