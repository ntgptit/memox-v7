part of 'study_repository_impl.dart';

/// The Trash half of [StudyRepositoryImpl] — same class, same library, split
/// out only so each source file stays under the size guard, the way the deck
/// repository splits its delete and move operations.
///
/// One responsibility: when content goes to Trash, the open sessions it
/// touches end `content_deleted` inside the deletion's own transaction
/// (BR-259, BR-261).
mixin _StudyTrashInvalidationOperation implements StudyRepository {
  StudyDao get _dao;

  @override
  Future<int> invalidateSessionsForDeletedContent({
    required List<String> deckIds,
    required List<String> cardIds,
    required DateTime endedAt,
  }) async {
    // **No transaction of its own.** This is called from inside the deletion's
    // transaction (BR-259), and opening a second one here would only be a
    // savepoint that can commit while the deletion around it rolls back — the
    // one outcome the rule forbids: a session closed for a deletion that never
    // happened.
    return _invalidateSessionsTouching(
      deckIds: deckIds,
      cardIds: cardIds,
      endedAt: endedAt,
      reason: StudySessionEndReason.contentDeleted,
    );
  }

  @override
  Future<int> invalidateSessionsForPromotedSubtree({
    required List<String> deckIds,
    required List<String> cardIds,
    required DateTime endedAt,
  }) => _invalidateSessionsTouching(
    deckIds: deckIds,
    cardIds: cardIds,
    endedAt: endedAt,
    reason: StudySessionEndReason.subtreePromoted,
  );

  Future<int> _invalidateSessionsTouching({
    required List<String> deckIds,
    required List<String> cardIds,
    required DateTime endedAt,
    required StudySessionEndReason reason,
  }) async {
    final ids = await _dao.openSessionIdsTouching(
      deckIds: deckIds,
      cardIds: cardIds,
    );

    for (final id in ids) {
      await _dao.updateSession(
        id,
        StudySessionsCompanion(
          status: Value<String>(StudySessionStatus.invalidated.dbValue),
          // Stored, never inferred (BR-259, BR-269, AD-11). The two callers
          // name distinct events; neither is a whole-root scheduler reset.
          endReason: Value<String?>(reason.dbValue),
          endedAt: Value<DateTime?>(endedAt),
        ),
      );
    }

    return ids.length;
  }
}
