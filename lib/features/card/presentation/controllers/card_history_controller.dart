import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/card_history_cursor_model.dart';
import '../../domain/models/card_history_event_model.dart';
import '../providers/card_detail_use_case_provider.dart';
import '../states/card_history_state.dart';

part 'card_history_controller.g.dart';

/// The paginated review history of one card (UC-12 steps 4–6, BR-184).
///
/// **A notifier rather than an async provider, because pages accumulate.** An
/// `AsyncNotifier` re-running its build for page two would either discard page
/// one or re-read it, and appending to what a re-read returns is precisely the
/// duplicate BR-184 forbids. So the rows live in state and each request appends
/// to them.
///
/// **No two requests are ever in flight at once, and that is what makes the
/// appending safe** (UC-12 E5). [loadMore] writes the in-flight status into
/// `state` *before* its first `await`, so a second tap arriving in any later
/// microtask sees it and returns — there is no window in which two responses
/// could both be appended. A request ticket was written here first and removed:
/// it could not be reached through the public API, and an unreachable guard
/// reads as protection somebody is relying on.
///
/// What can still arrive late is a response to a request whose screen has gone,
/// and `ref.mounted` is what drops that one.
///
/// `autoDispose` by default, so leaving the screen drops the accumulated pages
/// — coming back to a card should start at the newest 50, not restore a scroll
/// through a history the reader has left.
@riverpod
class CardHistory extends _$CardHistory {
  @override
  CardHistoryState build(String cardId) {
    // Started, not awaited: `build` must return the state synchronously, and
    // `_fetch` touches `state` only after its first `await`, so nothing is
    // written during the build itself.
    unawaited(_fetch(after: null));

    return const CardHistoryState();
  }

  /// Fetches the page after whatever is on screen (UC-12 steps 4–6, E4).
  ///
  /// **One mutator, because `Load more` and `Try again` are the same
  /// operation.** Both mean "read the page after the last row I have"; only the
  /// label differs, and it differs because of the state the tail is already
  /// rendering. Two methods would have been two places to state the resume
  /// rule, which is exactly how a retry ends up re-reading page one and
  /// appending a second copy of every row already shown.
  ///
  /// A no-op while a request is running — a double tap must not fire one cursor
  /// twice — and at the end of the history, where there is neither a next page
  /// nor a failure to repeat.
  Future<void> loadMore() async {
    if (state.isLoadingInitial || state.isLoadingMore) return;
    if (!state.hasMore && !state.hasPageError) return;

    // A failure on the very first page leaves nothing on screen, so retrying it
    // is an initial load again; a failure later leaves rows in place, and the
    // spinner belongs at the tail rather than over them.
    state = state.copyWith(
      status: state.events.isEmpty
          ? CardHistoryStatus.loadingInitial
          : CardHistoryStatus.loadingMore,
    );
    await _fetch(after: state.nextCursor);
  }

  Future<void> _fetch({required CardHistoryCursor? after}) async {
    try {
      final page = await ref.read(loadCardHistoryPageUseCaseProvider)(
        cardId,
        after: after,
      );
      // The screen may be gone by now — a page that lands after the reader has
      // left must not be written into a disposed notifier.
      if (!ref.mounted) return;

      state = CardHistoryState(
        events: _appended(page.events),
        status: CardHistoryStatus.loaded,
        nextCursor: page.nextCursor,
      );
    } on Object {
      // The failure object is deliberately not kept. Every error reachable here
      // is a local database failure mapped at the repository boundary, and the
      // tail band says one thing about all of them (W3 face 6); storing a
      // reason nothing reads would be a field that goes stale unnoticed. It is
      // surfaced, not swallowed — `pageError` is what the screen renders.
      if (!ref.mounted) return;

      state = state.copyWith(status: CardHistoryStatus.pageError);
    }
  }

  /// Appends [incoming], skipping any event already on screen.
  ///
  /// **A guard, not the mechanism.** The keyset cursor is what makes pages
  /// disjoint (BR-184); this is the cheap second line that keeps a bug in the
  /// cursor from showing the user the same review twice, and it is the reason
  /// the list stays stable under a retry that races a response.
  List<CardHistoryEventModel> _appended(List<CardHistoryEventModel> incoming) {
    final seen = state.events.map((event) => event.id).toSet();

    return <CardHistoryEventModel>[
      ...state.events,
      ...incoming.where((event) => seen.add(event.id)),
    ];
  }
}
