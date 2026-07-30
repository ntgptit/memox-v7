import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/di/deck_repository_provider.dart';
import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/clock_provider.dart';
import '../../domain/models/root_deck_summary_model.dart';

part 'root_decks_controller.g.dart';

/// The instant the deck list's due counts are measured against.
///
/// Held as state rather than read inline so it changes at moments we choose. A
/// `DateTime.now()` inside the stream provider would be re-evaluated on every
/// unrelated rebuild, which makes the count flicker between two truths, and
/// would never update at all while the screen sat still.
///
/// It refreshes when the app comes back to the foreground. That is the moment
/// that matters in practice: the phone was in a pocket, hours passed, and cards
/// became due while nothing was watching. A periodic timer was considered and
/// rejected — it would wake the database on a schedule to change a number
/// nobody is looking at, and the boundary it would catch is the same one resume
/// already catches.
@riverpod
class DeckListNow extends _$DeckListNow {
  @override
  DateTime build() {
    // `AppLifecycleListener` rather than a widget observer: the trigger belongs
    // to the data this provider owns, and reaching it through the widget tree
    // would mean a controller holding on to a piece of that tree.
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);

    return ref.read(clockProvider)();
  }

  /// Re-measures now. Also the hook a pull-to-refresh would use, if the stream
  /// were not already the source of truth for everything except the clock.
  void refresh() => state = ref.read(clockProvider)();
}

/// Every root deck with its aggregate progress (UC-06).
///
/// One repository stream, one SQL statement. The counts are not computed here
/// and must not be: deriving them per row in Dart is the N+1 UC-06 names, and
/// it would also make the number disagree with the session query it is supposed
/// to predict.
///
/// Watching [deckListNowProvider] means a resume re-opens the stream with a
/// fresh boundary, which is the only thing that can change the due count
/// without the database changing.
///
/// Automatic retry is off — see `noAutomaticRetry`: while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin instead of showing
/// its error state.
@Riverpod(retry: noAutomaticRetry)
Stream<List<RootDeckSummary>> rootDeckSummaries(Ref ref) => ref
    .watch(deckRepositoryProvider)
    .watchRootDeckSummaries(now: ref.watch(deckListNowProvider));
