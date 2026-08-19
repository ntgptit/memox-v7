import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';

part 'study_home_now_controller.g.dart';

/// The instant Study Home's workload is measured against.
///
/// Held as state rather than read inline, for the reason `DeckListNow` records:
/// a `clockProvider()` call inside the stream provider is re-evaluated on every
/// unrelated rebuild, which makes the split between overdue and due-today
/// flicker between two truths — and never updates at all while the tab sits
/// still.
///
/// Two things move it:
///
/// * **coming back to the foreground** — the phone was in a pocket, and a card
///   became due, or the local day turned over, while nothing was watching;
/// * **a boundary crossed while the tab is open** — `StudyHome` arms a single
///   wake from the snapshot it just read.
///
/// **Its own notifier rather than sharing the deck list's.** `deckListNowProvider`
/// answers the same question, and reaching for it would be a feature importing
/// another feature's `presentation/` — the boundary `check_architecture.sh`
/// rule 3 exists for. The two are also independently disposable: the Study tab
/// keeping a deck-list clock alive would be a wake-up scheduled for a screen
/// nobody is looking at.
@riverpod
class StudyHomeNow extends _$StudyHomeNow {
  @override
  DateTime build() {
    // `AppLifecycleListener` rather than a widget observer: the trigger belongs
    // to the data this provider owns, and reaching it through the widget tree
    // would mean a controller holding on to a piece of that tree.
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);

    return ref.read(clockProvider)();
  }

  /// Re-measures now. The stream underneath is already the source of truth for
  /// everything except the clock, so this is the only thing a refresh moves.
  void refresh() => state = ref.read(clockProvider)();
}
