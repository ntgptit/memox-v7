import 'package:freezed_annotation/freezed_annotation.dart';

part 'card_move_target_model.freezed.dart';

/// One deck a card may move into (BR-165, UC-04 A5).
///
/// A read model: the picker needs a name to show, a parent name to tell two
/// same-named decks apart, and an id to submit. It carries no content type
/// beyond what the query already filtered on — every row here is a legal
/// target by construction, so a widget cannot re-derive the rule and get it
/// wrong.
@freezed
abstract class CardMoveTarget with _$CardMoveTarget {
  const factory CardMoveTarget({
    required String deckId,
    required String name,

    /// The parent's name, for the "Unit 1 · Reading" line under a duplicate
    /// name. Null only for a row whose parent vanished mid-read.
    required String? parentName,
  }) = _CardMoveTarget;
}
