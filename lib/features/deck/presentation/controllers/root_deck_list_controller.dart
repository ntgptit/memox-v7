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
/// It cannot loop: `nextDueAt` is strictly after the `now` it was read with, so
/// each firing moves the clock strictly forward.
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
  Timer? _boundaryTimer;

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
    if (nextDueAt == null) return;

    final Duration delay = nextDueAt.difference(ref.read(clockProvider)());
    // Unreachable through the query, which selects `due_at > :now`. Guarded
    // anyway because the alternative to a guard here is a zero-delay timer that
    // re-arms itself forever, and a clock that jumps backwards is not something
    // this code gets to rule out.
    if (delay <= Duration.zero) return;

    _boundaryTimer = Timer(
      delay < kMaxDueBoundaryDelay ? delay : kMaxDueBoundaryDelay,
      ref.read(deckListNowProvider.notifier).refresh,
    );
  }

  void _cancelBoundary() {
    _boundaryTimer?.cancel();
    _boundaryTimer = null;
  }
}
