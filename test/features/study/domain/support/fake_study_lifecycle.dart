part of 'fake_study_repository.dart';

/// The endings, split off the main fake at the guard's 400-line mark — the same
/// seam the real repository takes in `study_lifecycle_repository_impl.dart`.
///
/// Everything here is about a session *stopping*: what it recorded when it did,
/// what held it open, and what refused. Keeping them together is what lets a
/// test read "which endings happened" from one place instead of from five
/// fields scattered through a three-hundred-line double.
// `implements StudyRepository`, so the `@override`s below stay meaningful:
// without it a signature could drift from the contract here and only the
// concrete class would notice.
mixin _FakeStudyLifecycleStubs implements StudyRepository {
  final List<({StudySessionStatus status, StudySessionEndReason? reason})>
  ended = <({StudySessionStatus status, StudySessionEndReason? reason})>[];
  @override
  Future<void> endSession({
    required String sessionId,
    required StudySessionStatus status,
    required StudySessionEndReason? reason,
    required DateTime endedAt,
  }) async {
    final gate = endSessionGate;
    if (gate != null) await gate.future;
    if (endSessionFails) throw StateError('the session could not be ended');

    ended.add((status: status, reason: reason));
  }

  /// Holds every `endSession` open: the window between pressing ✕ and the
  /// session ending, where the screen used to take another answer.
  Completer<void>? endSessionGate;

  /// Makes ending fail — a session that could not end is still running.
  bool endSessionFails = false;
  @override
  Future<int> abandonStaleSessions({required DateTime dayStart}) async {
    abandonedBefore = dayStart;

    return 0;
  }

  DateTime? abandonedBefore;
  @override
  Future<int> invalidateSessionsForRoot({
    required String rootDeckId,
    required DateTime endedAt,
    required StudySessionEndReason reason,
  }) async => 0;

  /// What a deletion asked this fake to close (BR-185). Recorded rather than
  /// simulated: the closing itself is exercised against a real database in
  /// `test/features/trash/`, and what a *caller* owes is the id sets.
  final List<({List<String> deckIds, List<String> cardIds})>
  deletionInvalidations = <({List<String> deckIds, List<String> cardIds})>[];

  @override
  Future<int> invalidateSessionsForDeletedContent({
    required List<String> deckIds,
    required List<String> cardIds,
    required DateTime endedAt,
  }) async {
    deletionInvalidations.add((deckIds: deckIds, cardIds: cardIds));

    return 0;
  }
}
