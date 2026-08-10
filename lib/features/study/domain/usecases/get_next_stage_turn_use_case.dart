import '../entities/study_session_entity.dart';
import '../models/study_mode.dart';
import '../models/study_turn_model.dart';
import '../repositories/study_repository.dart';
import 'advance_study_stage_use_case.dart';
import 'get_next_turn_use_case.dart';

/// Which stage is running next, and the turn it serves — one read (AD-13).
///
/// **Two use cases composed in a controller is the shape AD-13 names.** The
/// screen needs both facts at the same moment: a mode with no turn draws a
/// blocked state, and a turn with the wrong mode draws the previous stage's
/// body around the next stage's card. Composed above the domain they were two
/// snapshots, and the window between them is a real one — the stage advance
/// writes.
///
/// It stays two calls underneath, because the second is only meaningful once
/// the first has run: `advance` may close the session, and there is no turn to
/// ask for then.
final class GetNextStageTurnUseCase {
  const GetNextStageTurnUseCase(this._repository);

  final StudyRepository _repository;

  /// A null mode ends the session; it is **not** the same as a null turn, which
  /// means the stage has cards but none available yet (BR-26).
  Future<(StudyMode?, StudyTurnModel?)> call({
    required StudySessionEntity session,
    required DateTime now,
    required Duration utcOffset,
  }) async {
    final mode = await AdvanceStudyStageUseCase(
      _repository,
    ).call(session: session, now: now, utcOffset: utcOffset);
    if (mode == null) return (null, null);

    return (mode, await GetNextTurnUseCase(_repository).call(session.id));
  }
}
