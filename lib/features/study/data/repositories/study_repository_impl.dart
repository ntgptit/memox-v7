import '../../domain/repositories/study_repository.dart';

/// Drift-backed implementation of [StudyRepository].
///
/// Structural anchor for `features/study/data/`. It carries no methods yet
/// because the contract carries none; both grow together in M4.5 and M4.6.
///
/// When it does grow, this class is the boundary where Drift exceptions become
/// a domain `Failure` — nothing above it may see a `DriftWrappedException`.
final class StudyRepositoryImpl implements StudyRepository {
  const StudyRepositoryImpl();
}
