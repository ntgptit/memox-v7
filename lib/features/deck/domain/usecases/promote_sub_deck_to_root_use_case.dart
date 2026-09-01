import '../models/scheduler_type_model.dart';
import '../repositories/deck_repository.dart';

/// Promotes a branch into a new root with an explicitly chosen scheduler.
class PromoteSubDeckToRootUseCase {
  const PromoteSubDeckToRootUseCase(this._repository);

  final DeckRepository _repository;

  Future<void> call({
    required String deckId,
    required SchedulerType schedulerType,
  }) => _repository.promoteSubDeckToRoot(
    deckId: deckId,
    schedulerType: schedulerType,
  );
}
