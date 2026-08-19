import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../di/study_repository_provider.dart';
import '../../domain/models/new_card_order_model.dart';
import '../../domain/usecases/clear_study_options_override_use_case.dart';
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

/// Drops the root deck's override so it follows the app defaults again
/// (BR-212).
///
/// **Its own controller, not a method on the one above.** The two are different
/// operations with different outcomes — a save closes the screen, a clear
/// leaves it open showing the app defaults it just adopted — and sharing one
/// submit state would put a spinner on the Save button when the user pressed
/// `Use app defaults`.
@riverpod
class StudyOptionsClearController extends _$StudyOptionsClearController {
  @override
  StudyOptionsSubmitState build(String deckId) =>
      const StudyOptionsSubmitState();

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = const StudyOptionsSubmitState(isSubmitting: true);
    try {
      await ClearStudyOptionsOverrideUseCase(
        ref.read(studyRepositoryProvider),
      ).call(deckId);

      if (!ref.mounted) return;
      // The screen reads the resolved options through `studyOptionsProvider`,
      // which is a `Future` and not a stream, so nothing else would tell it the
      // override is gone.
      ref.invalidate(studyOptionsProvider(deckId));
      // `savedAndContinue`, not `savedAndClose`: the screen stays open on the
      // values it has just adopted, which is the confirmation. Popping would
      // leave the user to go back in and check.
      state = const StudyOptionsSubmitState(
        outcome: SubmitOutcome.savedAndContinue,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = studyOptionsSubmitFailure(failure);
    }
  }
}
