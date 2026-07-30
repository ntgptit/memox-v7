import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/clock_provider.dart';
import '../../domain/models/root_deck_list_snapshot_model.dart';
import '../providers/deck_use_case_provider.dart';
import 'deck_list_now_controller.dart';

part 'root_deck_list_controller.g.dart';

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
/// practice the ceiling is never what fires. If it ever does, the effect is one
/// extra query after a day of the screen being continuously open.
const Duration kMaxDueBoundaryDelay = Duration(days: 1);

/// Every root deck with its aggregate progress, and a refresh scheduled for the
/// moment that progress expires (UC-06).
///
/// One repository stream, one SQL statement. The counts are not computed here and
/// must not be: deriving them per row in Dart is the N+1 UC-06 names, and it would
/// also make the number disagree with the session query it is supposed to predict.
///
/// **The timer, and why it is one timer and not a schedule.** Each emission
/// carries `nextDueAt` — the earliest instant at which some card becomes due, from
/// the same statement as the counts. A single one-shot timer is armed for that
/// instant; when it fires it moves [deckListNowProvider], this notifier rebuilds,
/// the query runs at the new instant, and the next emission arms the next timer.
/// So the wake-ups follow the data instead of a fixed interval, there is never
/// more than one pending, and a screen with nothing scheduled to come due has none
/// at all.
///
/// **The boundary that has already passed.** A snapshot is read at one `now` and
/// processed a few instants later. If the clock crosses `nextDueAt` in that gap —
/// `delay <= 0` — a future timer would be armed for a moment already gone, so
/// instead the notifier refreshes *immediately*: it re-opens the query at the new
/// `now`, where the card that just came due is finally counted. Without this the
/// count could sit stale until the next resume or unrelated rebuild.
///
/// It still cannot loop. A healthy repository answers the re-opened query
/// (`due_at > now`) with a *later* boundary or none, so the immediate refresh
/// fires at most once per real crossing. The one degenerate case — a repository
/// that keeps re-emitting the *same* past boundary regardless of `now` — is held
/// by [_immediateRefreshBoundary], which refuses to arm a second refresh for a
/// boundary it has already chased.
///
/// The timer is armed in `listenSelf` rather than inside the stream's transform,
/// because arming it is a side effect and a `map` is not where side effects
/// belong. It is cancelled by an `onDispose` registered in the same build, which
/// Riverpod runs both on disposal *and* before a rebuild — that is what keeps a
/// rebuild from leaving the previous timer pending. Nothing here is global: this
/// notifier is `autoDispose`, so leaving the screen cancels the timer with it.
///
/// **A notifier and not a function provider**, only because `listenSelf` is a
/// notifier method: a function provider receives a plain `Ref`, which has no way
/// to observe its own output. It exposes `build` and nothing else — there is no
/// command here.
///
/// Automatic retry is off — see `noAutomaticRetry`: while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin instead of showing
/// its error state.
@Riverpod(retry: noAutomaticRetry)
class RootDeckList extends _$RootDeckList {
  /// At most one pending wake-up, ever. Held on the notifier rather than in the
  /// build closure so cancelling it does not depend on which closure won a race.
  /// Carries either the future-boundary timer or the one-shot immediate refresh —
  /// they never coexist, so one field and one [_cancelBoundary] cover both, and
  /// the `onDispose` that cancels it cancels whichever is armed.
  Timer? _boundaryTimer;

  /// The past-or-equal boundary an immediate refresh has already been armed for,
  /// or `null` when the last emission carried a healthy (future or absent) one.
  ///
  /// This is the loop guard. A stale emission triggers one immediate refresh and
  /// records its boundary here; a repository that re-emits the *same* past
  /// boundary then finds it already recorded and does not arm again.
  DateTime? _immediateRefreshBoundary;

  @override
  Stream<RootDeckListSnapshot> build() {
    ref.onDispose(_cancelBoundary);
    listenSelf(_armBoundary);

    return ref.watch(watchRootDeckListUseCaseProvider)(
      now: ref.watch(deckListNowProvider),
    );
  }

  /// Re-arms the wake-up from the emission that just landed.
  void _armBoundary(
    AsyncValue<RootDeckListSnapshot>? _,
    AsyncValue<RootDeckListSnapshot> next,
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
    // boundary already chased. A healthy repository advances past `nextDueAt` on
    // the reopened read, so this fires once; only a repository stuck on the same
    // past boundary would try again, and that is what the guard stops.
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
