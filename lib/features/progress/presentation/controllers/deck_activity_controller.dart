import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/clock_provider.dart';
import '../../../../core/time/time_zone_provider.dart';
import '../../domain/models/deck_activity_snapshot_model.dart';
import '../providers/progress_use_case_provider.dart';
import 'progress_now_controller.dart';

part 'deck_activity_controller.g.dart';

/// The longest a day-boundary timer may wait before it re-measures anyway.
///
/// **Not a poll interval.** The delay comes from the data — the next local
/// midnight — and this is only a ceiling on it, for the mechanical reason
/// `kMaxDueBoundaryDelay` states: on the web a `Timer` is `setTimeout`, whose
/// delay is a 32-bit signed millisecond count, so anything past about 24.8 days
/// fires immediately and turns one scheduled wake into a busy loop. Web is the
/// E2E channel, so the arithmetic has to be safe there.
///
/// A day is far inside that limit and is itself the longest gap this screen can
/// legitimately wait, so in practice the ceiling is never what fires.
const Duration kMaxProgressBoundaryDelay = Duration(days: 1);

/// One level of Progress by Deck, with a refresh scheduled for the moment its
/// windows expire (UC-12).
///
/// **`family` on the deck id, and that is the whole unification.** The library
/// level is this notifier with `null`; a deck's own level is the same notifier
/// with an id. One notifier cannot drift from itself, which is the failure the
/// deck tree had to be repaired from — two screens answering one question with
/// different amounts of information.
///
/// The family also means drilling into a deck does not disturb the level above
/// it, which matters because the shell keeps the branch alive behind a pushed
/// route.
///
/// **The timer, and why it is one timer.** Every windowed figure on this screen
/// expires at the next local midnight with no database write behind it: at 00:00
/// the oldest day leaves the window and today becomes a day with nothing in it
/// yet. The snapshot carries that instant from the same read as the figures; a
/// single one-shot timer is armed for it, and when it fires it moves
/// [progressNowProvider], every level re-reads, and the next emission arms the
/// next timer. So the wake-ups follow the data instead of a fixed interval, and
/// there is never more than one pending per level.
///
/// The timer is armed in `listenSelf` rather than inside the stream, because
/// arming it is a side effect and a `map` is not where side effects belong. It is
/// cancelled by an `onDispose` registered in the same build, which Riverpod runs
/// both on disposal *and* before a rebuild — that is what keeps a rebuild from
/// leaving the previous timer pending. This notifier is `autoDispose`, so leaving
/// the level cancels its timer with it.
///
/// Automatic retry is off — see `noAutomaticRetry`: while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin instead of showing
/// its error state and its retry action.
@Riverpod(retry: noAutomaticRetry)
class DeckActivityLevel extends _$DeckActivityLevel {
  /// At most one pending wake-up per level, ever. Held on the notifier rather
  /// than in the build closure so cancelling it does not depend on which closure
  /// won a race.
  Timer? _boundaryTimer;

  /// The past-or-equal boundary an immediate refresh has already been armed for,
  /// or `null` when the last emission carried a future one.
  ///
  /// The loop guard. A stale emission triggers one immediate refresh and records
  /// its boundary here; a repository that re-emits the *same* past boundary then
  /// finds it already recorded and does not arm again.
  DateTime? _immediateRefreshBoundary;

  @override
  Stream<DeckActivitySnapshot> build(String? deckId) {
    ref.onDispose(_cancelBoundary);
    listenSelf(_armBoundary);

    return ref.watch(watchDeckActivityUseCaseProvider)(
      deckId: deckId,
      now: ref.watch(progressNowProvider),
      // Resolved per build, so a device that changed zones re-reads with the new
      // offset the next time anything moves `progressNowProvider` — which the
      // resume hook already does.
      utcOffset: ref.watch(utcOffsetProvider)(),
    );
  }

  /// Re-arms the wake-up from the emission that just landed.
  void _armBoundary(
    AsyncValue<DeckActivitySnapshot>? _,
    AsyncValue<DeckActivitySnapshot> next,
  ) {
    // Cancel first, unconditionally: an error emission must also clear the timer
    // armed for the previous snapshot.
    _cancelBoundary();

    final DateTime? boundary = next.value?.nextDayBoundaryAt;
    if (boundary == null) {
      _immediateRefreshBoundary = null;

      return;
    }

    final Duration delay = boundary.difference(ref.read(clockProvider)());

    if (delay > Duration.zero) {
      _immediateRefreshBoundary = null;
      _boundaryTimer = Timer(
        delay < kMaxProgressBoundaryDelay ? delay : kMaxProgressBoundaryDelay,
        ref.read(progressNowProvider.notifier).refresh,
      );

      return;
    }

    // `delay <= 0`: the clock reached midnight before this emission was
    // processed, so the boundary was crossed with no timer to catch it. Refresh
    // now — re-open the read at the new `now`, where the windows have moved —
    // instead of showing yesterday's windows until the next resume.
    //
    // Guarded so it cannot spin: recorded once per boundary and refused for a
    // boundary already chased. A healthy read answers with tomorrow's midnight,
    // so this fires at most once per real crossing.
    if (_immediateRefreshBoundary == boundary) return;
    _immediateRefreshBoundary = boundary;
    _boundaryTimer = Timer(
      Duration.zero,
      ref.read(progressNowProvider.notifier).refresh,
    );
  }

  void _cancelBoundary() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
  }
}
