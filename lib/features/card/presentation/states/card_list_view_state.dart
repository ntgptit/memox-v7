import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/card_entity.dart';

part 'card_list_view_state.freezed.dart';

/// What the card list shows right now.
///
/// **A window and its total are two facts, and the view holds both** — the list
/// draws the cards, the "showing N of M" line needs the total. They come from
/// two statements on purpose (see `CardRepository.watchCardCountByDeck`), so a
/// frame where [total] trails [cards] by one is a stale label, not a wrong
/// control; the type does not pretend they are one read.
///
/// [hasMore] is derived, not stored: the window can grow while more rows exist
/// than it holds. It is `cards.length < total`, computed once here so the screen
/// and its tests agree on what "there is more" means.
@freezed
abstract class CardListLoaded with _$CardListLoaded {
  const factory CardListLoaded({
    /// The current window, newest first.
    required List<CardEntity> cards,

    /// Every card in the deck, whatever the window is showing.
    required int total,

    /// Whether a load-more expansion would reveal rows not yet in [cards].
    required bool loadingMore,
  }) = _CardListLoaded;

  const CardListLoaded._();

  /// More rows exist than the window holds.
  bool get hasMore => cards.length < total;
}
