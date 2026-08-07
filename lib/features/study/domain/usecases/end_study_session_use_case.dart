import '../models/study_session_status_model.dart';
import '../repositories/study_repository.dart';

/// Closes a session that did not simply run out of queue (UC-05, BR-82…BR-85).
///
/// **The reason is the caller's to supply, and the matrix is what checks it.**
/// A single `abandon()` would have to guess between `user_exit` and
/// `interrupted`, and BR-103 makes that difference real: one says the user chose
/// to stop, the other says the operating system took the app away.
///
/// Turns already recorded stay recorded, in every ending (BR-86). Nothing here
/// touches `study_answers`, and that is the entire guarantee.
class EndStudySessionUseCase {
  const EndStudySessionUseCase(this._repository);

  final StudyRepository _repository;

  Future<void> call({
    required String sessionId,
    required StudySessionStatus status,
    required StudySessionEndReason? reason,
    required DateTime now,
  }) => _repository.endSession(
    sessionId: sessionId,
    status: status,
    reason: reason,
    endedAt: now,
  );
}
