import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';

part 'progress_now_controller.g.dart';

/// The instant Progress by Deck measures its windows against.
///
/// Held as state rather than read inline, for the reason `DeckListNow` states: a
/// `DateTime.now()` inside the stream provider would be re-evaluated on every
/// unrelated rebuild — making the same figure flicker between two truths — and
/// would never move at all while the screen sat still.
///
/// Two things move it, and this screen needs both more than the deck list does,
/// because every figure on it is defined by a window that slides:
///
/// * **coming back to the foreground** — the phone was in a pocket and days may
///   have passed while nothing was watching;
/// * **the local day rolling over while the screen is open** —
///   `DeckActivityLevel` schedules that from the boundary its own snapshot
///   carries (BR-184).
///
/// Its own file, beside the query controller that watches it, and for the same
/// reason: this is input state the UI owns, not a controller that reads the data
/// layer.
@riverpod
class ProgressNow extends _$ProgressNow {
  @override
  DateTime build() {
    // `AppLifecycleListener` rather than a widget observer: the trigger belongs
    // to the data this provider owns, and reaching it through the widget tree
    // would mean a controller holding a piece of that tree.
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);

    return ref.read(clockProvider)();
  }

  /// Re-measures now.
  void refresh() => state = ref.read(clockProvider)();
}
