import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../domain/models/progress_overview_model.dart';
import '../providers/progress_use_case_provider.dart';
import 'progress_now_controller.dart';

part 'progress_overview_controller.g.dart';

/// The longest a midnight timer may wait before it re-measures anyway.
///
/// **Not a poll interval.** The delay comes from the data — the local midnight
/// the emission carried — and this is only a ceiling on it, for the mechanical
/// reason `kMaxDueBoundaryDelay` states: on the web a `Timer` is `setTimeout`,
/// whose delay is a 32-bit signed millisecond count, so anything past about 24.8
/// days fires immediately and turns one scheduled wake into a busy loop.
///
/// A day plus an hour, rather than exactly a day: the next midnight is always
/// less than 24 hours away, so this ceiling can never be what fires, and leaving
/// slack means a clock nudged forward by an NTP correction does not clip it.
const Duration kMaxProgressMidnightDelay = Duration(hours: 25);

/// The learner's progress overview, with a refresh scheduled for the moment it
/// expires (UC-12).
///
/// **The timer, and why it is one timer and not a schedule.** Each emission
/// carries `nextLocalMidnight` — the instant its own window stops being today —
/// from the same snapshot as the counts (BR-184). A single one-shot timer is
/// armed for that instant; when it fires it moves [progressNowProvider], the
/// stream re-opens at the new local day, and the next emission arms the next
/// timer. So the wake-up follows the data instead of a fixed interval, and there
/// is never more than one pending.
///
/// The timer is armed in `listenSelf` rather than inside a `map`, because arming
/// it is a side effect and a `map` is not where side effects belong. It is
/// cancelled by an `onDispose` registered in the same build, which Riverpod runs
/// both on disposal *and* before a rebuild — that is what keeps a rebuild from
/// leaving the previous timer pending. Nothing here is global: this notifier is
/// `autoDispose`, so leaving the tab cancels its timer with it.
///
/// **Answers arriving while the screen is open need no timer at all.** The
/// repository's stream re-emits on its own when history changes (BR-189), and
/// `MxAsyncView` keeps the previous value on screen during a refresh, so a new
/// answer updates the numbers in place rather than flashing a spinner.
///
/// Automatic retry is off — see `noAutomaticRetry`: while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin instead of showing
/// its error state, and the user would never reach the `Retry` that UC-12 E1
/// promises.
@Riverpod(retry: noAutomaticRetry)
class ProgressOverviewController extends _$ProgressOverviewController {
  /// At most one pending wake-up, ever. Held on the notifier rather than in the
  /// build closure so cancelling it does not depend on which closure won a race.
  Timer? _midnightTimer;

  /// The past-or-equal midnight an immediate refresh has already been armed for,
  /// or `null` when the last emission carried a future one.
  ///
  /// This is the loop guard. A stale emission triggers one immediate refresh and
  /// records its boundary here; a repository that re-emits the *same* past
  /// boundary then finds it already recorded and does not arm again. Without it,
  /// a clock that is behind the boundary by a rounding error re-arms forever.
  DateTime? _immediateRefreshBoundary;

  @override
  Stream<ProgressOverview> build() {
    ref.onDispose(_cancelMidnight);
    listenSelf(_armMidnight);

    return ref.watch(watchProgressOverviewUseCaseProvider)(
      now: ref.watch(progressNowProvider),
      // Resolved per build, so a device that changed zone or season re-reads
      // with the new offset the next time anything moves `progressNowProvider`
      // — which the resume hook already does.
      utcOffset: ref.watch(utcOffsetProvider)(),
    );
  }

  /// Re-arms the wake-up from the emission that just landed.
  void _armMidnight(
    AsyncValue<ProgressOverview>? _,
    AsyncValue<ProgressOverview> next,
  ) {
    // Cancel first, unconditionally: exactly one timer may be outstanding, and
    // re-arming without cancelling is how two of them end up racing.
    //
    // What happens next depends on whether there is still a snapshot to wake up
    // for. Riverpod builds an `AsyncError` with `copyWithPrevious`, so an error
    // that lands *after* a value keeps that value — `boundary` is then the old
    // snapshot's midnight, and the timer is re-armed from it. That is correct
    // rather than an oversight: local midnight is a property of the clock, not
    // of the read that failed, and the screen showing stale numbers over an
    // error is exactly the screen that must re-read when the day rolls over. An
    // error with no previous value has no boundary, and arms nothing.
    _cancelMidnight();

    final DateTime? boundary = next.value?.nextLocalMidnight;
    if (boundary == null) {
      _immediateRefreshBoundary = null;
      return;
    }

    final Duration delay = boundary.difference(ref.read(clockProvider)());

    if (delay > Duration.zero) {
      _immediateRefreshBoundary = null;
      _midnightTimer = Timer(
        delay < kMaxProgressMidnightDelay ? delay : kMaxProgressMidnightDelay,
        ref.read(progressNowProvider.notifier).refresh,
      );
      return;
    }

    // `delay <= 0`: midnight was already behind by the time this emission was
    // processed — the app was suspended across it, or the read took longer than
    // the gap. Refresh now, so the window is re-opened at the day the user is
    // actually in, rather than leaving yesterday on screen until something else
    // happens.
    //
    // Guarded so it cannot spin: recorded once per boundary, and refused for a
    // boundary already chased. A healthy repository answers the re-opened query
    // with a later midnight, so this fires at most once per real crossing.
    if (_immediateRefreshBoundary == boundary) return;
    _immediateRefreshBoundary = boundary;
    _midnightTimer = Timer(
      Duration.zero,
      ref.read(progressNowProvider.notifier).refresh,
    );
  }

  void _cancelMidnight() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
  }
}
