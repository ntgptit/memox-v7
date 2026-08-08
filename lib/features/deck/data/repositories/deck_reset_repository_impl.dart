part of 'deck_repository_impl.dart';

/// Reset learning progress (UC-07).
///
/// **One transaction, and BR-47 is the reason there is only one method.** The
/// generation bump, the deck's new scheduler, every card's state and every open
/// session all have to land together — a tree left with cards from two
/// generations is exactly the state invariant 9 exists to catch, and there is no
/// half of this operation that makes sense on its own.
///
/// **It reaches Study through Study's domain contract**, which is what the
/// architecture guard's own message recommends where it forbids reaching into
/// another feature's `data/`. `invalidateSessionsForRoot` opens a transaction of
/// its own; Drift joins it to the one already running, so BR-83 is closed inside
/// BR-47 rather than beside it.
mixin _ResetLearningProgressOperation implements DeckRepository {
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
      );
    }),
  );
}
