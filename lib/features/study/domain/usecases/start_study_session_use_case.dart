import '../../../../core/error/failure.dart';
import '../models/study_session_start_model.dart';
import '../failures/study_refusal_failure.dart';
import '../models/study_mode.dart';
import '../models/study_scheduler.dart';
import '../models/study_session_kind_model.dart';
import '../repositories/study_repository.dart';

/// Opens a session of a chosen kind (UC-05).
///
/// **One use case for both kinds, because opening a session is one interaction.**
/// What differs is which set of cards it takes and which stages it runs, and both
/// of those are answers the algorithm and BR-142 already give — not two different
/// things a user does. Two use cases here would duplicate the option lookup, the
/// generation read and the refusal handling, and the copies would drift.
///
/// The stage list comes from the deck's algorithm (BR-97). A review session is
/// given exactly one mode by the user (BR-109), and that mode must be one the
/// algorithm offers (BR-146) — a review in `browse` would record nothing and
/// could never end.
class StartStudySessionUseCase {
  const StartStudySessionUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudySessionStartModel> call({
    required String deckId,
    required StudySessionKind kind,
    required DateTime now,

    /// Required for a review session, ignored for a learning one.
    StudyMode? reviewMode,
  }) async {
    final context = await _repository.deckContext(deckId);
    final scheduler = schedulerFor(context.schedulerType);

    // A deck written by a newer build is readable but not studiable: nothing
    // here knows its rules, and guessing them would write a schedule under an
    // algorithm that does not exist in this version.
    if (scheduler == null) {
      throw const ConflictFailure(
        message: 'This deck uses an algorithm this version does not know',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    final stageSequence = _stagesFor(
      scheduler: scheduler,
      kind: kind,
      reviewMode: reviewMode,
    );

    // Read once, here, and frozen onto the session (BR-139). Changing the
    // setting afterwards must not move a session that is already running.
    final options = await _repository.effectiveOptions(context.rootDeckId);

    final session = await _repository.openSession(
      deckId: deckId,
      kind: kind,
      stageSequence: stageSequence,
      cardLimit: options.cardLimit,
      newCardOrder: options.newCardOrder,
      now: now,
    );

    // The card set comes back with the session rather than in a second call:
    // three reads are three snapshots, and a Reset landing between them leaves
    // the screen holding halves of two different worlds (AD-13).
    return StudySessionStartModel(
      session: session,
      schedulerType: context.schedulerType,
      actions: scheduler.supportedActions,
      cards: await _repository.sessionCards(session.id),
    );
  }

  List<StudyMode> _stagesFor({
    required StudyScheduler scheduler,
    required StudySessionKind kind,
    required StudyMode? reviewMode,
  }) {
    if (kind == StudySessionKind.learning) return scheduler.stageSequence;

    if (reviewMode == null) {
      throw const ValidationFailure(
        message: 'A review session needs a mode',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    // BR-146. Refused rather than silently substituted: a user who picked
    // `fill` and got `match` would have no way to tell it happened.
    if (!scheduler.reviewModes.contains(reviewMode)) {
      throw const ConflictFailure(
        message: 'This algorithm does not offer that mode',
        reason: StudyRefusalReason.modeNotSupportedByScheduler,
      );
    }

    return <StudyMode>[reviewMode];
  }
}
