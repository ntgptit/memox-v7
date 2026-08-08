import '../models/study_turn_model.dart';
import '../repositories/study_repository.dart';

/// The card to put in front of the user next.
///
/// Null does **not** mean the session is over: it also means every remaining
/// card is waiting out BR-26's three-card gap. `AdvanceStudyStageUseCase` is
/// what tells the two apart, and keeping them apart is what stops a session
/// ending three cards early.
class GetNextTurnUseCase {
  const GetNextTurnUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudyTurnModel?> call(String sessionId) =>
      _repository.nextTurn(sessionId);
}
