import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/new_card_order_model.dart';
import '../../domain/usecases/save_study_options_use_case.dart';
import '../states/study_options_submit_state.dart';
import 'study_options_controller.dart';

part 'study_options_write_controller.g.dart';

/// Saves the study options (BR-147).
///
/// It validates nothing: the bounds belong to `StudyCardLimit` and are applied
/// by the use case, which reports the broken one as a typed problem. A
/// controller that checked them too would be a second owner of the rule, free to
/// disagree with the first about the same number.
@riverpod
class StudyOptionsWriteController extends _$StudyOptionsWriteController {
  @override
  StudyOptionsSubmitState build(String deckId) =>
      const StudyOptionsSubmitState();

  Future<void> submit({
    required String rawCardLimit,
    required NewCardOrder newCardOrder,
  }) async {
    if (!state.canSubmit) return;

    state = const StudyOptionsSubmitState(isSubmitting: true);
    try {
      await SaveStudyOptionsUseCase(ref.read(studyRepositoryProvider)).call(
        deckId: deckId,
        rawCardLimit: rawCardLimit,
        newCardOrder: newCardOrder,
      );

      if (!ref.mounted) return;
      // The screen reads the same options through `studyOptionsProvider`;
      // without this it would keep showing the values from before the save
      // until something else happened to invalidate it.
      ref.invalidate(studyOptionsProvider(deckId));
      state = const StudyOptionsSubmitState(
        outcome: SubmitOutcome.savedAndClose,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = studyOptionsSubmitFailure(failure);
    }
  }
}
