import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/study_session_summary_model.dart';
import '../../domain/usecases/get_session_summary_use_case.dart';
import 'study_session_controller.dart';

part 'study_session_summary_controller.g.dart';

/// What a session came to, read once it has ended.
///
/// **A query, and it was living in a command.** `StudySessionController` held
/// the read, the field it landed in, and three call sites that had to remember
/// to run it — one of them inside a failure path, where forgetting would have
/// shown a summary belonging to the previous session. None of that is state the
/// controller owns: the numbers are in the database, and the session is over.
///
/// Moving it out is what finally took that controller under the 400-line guard,
/// but the reason it *could* move is the one that matters: a session's epilogue
/// is not a command, and the screen asks for it exactly when it needs it.
///
/// **Read back rather than accumulated.** A tally in the controller would be a
/// second copy of numbers the database holds, and the two disagree the moment a
/// write is refused. `status` comes from the same statement, so a session that
/// ended by failing cannot be summarised as one that finished.
///
/// Null rather than an error when the read fails: the session has genuinely
/// ended, and refusing to say so because the epilogue could not be read is the
/// worse answer. `noAutomaticRetry` for the same reason — a summary that cannot
/// be read now will not read differently in thirteen seconds.
///
/// **Keyed by the deck, and it reads the session off the controller.** A family
/// key is compared by identity, so anything but a String or an int caches a new
/// entry on every rebuild — `provider_convention_test.dart` holds that line, and
/// a pair of named parameters is a record key. Taking the session id and the
/// scheduler from the controller instead keeps the key primitive and stops them
/// being a second copy of two facts that already have an owner.
///
/// It is `autoDispose`, and the screen watches it only in the finished branch —
/// so it is created when the session is already over and the state it depends on
/// has stopped changing.
@Riverpod(retry: noAutomaticRetry)
Future<StudySessionSummaryModel?> studySessionSummary(
  Ref ref,
  String deckId,
) async {
  final state = ref.watch(studySessionControllerProvider(deckId));
  final session = state.session;
  if (session == null) return null;

  try {
    return await GetSessionSummaryUseCase(
      ref.read(studyRepositoryProvider),
    ).call(sessionId: session.id, schedulerType: state.schedulerType);
  } on Object catch (_) {
    // Narrow by intent, not by type: every failure here has the same answer,
    // which is to show the end of the session without counts.
    return null;
  }
}
