import '../models/study_mode.dart';
import '../models/study_session_kind_model.dart';
import '../models/study_session_start_model.dart';
import '../repositories/study_repository.dart';
import 'resume_study_session_use_case.dart';
import 'start_study_session_use_case.dart';

/// Opens the deck's session — the one already running, or a new one (BR-103).
///
/// **The choice belongs here, not in the controller.** Both arms end with the
/// same four facts — session, scheduler, actions, card set — so a screen holding
/// the `if` was a screen that knew there were two ways to get them, and any
/// difference between the arms was a difference it had to keep in step.
///
/// [shouldResume] is the caller's intent, taken from the route: Resume was
/// offered because a session was open, and this is what acts on it. The other
/// parameters describe the session that would be started if it were not.
///
/// [resumeSessionId] names *which* open session, when the caller offered a
/// particular one. Null means "whichever is open for this deck", which is right
/// only for a caller that never named one — see [ResumeStudySessionUseCase].
final class OpenStudySessionUseCase {
  const OpenStudySessionUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudySessionStartModel> call({
    required String deckId,
    required StudySessionKind kind,
    required DateTime now,
    required Duration utcOffset,
    StudyMode? reviewMode,
    bool shouldResume = false,
    String? resumeSessionId,
  }) => shouldResume
      ? ResumeStudySessionUseCase(_repository).call(
          deckId,
          sessionId: resumeSessionId,
          // Passed through so the resume can re-check BR-103's study day at the
          // moment of the tap, not only at the moment the list was drawn.
          now: now,
          utcOffset: utcOffset,
        )
      : StartStudySessionUseCase(_repository).call(
          deckId: deckId,
          kind: kind,
          reviewMode: reviewMode,
          now: now,
          utcOffset: utcOffset,
        );
}
