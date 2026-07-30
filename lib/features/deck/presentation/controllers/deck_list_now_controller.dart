import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';

part 'deck_list_now_controller.g.dart';

/// The instant the deck list's due counts are measured against.
///
/// Held as state rather than read inline so it changes at moments we choose. A
/// `DateTime.now()` inside the stream provider would be re-evaluated on every
/// unrelated rebuild, which makes the count flicker between two truths, and would
/// never update at all while the screen sat still.
///
/// Two things move it, and both are needed:
///
/// * **coming back to the foreground** — the phone was in a pocket and hours
///   passed while nothing was watching;
/// * **a due boundary being crossed while the screen is open** — `RootDeckList`
///   schedules that from the data it just read.
///
/// Resume alone was the whole mechanism, and it left a real gap: a user sitting on
/// the list when a card came due saw a badge that said 3 while the session it
/// launches handed out 4. The comment here used to record that a periodic timer
/// had been "considered and rejected" because resume catches the same boundary. It
/// does not, and what replaced that reasoning is not a periodic timer either — it
/// is a single wake scheduled from `nextDueAt`.
///
/// **Its own file, beside the query controller that watches it.** This is an
/// input-state notifier: a value the UI owns that a query is parameterized by,
/// which is a different kind of thing from a controller that reads the data layer.
/// They shared a file until the two notifiers made the file's public surface read
/// as one God Notifier to anything counting methods per file.
@riverpod
class DeckListNow extends _$DeckListNow {
  @override
  DateTime build() {
    // `AppLifecycleListener` rather than a widget observer: the trigger belongs to
    // the data this provider owns, and reaching it through the widget tree would
    // mean a controller holding on to a piece of that tree.
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);

    return ref.read(clockProvider)();
  }

  /// Re-measures now. Also the hook a pull-to-refresh would use, if the stream
  /// were not already the source of truth for everything except the clock.
  void refresh() => state = ref.read(clockProvider)();
}
