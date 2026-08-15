import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../di/study_home_repository_provider.dart';
import '../../domain/models/study_home_model.dart';
import '../../domain/usecases/watch_study_home_use_case.dart';
import 'study_home_now_controller.dart';

part 'study_home_controller.g.dart';

/// The longest a boundary timer may wait before it re-measures anyway.
///
/// **Not a poll interval.** The delay comes from the data — the next instant a
/// card becomes due, or the next local midnight — and this is only a ceiling on
/// it, for one mechanical reason: on the web a `Timer` is `setTimeout`, whose
/// delay is a 32-bit signed millisecond count, so anything past about 24.8 days
/// fires immediately and turns one scheduled wake into a busy loop. Web is the
/// E2E channel, so the arithmetic has to be safe there.
///
/// The twin of `kMaxDueBoundaryDelay` in the deck list, and deliberately a
/// second constant rather than an import: `features/deck/presentation/` is
/// exactly what a feature may not reach into. Extracting the shared mechanism
/// into `core/` is recorded as follow-up work rather than done here, because it
/// would rewrite a controller this change has no other reason to touch.
const Duration kMaxStudyHomeBoundaryDelay = Duration(days: 1);

/// Everything the Study tab shows, with a refresh scheduled for the moment its
/// counts expire (UC-14, BR-200).
///
/// A **query** controller: it reports what the data layer says and holds no
/// command. That is not a style choice here — the contract it reads has no
/// method that writes, so entering the tab cannot open a session (BR-101).
/// Starting one is the session screen's job, reached only by a tap.
///
/// **The timer, and why it is one timer and not a schedule.** Each emission
/// carries the two instants that expire it: the next card to become due, and the
/// next local midnight at which today's due cards become overdue (BR-162). One
/// one-shot is armed for the earlier of the two; when it fires it moves
/// [studyHomeNowProvider], the stream re-opens at the new `now`, and the next
/// emission arms the next timer. Wake-ups follow the data rather than an
/// interval, and a library with nothing scheduled has none at all.
///
/// Automatic retry is off — see `noAutomaticRetry`: while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin for thirteen
/// seconds instead of showing the error state that offers a retry.
@Riverpod(retry: noAutomaticRetry)
class StudyHome extends _$StudyHome {
  /// At most one pending wake-up, ever. Held on the notifier rather than in a
  /// build closure so cancelling it does not depend on which closure won a race.
  Timer? _boundaryTimer;

  /// The past-or-equal boundary an immediate refresh has already been armed for,
  /// or null when the last emission carried a future or absent one.
  ///
  /// The loop guard: a stale emission triggers one immediate refresh and records
  /// its boundary; a repository re-emitting the *same* past boundary then finds
  /// it recorded and does not arm again.
  DateTime? _immediateRefreshBoundary;

  @override
  Stream<StudyHomeModel> build() {
    ref.onDispose(_cancelBoundary);
    listenSelf(_armBoundary);

    return WatchStudyHomeUseCase(ref.watch(studyHomeRepositoryProvider)).call(
      now: ref.watch(studyHomeNowProvider),
      // Resolved per build, so a device that changed zones re-reads with the new
      // offset the next time anything moves `studyHomeNowProvider` — which the
      // resume hook already does.
      utcOffset: ref.watch(utcOffsetProvider)(),
    );
  }

  /// Re-arms the wake-up from the emission that just landed.
  void _armBoundary(
    AsyncValue<StudyHomeModel>? _,
    AsyncValue<StudyHomeModel> next,
  ) {
    // Cancel first, unconditionally. An emission carrying no boundary must also
    // clear the timer armed for the previous one — otherwise deleting the last
    // scheduled card leaves a wake-up behind for a card that is gone.
    _cancelBoundary();

    final DateTime? boundary = _earliestBoundary(next.value);
    if (boundary == null) {
      _immediateRefreshBoundary = null;
      return;
    }

    final Duration delay = boundary.difference(ref.read(clockProvider)());

    if (delay > Duration.zero) {
      _immediateRefreshBoundary = null;
      _boundaryTimer = Timer(
        delay < kMaxStudyHomeBoundaryDelay ? delay : kMaxStudyHomeBoundaryDelay,
        ref.read(studyHomeNowProvider.notifier).refresh,
      );
      return;
    }

    // The clock reached the boundary before this emission was processed, so it
    // was crossed with no timer to catch it. Re-open the query at the new `now`
    // rather than dropping the update until the next resume — guarded so it
    // cannot spin: a healthy read answers `due_at > now` with a later boundary
    // or none, so this fires at most once per real crossing.
    if (_immediateRefreshBoundary == boundary) return;
    _immediateRefreshBoundary = boundary;
    _boundaryTimer = Timer(
      Duration.zero,
      ref.read(studyHomeNowProvider.notifier).refresh,
    );
  }

  /// The earlier of the snapshot's two expiry instants, or null when it carries
  /// neither.
  ///
  /// **Both, not just `nextDueAt`.** That one goes null exactly when every
  /// scheduled card is already due — which is precisely when the overdue split
  /// still has to move at midnight, with no database write anywhere (BR-161).
  static DateTime? _earliestBoundary(StudyHomeModel? snapshot) {
    final DateTime? dueAt = snapshot?.nextDueAt;
    final DateTime? tickAt = snapshot?.nextOverdueTickAt;
    if (dueAt == null) return tickAt;
    if (tickAt == null) return dueAt;

    return dueAt.isBefore(tickAt) ? dueAt : tickAt;
  }

  void _cancelBoundary() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
  }
}
