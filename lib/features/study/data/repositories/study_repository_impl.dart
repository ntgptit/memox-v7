import '../../domain/repositories/study_repository.dart';

/// Drift-backed implementation of [StudyRepository].
///
/// Deliberately still empty. The contract landed with M5.0's domain half so the
/// use cases of M5.2 have something to be written against; the implementation is
/// the second half of M5.0 and arrives with its own tests.
///
/// Leaving the class here rather than deleting it keeps
/// `architecture_boundary_test.dart`'s pairing of contract and implementation
/// intact — and when it does grow, this class is the boundary where a Drift
/// exception becomes a domain `Failure`. Nothing above it may see a
/// `DriftWrappedException`.
final class StudyRepositoryImpl {
  const StudyRepositoryImpl();
}
