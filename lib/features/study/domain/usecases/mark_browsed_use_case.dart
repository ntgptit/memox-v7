import '../repositories/study_repository.dart';

/// Moves past a card in the one mode that grades nothing (BR-111, BR-28).
///
/// `browse` produces no action, and `study_answers.mode` cannot even hold the
/// value — so without this its queue never empties and the first stage of every
/// learning session runs forever.
class MarkBrowsedUseCase {
  const MarkBrowsedUseCase(this._repository);

  final StudyRepository _repository;

  Future<void> call({required String sessionId, required String cardId}) =>
      _repository.markBrowsed(sessionId: sessionId, cardId: cardId);
}
