import '../../../../core/error/failure.dart';
import '../entities/study_session_entity.dart';
import '../models/study_day_model.dart';
import '../models/study_scheduler.dart';
import '../models/study_session_start_model.dart';
import '../repositories/study_repository.dart';

/// Picks up a session left open, instead of opening a new one (BR-103).
///
/// **Same shape as starting one**, on purpose: the screen renders a session, and
/// it should not care whether that session is one second or one hour old. What
/// differs is only that nothing is created — the queue, the cursor and any
/// `remaining_ms` are exactly as they were left (BR-133).
///
/// **[sessionId] names the session the user was actually offered, and passing it
/// is what makes Resume mean one thing.** Without it this resolves by deck, and
/// "the open session of this deck" is a different question from "the session on
/// the card that was tapped": a second session opened later on the same deck, or
/// one an earlier study day left behind, both answer the first question and
/// neither is what the tap meant (BR-200). Study Home reads a session id and
/// hands it back here; the per-deck entry screen has no id to give and keeps the
/// older behaviour, which is correct there because it offered no particular
/// session in the first place.
class ResumeStudySessionUseCase {
  const ResumeStudySessionUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudySessionStartModel> call(
    String deckId, {
    String? sessionId,
    DateTime? now,
    Duration? utcOffset,
  }) async {
    final session = await _resolve(
      deckId,
      sessionId,
      now: now,
      utcOffset: utcOffset,
    );
    if (session == null) {
      throw const NotFoundFailure(message: 'No session to resume');
    }

    final context = await _repository.deckContext(deckId);
    final scheduler = schedulerFor(context.schedulerType);
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
      );
    }

    return StudySessionStartModel(
      session: session,
      deckName: context.deckName,
      schedulerType: context.schedulerType,
      actions: scheduler.supportedActions,
      cards: await _repository.sessionCards(session.id),
    );
  }

  /// The named session, re-checked — or the deck's open one when no id came.
  ///
  /// **All three conditions are re-checked here, not trusted from the read that
  /// offered it.** A list is a snapshot: between drawing the Resume card and the
  /// finger landing on it the session can end, the row can belong to a deck the
  /// caller did not mean, or the local day can turn over. Returning null in any
  /// of the three surfaces as the same honest "no session to resume" as an id
  /// that never existed — the alternative is opening a session that cannot take
  /// an answer.
  ///
  /// **The study day is the one that had no owner at the tap.** Study Home
  /// excludes yesterday's session from its list and re-reads at midnight, so the
  /// card does go away — but only once that read lands, and a tap inside that
  /// gap resumed a session BR-103 says is `abandoned`/`interrupted`. Checking it
  /// here makes the tap as strict as the list, and as strict as the per-deck
  /// entry screen, which sweeps stale sessions before offering anything.
  ///
  /// [now] and [utcOffset] are optional because the caller that has no id has no
  /// need of them: `openSessionFor` answers a different question and the entry
  /// screen has already run BR-103's sweep before asking it.
  Future<StudySessionEntity?> _resolve(
    String deckId,
    String? sessionId, {
    required DateTime? now,
    required Duration? utcOffset,
  }) async {
    if (sessionId == null) return _repository.openSessionFor(deckId);

    final session = await _repository.sessionById(sessionId);
    if (session == null || !session.isOpen) return null;
    if (session.deckId != deckId) return null;

    if (now == null || utcOffset == null) return session;
    final dayStart = StudyDayModel(now: now, utcOffset: utcOffset).startOfToday;
    if (session.startedAt.isBefore(dayStart)) return null;

    return session;
  }
}
