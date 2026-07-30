import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/deck_content_type_model.dart';
import '../models/scheduler_type_model.dart';

part 'deck_entity.freezed.dart';

/// A deck in the tree, shaped by what presentation needs (AD-01) — not by the
/// `decks` table. Scheduler columns live on the root only (BR-06); on a
/// sub-deck they are null and the root is one lookup away via [rootDeckId].
@freezed
abstract class DeckEntity with _$DeckEntity {
  const factory DeckEntity({
    required String id,
    required String name,

    /// Null marks a root deck.
    required String? parentDeckId,

    /// The root of this deck's tree; a root carries its own id (BR-56).
    required String rootDeckId,
    required DeckContentType contentType,

    /// Root only (BR-06). Null on every sub-deck.
    required SchedulerType? schedulerType,

    /// Root only. Starts at 1, +1 per reset (BR-40).
    required int? schedulerGeneration,

    /// Null while the scheduler is still unlocked (BR-12, BR-13). Root only.
    required DateTime? firstReviewAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _DeckEntity;

  const DeckEntity._();

  /// Deepest allowed level in the deck tree (BR-55). The root counts as
  /// level 1, so a chain of root → … → leaf may hold at most this many decks.
  ///
  /// The single owner of the number 10: repository guards derive their SQL
  /// walk bounds from it instead of repeating it.
  static const int maxTreeDepth = 10;

  bool get isRoot => parentDeckId == null;

  /// BR-01 is **not** here. The deck name rule and its limit live in
  /// `domain/models/deck_name_model.dart`, in a type that cannot hold an invalid
  /// value — so the repository contract asks for a `DeckName` and "has this been
  /// validated?" is answered by the signature.
  ///
  /// It used to be here as `nameProblem` and `validateName`, and having it here is
  /// what let three layers each call it for one submit.
}
