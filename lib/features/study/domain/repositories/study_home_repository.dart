import '../models/study_day_model.dart';
import '../models/study_home_model.dart';

/// The Study tab's read, and only its read (BR-200).
///
/// **A contract of its own rather than two more methods on `StudyRepository`.**
/// That one owns a session's whole life — opening it, serving turns, grading
/// them, ending it — and every method on it writes or feeds a write. This one
/// cannot write at all, and saying so in the type is what makes "entering the
/// Study tab touches nothing" checkable instead of a promise in a comment: a
/// screen holding only this has no method to call that would create a session.
///
/// Pure Dart, like every other contract here (AD-01): no Flutter, no Drift.
abstract interface class StudyHomeRepository {
  /// Everything the Study tab shows, watched as one snapshot (AD-13).
  ///
  /// **Watched, not read once.** Finishing a session, answering a card, adding
  /// a deck and deleting one all change what belongs on this screen, and a list
  /// that only re-read on navigation would keep showing the counts of a session
  /// the user has just walked out of.
  ///
  /// **[day] rather than three loose instants.** The read needs `now` for the
  /// due predicate (AD-06), the start of the local day to split overdue from
  /// due-today (BR-162) and to reject a session an earlier study day left open
  /// (BR-103), and the *next* local midnight so the screen knows when its own
  /// split expires (BR-161). All three are one calculation over one clock
  /// reading; passing them separately lets a caller mix a `now` from one instant
  /// with a midnight derived from another, which is a card in the wrong half of
  /// a partition that is supposed to be exact.
  ///
  /// `domain/` may read neither the wall clock nor the device timezone, so both
  /// enter [StudyDayModel] from the composition root (AD-06, AD-16).
  Stream<StudyHomeModel> watchStudyHome(StudyDayModel day);
}
