import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/error/failure.dart';
import 'deck_content_type_model.dart';
import 'scheduler_type_model.dart';

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

  /// Longest allowed deck name after trimming (BR-01).
  static const int maxNameLength = 200;

  bool get isRoot => parentDeckId == null;

  /// Validates and normalises a deck name (BR-01).
  ///
  /// Returns the trimmed name. Throws [ValidationFailure] when empty after
  /// trim or longer than [maxNameLength] — never truncates silently. The
  /// messages are the non-localized fallback; screens pick their copy from ARB
  /// by field key (see `Failure.message`).
  static String validateName(String raw) {
    final name = raw.trim();
    if (name.isEmpty) {
      throw const ValidationFailure(
        message: 'Please check the highlighted fields.',
        fieldErrors: <String, String>{'name': 'Name must not be empty.'},
      );
    }
    if (name.length > maxNameLength) {
      throw const ValidationFailure(
        message: 'Please check the highlighted fields.',
        fieldErrors: <String, String>{
          'name': 'Name is longer than $maxNameLength characters.',
        },
      );
    }

    return name;
  }
}
