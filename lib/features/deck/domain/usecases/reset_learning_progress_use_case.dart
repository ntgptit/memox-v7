import '../models/scheduler_type_model.dart';
import '../repositories/deck_repository.dart';

/// Resets a root deck's learning progress, optionally onto a new scheduler
/// (UC-07).
///
/// **Thin, and the reason is the same one that keeps depth checks out of use
/// cases** (CLAUDE.md): every rule this operation applies needs the data as it
/// stands at the moment of writing. Whether the deck is a root, what its
/// generation is, which sessions are open — all of them can change between the
/// confirmation opening and the confirm landing, so a check here would answer a
/// question about a moment that has already passed, and the answer would be a
/// race with the write.
///
/// What it does own is the sentence the rest of the app reads: **resetting is
/// one interaction**, not "clear the schedules, then close the sessions, then
/// bump the generation". BR-47 makes that literal — one transaction — and the
/// repository is where a transaction can be opened.
class ResetLearningProgressUseCase {
  const ResetLearningProgressUseCase(this._repository);

  final DeckRepository _repository;

  /// [schedulerType] is the mode the deck runs **after** the reset. Passing the
  /// one it already has is a plain reset (UC-07 A1); passing another is the only
  /// way to change it once a card has been learned (BR-13, BR-44).
  Future<void> call({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => _repository.resetLearningProgress(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
}
