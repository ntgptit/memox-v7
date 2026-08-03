import '../entities/card_entity.dart';
import '../entities/card_review_state_entity.dart';
import 'card_state_model.dart';

/// One row of the management list: a card and the slice of its schedule the row
/// draws (D5, BR-89…BR-91).
///
/// **One projection carrying both, not two reads the screen zips together**
/// (AD-13). The row shows the card's content and its state dot in the same
/// frame; reading them separately would let the list render a card from after a
/// write beside a state from before it. The join in `cardListItemsByDeck`
/// returns the pair, and this is what it maps to.
///
/// [state] is derived here, on read, never stored — the display label is a
/// projection of `current_box` / `interval_days` (BR-89), and `cardStateOf` owns
/// the two per-scheduler functions that compute it.
class CardListItemModel {
  const CardListItemModel({
    required this.card,
    required this.reviewState,
    this.tagNames = const <String>[],
  });

  final CardEntity card;
  final CardReviewStateEntity reviewState;

  /// The card's tag names, for the row's chip strip (BR-93). Names only — the
  /// row does not act on a tag, so it needs no id; the editor owns tag edits and
  /// reads full `TagEntity`s through its own stream.
  final List<String> tagNames;

  /// The four-way display state (BR-90/BR-91/BR-88).
  CardState get state => cardStateOf(reviewState);

  /// When this card next comes due, or null for "due now" (BR-22). The badge
  /// reads it against `clockProvider`'s now — no widget touches the wall clock.
  DateTime? get dueAt => reviewState.dueAt;
}
