part of 'deck_repository_impl.dart';

/// The two operations that rewrite a root deck's scheduler.
///
/// **Together because they are the same write with one line different.** Both
/// set `scheduler_type` and re-seed every study state in the tree, in one
/// transaction (BR-47, BR-14, BR-42). Only `resetLearningProgress` bumps
/// `scheduler_generation` — because only reset is throwing a generation of
/// learning away. Reading them side by side is what makes that single
/// difference visible; in two files it looked like two unrelated operations that
/// happened to resemble each other, and the temptation was always to route the
/// cheap one through the expensive one.
///
/// **They reach Study through Study's domain contract**, which is what the
/// architecture guard's own message recommends where it forbids reaching into
/// another feature's `data/`. `invalidateSessionsForRoot` opens a transaction of
/// its own; Drift joins it to the one already running, so BR-83 and BR-164 are
/// closed inside BR-47 rather than beside it.
mixin _SchedulerWriteOperations implements DeckRepository {
  DeckDao get _dao;
  DateTime Function() get _clock;
  StudyRepository get _study;

  Future<T> _guard<T>(Future<T> Function() action);
  Future<Deck> _requireDeckRow(String deckId);

  @override
  Future<void> resetLearningProgress({
    required String rootDeckId,
    required SchedulerType schedulerType,
  }) => _guard(
    () => _dao.runInTransaction(() async {
      final deck = await _requireDeckRow(rootDeckId);

      // A4: there is no such operation one level down. The scheduler and the
      // generation belong to the root (BR-05), so a reset on a branch would
      // either do nothing or quietly reset somebody else's tree.
      if (deck.parentDeckId != null) {
        throw const ConflictFailure(
          message: 'Refused: learning progress is reset on a root deck.',
          reason: DeckConflictReason.resetNeedsRootDeck,
        );
      }

      // A scheduler this build does not know cannot be written back — the enum
      // has no `dbValue` for it — so the refusal is here rather than at the
      // write, where it would surface as a crash instead of an answer.
      if (schedulerType == SchedulerType.unknown) {
        throw const ConflictFailure(
          message: 'Refused: that study mode is unknown to this version.',
          reason: DeckConflictReason.resetSchedulerUnknown,
        );
      }

      final now = _clock();
      final generation =
          (deck.schedulerGeneration ?? _initialSchedulerGeneration) + 1;

      await _dao.updateDeckById(
        rootDeckId,
        DecksCompanion(
          schedulerType: Value<String?>(schedulerType.dbValue),
          schedulerGeneration: Value<int?>(generation),
          // BR-44: the scheduler is unlocked again, and this is the only
          // mechanism that does it (BR-13).
          firstAnsweredAt: const Value<DateTime?>(null),
          updatedAt: Value<DateTime>(now),
        ),
      );

      await _dao.resetTreeStudyStates(
        rootDeckId: rootDeckId,
        schedulerType: schedulerType,
        generation: generation,
      );

      // BR-83. `scheduler_reset`, not `stale_generation`: this is the reset
      // closing its own sessions, not a session discovering afterwards that it
      // had been outrun.
      await _study.invalidateSessionsForRoot(
        rootDeckId: rootDeckId,
        endedAt: now,
        reason: StudySessionEndReason.schedulerReset,
      );
    }),
  );

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

      // **Choosing the mode the deck already runs is a no-op, and has to be
      // one.** Everything below re-seeds the tree and kills every open session;
      // doing that because the user confirmed the row that was already selected
      // would destroy a session for no change at all. The comparison is on the
      // stored string rather than the parsed enum so that an unknown stored
      // value can never equal a known choice.
      if (deck.schedulerType == schedulerType.dbValue) {
        return;
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
      //
      // **`scheduler_changed`, not `scheduler_reset`** (M100.13). Both close a
      // session because the ground moved, and they used to write the same
      // label — but a reset bumps the generation and this does not, so reading
      // the column alone said "reset" about something that was not one. The
      // generation comparison could still tell them apart; needing that trick
      // to read one column is what made the value worth splitting.
      await _study.invalidateSessionsForRoot(
        rootDeckId: rootDeckId,
        endedAt: _clock(),
        reason: StudySessionEndReason.schedulerChanged,
      );
    }),
  );
}
