import '../../../../core/error/failure.dart';
import '../../../study/domain/models/new_card_order_model.dart';
import '../../../study/domain/models/study_card_limit_model.dart';
import '../repositories/app_settings_repository.dart';

/// Changes the app-wide study defaults (BR-183).
///
/// **The bounds are Study's, run through Study's type.** `StudyCardLimit.parse`
/// is the only parser for this number in the app; a second one here would be a
/// second answer to "is 500 allowed", and the two screens that edit this value
/// — this one and the deck's own options — would be free to disagree (BR-183).
///
/// **This writes `app_settings` and nothing else.** A root deck carrying an
/// override keeps it, and clearing that override is a different action on a
/// different surface (BR-184).
///
/// **Sessions already running are untouched** (BR-185). A session fixes its
/// ceiling into `study_sessions.card_limit` when it opens (BR-139), so there is
/// no write here that could move one — which is why this use case has nothing
/// to say about sessions rather than having a guard about them.
class SaveStudyDefaultsUseCase {
  const SaveStudyDefaultsUseCase(this._repository);

  final AppSettingsRepository _repository;

  /// `async`, so an invalid limit arrives as a failed future rather than a
  /// synchronous throw — the same reason `SaveStudyOptionsUseCase` gives: a
  /// caller using `unawaited(...)` sees a synchronous throw as an uncaught
  /// error at the call site, which is not where anybody is looking for it.
  Future<void> call({
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

    return _repository.saveStudyDefaults(
      cardLimit: parsed.limit!,
      newCardOrder: newCardOrder,
    );
  }
}
