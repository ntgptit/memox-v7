import '../entities/study_session_entity.dart';
import '../models/study_day_model.dart';
import '../repositories/study_repository.dart';

/// What the app does with a session it finds still open (BR-103).
///
/// **Two different situations, and the difference is the study day.** A session
/// from *today* is one the user may still want to continue — the app offers it
/// back. A session from an earlier day is over whether or not anybody said so,
/// and it closes as `abandoned`/`interrupted`.
///
/// `interrupted` rather than `user_exit`, for the reason BR-76 stores `kind`
/// instead of deriving it: the user did not leave, the app did, and merging the
/// two makes the history say somebody gave up when they did not.
///
/// One call rather than "close the stale ones, then look for an open one": the
/// second read has to happen after the first write, and splitting them lets a
/// caller do it in the wrong order and offer to resume a session it just closed.
class ResumeStudyDayUseCase {
  const ResumeStudyDayUseCase(this._repository);

  final StudyRepository _repository;

  /// Returns today's still-open session for [deckId], if there is one.
  Future<StudySessionEntity?> call({
    required String deckId,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final dayStart = StudyDayModel(now: now, utcOffset: utcOffset).startOfToday;

    await _repository.abandonStaleSessions(dayStart: dayStart);

    return _repository.openSessionFor(deckId);
  }
}
