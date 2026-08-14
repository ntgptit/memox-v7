import '../repositories/trash_repository.dart';

/// Deletes the selected batches for good (BR-191, BR-192).
class PurgeTrashBatchesUseCase {
  const PurgeTrashBatchesUseCase(this._repository);

  final TrashRepository _repository;

  Future<void> call(List<String> batchIds) => _repository.purge(batchIds);
}
