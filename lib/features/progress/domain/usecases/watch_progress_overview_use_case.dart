import '../models/progress_overview_model.dart';
import '../repositories/progress_repository.dart';

/// Watches the learner's progress overview (UC-12).
///
/// **One use case for one interaction, and only one.** Opening Progress is a
/// single activity — "how am I doing" — so it gets a single read returning
/// streak, today and the week together (AD-13). Splitting it into
/// `WatchStreakUseCase` and `WatchTodayUseCase` would let a controller compose
/// two snapshots and render one number from before a write and another from
/// after it, which is exactly the class of bug AD-13 exists to prevent.
///
/// Thin, and accepted as such: AD-12 asks for a use case per interaction so a
/// new feature is a clone rather than a judgement call at every operation. The
/// value is not logic here — it is that `presentation/` names a use case and
/// never a repository.
///
/// [now] and [utcOffset] are passed in explicitly rather than read here. A use
/// case that read the clock could not be tested at 23:59, and nothing under
/// `lib/features/` reads the wall clock at all — every instant arrives from
/// `clockProvider` at the composition root (AD-06, AD-16).
class WatchProgressOverviewUseCase {
  const WatchProgressOverviewUseCase(this._repository);

  final ProgressRepository _repository;

  Stream<ProgressOverview> call({
    required DateTime now,
    required Duration utcOffset,
  }) => _repository.watchProgressOverview(now: now, utcOffset: utcOffset);
}
