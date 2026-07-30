import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/clock_provider.dart';
import '../../domain/models/deck_list_snapshot_model.dart';
import '../providers/deck_use_case_provider.dart';
import 'deck_list_now_controller.dart';

part 'deck_list_controller.g.dart';

/// The longest a due-boundary timer may wait before it re-measures anyway.
///
/// **Not a poll interval.** The timer's delay comes from the data — the next
/// instant a card becomes due — and this is only a ceiling on it, for one
/// mechanical reason: on the web a `Timer` is `setTimeout`, whose delay is a
/// 32-bit signed millisecond count, so anything past about 24.8 days fires
/// immediately and turns one scheduled wake into a busy loop. Web is the E2E
/// channel, so the arithmetic has to be safe there.
///
/// A day is far inside that limit and far past any real foreground session, so in
/// practice the ceiling is never what fires.
const Duration kMaxDueBoundaryDelay = Duration(days: 1);

/// One level of the deck tree, with a refresh scheduled for the moment its counts
/// expire (UC-06, UC-08).
///
/// **`family` on the parent id, and that is the whole unification.** The root list
/// is this notifier with `null`; the inside of a deck is the same notifier with an
/// id. There were two — `RootDeckList` and `DeckDetail` — and they answered the
/// same question with different amounts of information, which is why the two
/// screens looked different. One notifier cannot drift from itself.
///
/// The family also means opening a second deck does not disturb the first, which
/// matters because the shell keeps the branch alive behind a pushed route.
///
/// **The timer, and why it is one timer and not a schedule.** Each emission
/// carries `nextDueAt` — the earliest instant at which some card in view becomes
/// due, from the same statement as the counts. A single one-shot timer is armed
/// for that instant; when it fires it moves [deckListNowProvider], every level
/// rebuilds, and the next emission arms the next timer. So the wake-ups follow the
/// data instead of a fixed interval, there is never more than one pending per
/// level, and a level with nothing scheduled to come due has none at all.
///
/// The timer is armed in `listenSelf` rather than inside the stream's transform,
/// because arming it is a side effect and a `map` is not where side effects
/// belong. It is cancelled by an `onDispose` registered in the same build, which
/// Riverpod runs both on disposal *and* before a rebuild — that is what keeps a
/// rebuild from leaving the previous timer pending. Nothing here is global: this
/// notifier is `autoDispose`, so leaving a level cancels its timer with it.
///
/// Automatic retry is off — see `noAutomaticRetry`: while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin instead of showing
/// its error state.
@Riverpod(retry: noAutomaticRetry)
class DeckList extends _$DeckList {
  /// At most one pending wake-up per level, ever. Held on the notifier rather
  /// than in the build closure so cancelling it does not depend on which closure
  /// won a race.
  Timer? _boundaryTimer;

  /// The past-or-equal boundary an immediate refresh has already been armed for,
  /// or `null` when the last emission carried a healthy (future or absent) one.
  ///
  /// This is the loop guard. A stale emission triggers one immediate refresh and
  /// records its boundary here; a repository that re-emits the *same* past
  /// boundary then finds it already recorded and does not arm again.
  DateTime? _immediateRefreshBoundary;

  @override
  Stream<DeckListSnapshot> build(String? parentDeckId) {
    ref.onDispose(_cancelBoundary);
    listenSelf(_armBoundary);

    return ref.watch(watchDeckListUseCaseProvider)(
      parentDeckId: parentDeckId,
      now: ref.watch(deckListNowProvider),
    );
  }

  /// Re-arms the wake-up from the emission that just landed.
  void _armBoundary(
    AsyncValue<DeckListSnapshot>? _,
    AsyncValue<DeckListSnapshot> next,
  ) {
    // Cancel first, unconditionally. An emission that carries no boundary must
    // also clear the timer armed for the previous one — otherwise deleting the
    // last scheduled card leaves a wake-up behind for a card that is gone.
    _cancelBoundary();

    final DateTime? nextDueAt = next.value?.nextDueAt;
    if (nextDueAt == null) {
      _immediateRefreshBoundary = null;
      return;
    }

    final Duration delay = nextDueAt.difference(ref.read(clockProvider)());

    if (delay > Duration.zero) {
      // The boundary is still ahead: one one-shot at that instant, capped for the
      // web `setTimeout` limit. A healthy boundary ends any stale streak.
      _immediateRefreshBoundary = null;
      _boundaryTimer = Timer(
        delay < kMaxDueBoundaryDelay ? delay : kMaxDueBoundaryDelay,
        ref.read(deckListNowProvider.notifier).refresh,
      );
      return;
    }

    // `delay <= 0`: the clock reached `nextDueAt` before this emission was
    // processed, so the boundary was crossed with no timer to catch it. Refresh
    // now — re-open the query at the new `now`, where the newly-due card is
    // counted — instead of dropping the update until the next resume.
    //
    // Guarded so it cannot spin: recorded once per boundary, and refused for a
    // boundary already chased. A healthy repository answers the re-opened query
    // (`due_at > now`) with a later boundary or none, so this fires at most once
    // per real crossing.
    if (_immediateRefreshBoundary == nextDueAt) return;
    _immediateRefreshBoundary = nextDueAt;
    _boundaryTimer = Timer(
      Duration.zero,
      ref.read(deckListNowProvider.notifier).refresh,
    );
  }

  void _cancelBoundary() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
  }
}
