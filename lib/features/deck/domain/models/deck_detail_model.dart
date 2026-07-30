import 'package:freezed_annotation/freezed_annotation.dart';

import '../entities/deck_entity.dart';

part 'deck_detail_model.freezed.dart';

/// One deck plus its direct children — the deck screen's read model.
///
/// **Both facts come from a single database read**, which is the point of the type
/// existing. The screen computes its action set from the two together: which
/// actions exist comes from the deck's `content_type`, and whether *reset* is
/// offered comes from the children being empty (BR-68). Reading them separately
/// means two snapshots, so the screen could render an action matrix from a deck
/// captured at one instant and a child list captured at another.
///
/// It lives in `domain/models/` and not in the controller because the repository
/// returns it: `watchDeckDetail` is one contract method backed by one statement.
/// It used to be declared in the controller, which composed two repository calls
/// and asserted in a comment that they "arrive together" — they did not.
@freezed
abstract class DeckDetail with _$DeckDetail {
  const factory DeckDetail({
    required DeckEntity deck,
    required List<DeckEntity> childDecks,
  }) = _DeckDetail;

  const DeckDetail._();

  /// Whether the content type can be put back to `unset` (BR-68).
  ///
  /// Direct children only, and only for a sub-deck: a root's content type is
  /// invariant (BR-58). Cards are **not** counted here — this screen does not read
  /// the card feature (M4.11 owns that), so it can only say "no child decks", and
  /// the repository is what refuses a reset on a deck that still holds cards. That
  /// is the right split: the UI offers, the repository decides.
  bool get mayOfferReset => !deck.isRoot && childDecks.isEmpty;
}
