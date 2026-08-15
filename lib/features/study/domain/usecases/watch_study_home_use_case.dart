import '../models/study_day_model.dart';
import '../models/study_home_model.dart';
import '../repositories/study_home_repository.dart';

/// What the Study tab shows, from the moment it is measured against (BR-200).
///
/// **A thin use case, and deliberately one** (AD-12). It holds one piece of
/// logic — turning `now` and the device's UTC offset into the study day BR-105
/// defines — and that is exactly the piece no caller should be repeating. A
/// controller computing its own midnight is a second implementation of a
/// calculation `StudyDayModel` already owns, and two of them is how one screen
/// says "due today" while another says "1 day overdue" about the same card.
///
/// It **cannot** open a session: the contract it holds has no method that writes
/// (BR-101). Entering the tab, scrolling it and leaving it again touch nothing.
class WatchStudyHomeUseCase {
  const WatchStudyHomeUseCase(this._repository);

  final StudyHomeRepository _repository;

  Stream<StudyHomeModel> call({
    required DateTime now,
    required Duration utcOffset,
  }) =>
      _repository.watchStudyHome(StudyDayModel(now: now, utcOffset: utcOffset));
}
