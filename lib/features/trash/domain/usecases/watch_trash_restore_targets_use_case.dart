import '../models/trash_restore_target_model.dart';
import '../repositories/trash_repository.dart';

/// Where one batch may be restored to (BR-261).
///
/// A stream, because the tree can change under an open picker — a target
/// deleted elsewhere must leave the list rather than be tapped and refused.
class WatchTrashRestoreTargetsUseCase {
  const WatchTrashRestoreTargetsUseCase(this._repository);

  final TrashRepository _repository;

  Stream<List<TrashRestoreTarget>> call(String batchId) =>
      _repository.watchRestoreTargets(batchId);
}
