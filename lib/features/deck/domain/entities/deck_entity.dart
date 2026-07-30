import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/error/failure.dart';
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

  /// Longest allowed deck name after trimming (BR-01).
  static const int maxNameLength = 200;

  /// Deepest allowed level in the deck tree (BR-55). The root counts as
  /// level 1, so a chain of root → … → leaf may hold at most this many decks.
  ///
  /// The single owner of the number 10: repository guards derive their SQL
  /// walk bounds from it instead of repeating it.
  static const int maxTreeDepth = 10;

  bool get isRoot => parentDeckId == null;

  /// What is wrong with a proposed deck name, or `null` when nothing is
  /// (BR-01).
  ///
  /// Exists so a form can say "this is invalid, and here is which rule"
  /// **without** catching an exception and without restating the 200 anywhere.
  /// A screen that re-implemented the check would be a second owner of BR-01,
  /// and the two would disagree the first time the rule moved.
  ///
  /// Returns a value, not a message: copy is the screen's job and lives in ARB.
  static DeckNameProblem? nameProblem(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return DeckNameProblem.empty;
    if (name.length > maxNameLength) return DeckNameProblem.tooLong;

    return null;
  }

  /// Validates and normalises a deck name (BR-01).
  ///
  /// Returns the trimmed name. Throws [ValidationFailure] when [nameProblem]
  /// finds anything — never truncates silently. Expressed through
  /// [nameProblem] so the rule has exactly one implementation; the messages
  /// here are the non-localized fallback for a caller that reached the
  /// repository without a form in front of it.
  static String validateName(String raw) {
    final problem = nameProblem(raw);
    if (problem == null) return raw.trim();

    throw ValidationFailure(
      message: 'Please check the highlighted fields.',
      fieldErrors: <String, String>{'name': problem.debugDescription},
    );
  }
}

/// Why a deck name is not acceptable (BR-01).
enum DeckNameProblem {
  /// Empty, or nothing but whitespace.
  empty,

  /// Longer than [DeckEntity.maxNameLength] after trimming.
  tooLong;

  /// Non-localized text for the `Failure` a non-UI caller receives. Never
  /// shown to a user — screens map the enum to ARB copy.
  String get debugDescription => switch (this) {
    DeckNameProblem.empty => 'Name must not be empty.',
    DeckNameProblem.tooLong =>
      'Name is longer than ${DeckEntity.maxNameLength} characters.',
  };
}
