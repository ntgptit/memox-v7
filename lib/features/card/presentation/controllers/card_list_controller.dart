import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/entities/card_entity.dart';
import '../providers/card_use_case_provider.dart';
import 'card_list_window_controller.dart';

part 'card_list_controller.g.dart';

/// One deck's cards, capped at the window the user has scrolled open.
///
/// **The window size is `watch`ed, not passed** — growing it (a load-more tap)
/// moves `cardListWindowProvider`, this rebuilds, and the stream re-subscribes
/// at the larger `limit`. So the screen owns how far the window is open and the
/// read follows it, with no cursor threaded through (see `card.drift`).
///
/// `family` on the deck id, `autoDispose` by the generator default: leaving the
/// deck drops the subscription and the window with it.
///
/// Automatic retry is off (`noAutomaticRetry`): while Riverpod retries, the
/// state is `AsyncLoading`, so a failed local read would spin on a spinner
/// instead of reaching the error state the screen draws.
@Riverpod(retry: noAutomaticRetry)
class CardList extends _$CardList {
  @override
  Stream<List<CardEntity>> build(String deckId) {
    final limit = ref.watch(cardListWindowProvider(deckId));

    return ref.watch(watchCardsByDeckUseCaseProvider)(deckId, limit: limit);
  }
}

/// The deck's whole card count, for the "showing N of M" line.
///
/// A separate notifier from [CardList] because it is a separate statement: the
/// count cannot ride beside the rows without making SQLite materialise the whole
/// deck (see `CardRepository.watchCardCountByDeck`). The screen combines the two
/// AsyncValues; it does not ask the domain to pretend they are one.
@Riverpod(retry: noAutomaticRetry)
class CardCount extends _$CardCount {
  @override
  Stream<int> build(String deckId) =>
      ref.watch(watchCardCountUseCaseProvider)(deckId);
}
