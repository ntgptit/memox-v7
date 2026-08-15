import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';

part 'progress_now_controller.g.dart';

/// The instant the Progress numbers are measured against (BR-184).
///
/// Held as state rather than read inline for the reason `DeckListNow` records: a
/// `DateTime.now()` inside the stream provider would be re-evaluated on every
/// unrelated rebuild — making the window silently re-anchor — and would never
/// update at all while the screen sat still.
///
/// Two things move it, and Progress needs both:
///
/// * **coming back to the foreground** — the phone was in a pocket and the day
///   may have changed while nothing was watching;
/// * **local midnight passing with the screen open** — `ProgressOverview`
///   schedules that from the `nextLocalMidnight` its own emission carried
///   (BR-189), and `DeckActivityLevel` does the same from the boundary its own
///   snapshot carries (BR-194). One notifier, two readers: the instant is a
///   property of the screen's clock, not of either query.
///
/// **Its own file, beside the query controller that watches it**, for the same
/// reason `deck_list_now_controller.dart` is separate: this is an input-state
/// notifier — a value the UI owns that a query is parameterized by — and that is
/// a different kind of thing from a controller that reads the data layer.
@riverpod
class ProgressNow extends _$ProgressNow {
  @override
  DateTime build() {
    // `AppLifecycleListener` rather than a widget observer: the trigger belongs
    // to the data this provider owns, and reaching it through the widget tree
    // would mean a controller holding on to a piece of that tree.
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);

    return ref.read(clockProvider)();
  }

  /// Re-measures now, which re-opens the read at the new local day.
  void refresh() => state = ref.read(clockProvider)();
}
