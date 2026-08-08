import '../../../deck/domain/models/scheduler_type_model.dart';
import '../models/study_action_model.dart';
import '../models/study_scheduler.dart';
import '../models/study_session_summary_model.dart';
import '../repositories/study_repository.dart';

/// What to show once a session has ended.
///
/// **Which actions count as wrong is derived, never restated.** `eight_box`
/// spells it `forgotten` and `sm2` spells it `again`, so a query naming either
/// would report a spotless session on half the decks — and the number would look
/// plausible.
///
/// **It is not `binaryAction` either, and that distinction cost a test.**
/// `binaryAction` answers a different question — "turn a right/wrong grade into
/// an action" — and `sm2` returns null for it on purpose, because that algorithm
/// never grades anything itself (BR-106). Asking it here would have counted zero
/// mistakes on every `sm2` deck. The right question is which of the algorithm's
/// own actions are lapses (BR-20), which `StudyAction.isLapse` already answers
/// for both.
class GetSessionSummaryUseCase {
  const GetSessionSummaryUseCase(this._repository);

  final StudyRepository _repository;

  Future<StudySessionSummaryModel> call({
    required String sessionId,
    required SchedulerType schedulerType,
  }) => _repository.sessionSummary(
    sessionId: sessionId,
    wrongActions:
        schedulerFor(
          schedulerType,
        )?.supportedActions.where((action) => action.isLapse).toList() ??
        const <StudyAction>[],
  );
}
