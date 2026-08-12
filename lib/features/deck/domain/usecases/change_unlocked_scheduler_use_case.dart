import '../models/scheduler_type_model.dart';
import '../repositories/deck_repository.dart';

/// Changes a root deck's study mode while the scheduler is still unlocked
/// (UC-03, BR-12).
///
/// **A use case of its own rather than a flag on
/// `ResetLearningProgressUseCase`**, because the two answer different questions
/// and only one of them costs the user something. Reset throws a generation of
/// learning away and says so in a destructive confirmation; this one runs on a
/// deck where no card has finished the chain, so there is nothing to warn about
/// and UC-03's postcondition says the generation must not move. A boolean
/// joining them would make every caller decide which warning to show, and the
/// first caller to get it wrong would be showing a destruction warning for a
/// deck with nothing to destroy.
///
/// **Thin, for the same reason reset is** (CLAUDE.md): every rule here — is this
/// a root, is it still unlocked, which sessions are open — needs the data as it
/// stands at the moment of writing. A check here would answer a question about a
/// moment that has already passed, and the answer would be a race with the
/// write. What it owns is the sentence: changing the mode is **one**
/// interaction, not "rewrite the deck, then re-seed the tree, then close the
/// sessions".
class ChangeUnlockedSchedulerUseCase {
  const ChangeUnlockedSchedulerUseCase(this._repository);

  final DeckRepository _repository;

  /// [schedulerType] is the mode the deck runs afterwards. Passing the one it
  /// already runs is accepted and changes nothing the user can see — the
  /// alternative is making the sheet compare before submitting, which puts a
  /// decision about the deck's current state in the widget.
  Future<void> call({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => _repository.changeUnlockedScheduler(
    rootDeckId: rootDeckId,
    schedulerType: schedulerType,
  );
}
