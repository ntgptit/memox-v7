import '../models/study_mode.dart';
import '../repositories/study_repository.dart';

/// Suspends a turn without ending it (BR-133).
///
/// A `recall` turn interrupted at four seconds resumes at four seconds. Handing
/// back a fresh twenty would return time the user already spent, and hiding an
/// answer they had already seen would ask them to un-know it.
class SaveTurnProgressUseCase {
  const SaveTurnProgressUseCase(this._repository);

  final StudyRepository _repository;

  Future<void> call({
    required String sessionId,
    required StudyMode mode,
    required String cardId,
    int? remainingMs,
    bool isRevealed = false,
  }) => _repository.saveTurnProgress(
    sessionId: sessionId,
    mode: mode,
    cardId: cardId,
    remainingMs: remainingMs,
    isRevealed: isRevealed,
  );
}
