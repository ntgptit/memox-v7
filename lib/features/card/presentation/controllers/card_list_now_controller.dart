import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/time/clock_provider.dart';

part 'card_list_now_controller.g.dart';

/// The instant the card rows' due badges are measured against (D5, BR-22).
///
/// The mirror of `DeckListNow`, and for the same reason: a `DateTime.now()` read
/// inline in the tile would be re-evaluated on every unrelated rebuild and never
/// update while the screen sat still. Held as state, it moves at moments we
/// choose — here, on returning to the foreground, so a phone that spent an hour
/// in a pocket shows fresh badges when it wakes.
///
/// **No scheduled wake from the next due boundary**, unlike the deck list. There
/// the badge feeds a due *count* that launches a session, so a stale number is a
/// wrong control; here it is a relative label — "in 4d" a minute stale is a stale
/// label, not a wrong action — so resume-refresh is enough, and the boundary wake
/// waits for the study flow that actually depends on it.
@riverpod
class CardListNow extends _$CardListNow {
  @override
  DateTime build() {
    final listener = AppLifecycleListener(onResume: refresh);
    ref.onDispose(listener.dispose);

    return ref.read(clockProvider)();
  }

  void refresh() => state = ref.read(clockProvider)();
}
