import '../../../../core/error/failure.dart';
import '../models/new_card_order_model.dart';
import '../models/study_card_limit_model.dart';
import '../repositories/study_repository.dart';

/// Changes the study options of a deck's root (BR-147).
///
/// **The bounds run here and nowhere else.** The controller does not check them
/// and neither does the repository — the repository takes a [StudyCardLimit],
/// which cannot exist without having passed. A screen that re-derived which
/// bound was broken, to decide which field to mark, would make presentation a
/// second owner of the rule; the failure carries the problem instead.
///
/// **This does not touch the running session** (BR-139). A session fixes its
/// ceiling once, at the moment it opens, into `study_sessions.card_limit` — so
/// changing the preference mid-session cannot move the finish line the user is
/// already walking towards.
class SaveStudyOptionsUseCase {
  const SaveStudyOptionsUseCase(this._repository);

  final StudyRepository _repository;

  /// `async`, so an invalid limit arrives as a failed future rather than a
  /// synchronous throw. The two are not interchangeable: a caller that does not
  /// await immediately — `unawaited(save(...))` — sees the synchronous form as
  /// an uncaught error at the call site, which is not where anybody is looking
  /// for it.
  Future<void> call({
    required String deckId,
    required String rawCardLimit,
    required NewCardOrder newCardOrder,
  }) async {
    final parsed = StudyCardLimit.parse(rawCardLimit);
    final problem = parsed.problem;
    if (problem != null) {
      throw ValidationFailure(
        message: 'Card limit is out of range',
        problems: <Enum>{problem},
      );
    }

    return _repository.saveStudyOptions(
      deckId: deckId,
      cardLimit: parsed.limit!,
      newCardOrder: newCardOrder,
    );
  }
}
