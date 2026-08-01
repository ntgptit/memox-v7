import '../../domain/repositories/review_repository.dart';

/// Drift-backed implementation of [ReviewRepository].
///
/// Structural anchor for `features/review/data/`. It carries no methods yet
/// because the contract carries none; both grow together in M4.5 and M4.6.
///
/// When it does grow, this class is the boundary where Drift exceptions become
/// a domain `Failure` — nothing above it may see a `DriftWrappedException`.
final class ReviewRepositoryImpl implements ReviewRepository {
  const ReviewRepositoryImpl();
}
