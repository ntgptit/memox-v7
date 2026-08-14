import '../entities/trash_batch_entity.dart';
import '../repositories/trash_repository.dart';

/// The Trash list (UC-12 step 3).
class WatchTrashBatchesUseCase {
  const WatchTrashBatchesUseCase(this._repository);

  final TrashRepository _repository;

  Stream<List<TrashBatchEntity>> call() => _repository.watchBatches();
}
