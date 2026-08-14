import '../repositories/trash_repository.dart';

/// The retention sweep (BR-190).
///
/// [now] is a parameter rather than a clock read, so the thirty-day boundary is
/// testable from both sides and no layer below the composition root owns "now"
/// (AD-06).
class PurgeExpiredTrashUseCase {
  const PurgeExpiredTrashUseCase(this._repository);

  final TrashRepository _repository;

  Future<int> call(DateTime now) => _repository.purgeExpired(now);
}
