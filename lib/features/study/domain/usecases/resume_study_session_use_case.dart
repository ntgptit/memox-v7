import '../../../../core/error/failure.dart';
import '../models/study_scheduler.dart';
import '../models/study_session_start_model.dart';
import '../repositories/study_repository.dart';

/// Picks up a session left open, instead of opening a new one (BR-103).
///
/// **Same shape as starting one**, on purpose: the screen renders a session, and
/// it should not care whether that session is one second or one hour old. What
/// differs is only that nothing is created — the queue, the cursor and any
/// `remaining_ms` are exactly as they were left (BR-133).
class ResumeStudySessionUseCase {
  const ResumeStudySessionUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudySessionStartModel> call(String deckId) async {
    final session = await _repository.openSessionFor(deckId);
    if (session == null) {
      throw const NotFoundFailure(message: 'No session to resume');
    }

    final context = await _repository.deckContext(deckId);
    final scheduler = schedulerFor(context.schedulerType);
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
      );
    }

    return StudySessionStartModel(
      session: session,
      schedulerType: context.schedulerType,
      actions: scheduler.supportedActions,
      cards: await _repository.sessionCards(session.id),
    );
  }
}
