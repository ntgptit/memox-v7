import '../repositories/study_repository.dart';

/// Puts a root deck back on the app-wide study defaults (BR-184).
///
/// **The counterpart of `SaveStudyOptionsUseCase`, not a variant of it.** A save
/// writes two values; this removes the whole override, so the deck starts
/// reading whatever the app defaults are *now* and keeps following them when
/// they change. Saving the current defaults onto the deck would look the same
/// today and stop being true the next time somebody edits Settings.
///
/// **It is not Reset learning progress** (BR-42). Nothing on this path can
/// reach a card's schedule, a history row or a scheduler generation: the
/// repository behind it writes one nullable column of `decks`.
class ClearStudyOptionsOverrideUseCase {
  const ClearStudyOptionsOverrideUseCase(this._repository);

  final StudyRepository _repository;

  /// [deckId] may be any deck in the tree; the clear lands on its root.
  Future<void> call(String deckId) =>
      _repository.clearStudyOptionsOverride(deckId);
}
