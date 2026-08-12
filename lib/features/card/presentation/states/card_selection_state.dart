import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_selection_state.freezed.dart';

/// What the card list has selected, and whether it is in selection mode at all
/// (BR-167, UC-04 A6).
///
/// **Mode is a field, not `selectedIds.isNotEmpty`.** Entering the mode and
/// selecting the first card happen together on a long-press, but they are not
/// the same fact: a user who deselects the last card leaves the mode, while a
/// user who entered through the app-bar action has an empty selection.
/// Deriving the mode from the set makes those two the same state.
///
/// **The set holds ids, never cards.** A selection outlives the loaded window —
/// Select all covers every card the current filter matches, most of which are
/// not on screen — so anything richer would be a second copy of data the list
/// already streams, free to go stale.
///
/// **No submitting flag.** Writing belongs to the bulk command controllers and
/// their own submit state carries it; a second flag here would give the
/// spinner two owners.
@freezed
abstract class CardSelectionState with _$CardSelectionState {
  const factory CardSelectionState({
    @Default(false) bool isSelecting,
    @Default(<String>{}) Set<String> selectedIds,

    /// True when the selection came from Select all and therefore covers every
    /// card the filter matches, not only the loaded window. Only the label
    /// reads it — the mutations take [selectedIds] either way.
    @Default(false) bool isAllMatching,
  }) = _CardSelectionState;

  const CardSelectionState._();

  int get selectedCount => selectedIds.length;

  bool get hasSelection => selectedIds.isNotEmpty;

  bool isSelected(String cardId) => selectedIds.contains(cardId);

  List<String> get orderedIds => selectedIds.toList(growable: false);
}
