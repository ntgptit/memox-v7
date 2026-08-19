import '../repositories/trash_repository.dart';

/// Deletes the selected batches for good (BR-265, BR-266).
class PurgeTrashBatchesUseCase {
  const PurgeTrashBatchesUseCase(this._repository);

  final TrashRepository _repository;

  Future<void> call(List<String> batchIds) => _repository.purge(batchIds);
}
