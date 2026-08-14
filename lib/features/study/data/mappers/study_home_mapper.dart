import '../../../../core/database/app_database.dart';
import '../../../deck/domain/models/scheduler_type_model.dart';
import '../../domain/models/study_day_model.dart';
import '../../domain/models/study_home_deck_model.dart';
import '../../domain/models/study_home_model.dart';
import '../../domain/models/study_home_resume_model.dart';
import '../../domain/models/study_mode.dart';
import '../../domain/models/study_session_kind_model.dart';

/// Drift rows in, Study Home's read model out. Nothing Drift-shaped crosses
/// (AD-01).
///
/// Enums go through their own `fromDbValue`, which is where each decides whether
/// an unrecognised value degrades or throws; repeating that decision here would
/// give one stored value two behaviours depending on which read reached it.
StudyHomeModel studyHomeFromRows({
  required List<StudyHomeRootWorkloadResult> rows,
  required StudyHomeResumeCandidateResult? resume,
  required StudyDayModel day,
}) {
  final decks = rows.map(_deckFromRow).toList()..sort(compareStudyHomeDecks);

  return StudyHomeModel(
    resume: resume == null ? null : _resumeFromRow(resume),
    decks: List<StudyHomeDeckModel>.unmodifiable(decks),
    // Every row carries the same scalar subquery, so any row answers it; an
    // empty library has no row and nothing scheduled, which is the same null.
    nextDueAt: rows.isEmpty ? null : rows.first.nextDueAt?.toUtc(),
    nextOverdueTickAt: _overdueTickFor(
      decks,
      hasResume: resume != null,
      day: day,
    ),
  );
}

StudyHomeDeckModel _deckFromRow(StudyHomeRootWorkloadResult row) {
  final schedulerType = row.schedulerType;

  return StudyHomeDeckModel(
    deckId: row.deckId,
    deckName: row.deckName,
    // NULL is not a scheduler this build has not heard of — it is a column a
    // root deck should never leave empty (BR-06). Either way the row is listed
    // and the label is withheld rather than invented.
    schedulerType: schedulerType == null
        ? SchedulerType.unknown
        : SchedulerType.fromDbValue(schedulerType),
    totalCardCount: row.totalCardCount,
    newCount: row.newCount,
    overdueCount: row.overdueCount,
    dueTodayCount: row.dueTodayCount,
  );
}

StudyHomeResumeModel _resumeFromRow(StudyHomeResumeCandidateResult row) =>
    StudyHomeResumeModel(
      sessionId: row.sessionId,
      deckId: row.deckId,
      deckName: row.deckName,
      kind: StudySessionKind.fromDbValue(row.sessionKind),
      currentMode: StudyMode.fromDbValue(row.currentMode),
    );

/// The next local midnight, or null when nothing on the screen expires at it.
///
/// **Computed here rather than in the widget**, for the reason AD-16 gives: the
/// read layer owns `now` and the UTC offset, so this is the one place the
/// calendar arithmetic can run and be tested, and `lib/features/` may not read a
/// clock. A screen handed the raw instants would have to.
///
/// **Two things expire at midnight, not one.** The due split is the obvious one
/// (BR-161): today's due cards become overdue with no write anywhere. The other
/// is the Resume card, and it was missed. BR-182 offers a session back only
/// while it belongs to the *current* study day, and that window closes at the
/// same boundary — so a library with an open `learning` session and nothing due
/// armed no timer at all (`nextDueAt` is null when every card is unlearned,
/// because an unlearned card has no `due_at`), and a tab left open across
/// midnight kept offering a session BR-103 had already made stale.
///
/// Null only when *neither* applies, because then the boundary changes nothing
/// and a timer set for it would wake the screen to re-read the same zeroes.
DateTime? _overdueTickFor(
  List<StudyHomeDeckModel> decks, {
  required bool hasResume,
  required StudyDayModel day,
}) {
  final hasDue = decks.any((deck) => deck.dueCount > 0);
  if (!hasDue && !hasResume) return null;

  return day.startOfDayAfter(1);
}
