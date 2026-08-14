import '../repositories/trash_repository.dart';

/// Reverses the deletion just made (BR-189).
///
/// **Not a restore with a default target.** Undo asks nothing and writes to the
/// place the tombstone still points at; the repository refuses with its own
/// reason when that place no longer qualifies, so the copy can point at Trash
/// rather than explain a choice the user never made.
class UndoDeleteUseCase {
  const UndoDeleteUseCase(this._repository);

  final TrashRepository _repository;

  Future<void> call(String batchId) => _repository.undo(batchId);
}
