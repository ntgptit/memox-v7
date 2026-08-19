import '../models/trash_restore_target_model.dart';
import '../repositories/trash_repository.dart';

/// Restores one batch into a chosen target (BR-261, BR-262).
///
/// No validation here: the repository re-checks every rule inside the
/// transaction, and a copy of those checks above it would be a second rule set
/// running against an older snapshot.
class RestoreTrashBatchUseCase {
  const RestoreTrashBatchUseCase(this._repository);

  final TrashRepository _repository;

  Future<void> call({
    required String batchId,
    required TrashRestoreTarget target,
  }) => _repository.restore(batchId: batchId, target: target);
}
