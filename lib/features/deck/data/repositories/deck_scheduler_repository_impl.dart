part of 'deck_repository_impl.dart';

/// Change the study mode while the scheduler is still unlocked (UC-03, BR-12).
///
/// **It reads like a reset with one line removed, and that line is the whole
/// point.** `resetLearningProgress` bumps `scheduler_generation`; this does not
/// (UC-03 postcondition). A generation marks "everything before this belongs to
/// a cycle the user threw away" — and a deck where no card has finished the
/// learning chain has no such cycle. Spending a generation here would file an
/// empty history under a superseded number and make the next reset the *second*
/// one, for a user who has reset nothing.
///
/// The rest is identical because BR-14 asks for the same thing BR-42 does: every
/// card in the tree reinitialised onto the new algorithm, in one transaction
/// (BR-47). A tree holding `eight_box` boxes under an `sm2` root is what
/// invariant 9 exists to catch, and doing this in two statements is the only way
/// to produce it.
mixin _ChangeUnlockedSchedulerOperation implements DeckRepository {
  DeckDao get _dao;
  DateTime Function() get _clock;
  StudyRepository get _study;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);

  @override
  Future<void> changeUnlockedScheduler({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      // **Re-read inside the transaction, not trusted from the caller.** The
      // sheet that offered this could have been open while the user finished a
      // card on another screen; the lock it was drawn against is a fact about a
      // moment that has already passed.
      final deck = await _requireDeckRow(rootDeckId);

      if (deck.parentDeckId != null) {
        throw const ConflictFailure(
          message: 'Refused: the study mode is set on a root deck.',
          reason: DeckConflictReason.schedulerNeedsRootDeck,
        );
      }

      // BR-13. Past this point the choice is locked and Reset is the only way
      // through (BR-44) — which is a different operation with a different
      // warning, not this one with a flag.
      if (deck.firstAnsweredAt != null) {
        throw const ConflictFailure(
          message:
              'Refused: this deck has been studied, so the mode is locked.',
          reason: DeckConflictReason.schedulerLocked,
        );
      }

      // A scheduler this build does not know has no `dbValue`, so the write is
      // impossible rather than merely refused. Answering here keeps it an
      // answer instead of a crash.
      if (schedulerType == SchedulerType.unknown) {
        throw const ConflictFailure(
          message: 'Refused: that study mode is unknown to this version.',
          reason: DeckConflictReason.resetSchedulerUnknown,
        );
      }

      final generation =
          deck.schedulerGeneration ?? _initialSchedulerGeneration;

      await _dao.updateDeckById(
        rootDeckId,
        DecksCompanion(
          schedulerType: Value<String?>(schedulerType.dbValue),
          // **`first_answered_at` is not written here, in either direction.**
          // It is already NULL — the guard above proved it — and naming it in
          // the companion would make this operation look like something that
          // can unlock a deck. Only Reset does that (BR-44).
          updatedAt: Value<DateTime>(_clock()),
        ),
      );

      // The generation the deck already has, passed rather than bumped, so
      // every card keeps the number the root keeps (BR-05, invariant 9).
      await _dao.resetTreeStudyStates(
        rootDeckId: rootDeckId,
        schedulerType: schedulerType,
        generation: generation,
      );

      // **An open session cannot survive this, and the user must not have to
      // notice.** Its queue was dealt for the old algorithm and its stage
      // sequence belongs to it; the generation is unchanged, so BR-84's stale
      // check would wave every one of its answers straight through into a tree
      // that has just been re-seeded. Closing them here is the only place it can
      // happen atomically.
      await _study.invalidateSessionsForRoot(
        rootDeckId: rootDeckId,
        endedAt: _clock(),
        reason: StudySessionEndReason.schedulerReset,
      );
    }),
  );
}
