import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/state/submit_outcome.dart';
import '../../../study/domain/models/new_card_order_model.dart';
import '../../di/app_settings_repository_provider.dart';
import '../../domain/models/app_language_model.dart';
import '../../domain/models/app_theme_mode_model.dart';
import '../../domain/usecases/reset_app_settings_use_case.dart';
import '../../domain/usecases/save_language_use_case.dart';
import '../../domain/usecases/save_study_defaults_use_case.dart';
import '../../domain/usecases/save_theme_mode_use_case.dart';
import '../states/settings_submit_state.dart';

part 'settings_write_controller.g.dart';

/// The two study defaults (BR-183), saved together behind one button.
///
/// **One of four controllers in this file, not one controller with four
/// methods.** Each group writes atomically on its own — BR-188 — and carries
/// its own in-flight status; the version that shares one `isSubmitting` for
/// the whole screen is the bug CLAUDE.md names, because tapping Dark would
/// put a spinner on the card-limit button.
///
/// **None of the four validates anything.** The bounds belong to
/// `StudyCardLimit` and are applied by the use case, which reports the broken
/// one as a typed problem. A controller that checked them too would be a second
/// owner of the rule, free to disagree with the first about the same number.
///
/// **Success returns `savedAndContinue`, never `savedAndClose`.** This screen is
/// a tab, not a sheet: there is nothing to pop, and `savedAndClose` latches
/// `canSubmit` shut — which would let a user change the theme exactly once per
/// app launch.
///
/// The two values are saved together because they are one group in the data and
/// one thought for the user; saving half of what somebody just changed is the
/// partial write BR-188 forbids.
@riverpod
class SettingsStudyDefaultsController
    extends _$SettingsStudyDefaultsController {
  @override
  SettingsSubmitState build() => const SettingsSubmitState();

  Future<void> submit({
    required String rawCardLimit,
    required NewCardOrder newCardOrder,
  }) async {
    if (!state.canSubmit) return;

    state = const SettingsSubmitState(isSubmitting: true);
    try {
      await SaveStudyDefaultsUseCase(
        ref.read(appSettingsRepositoryProvider),
      ).call(rawCardLimit: rawCardLimit, newCardOrder: newCardOrder);

      if (!ref.mounted) return;
      // No `invalidate` anywhere in this file: the screen reads a Drift
      // `watch()` stream, so the write re-emits it. Invalidating as well would
      // tear the subscription down and rebuild it for a value already on its
      // way (BR-182).
      state = const SettingsSubmitState(
        outcome: SubmitOutcome.savedAndContinue,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = settingsSubmitFailure(failure);
    }
  }

  /// Clears a failure so the next attempt starts from a clean slate.
  ///
  /// Called by `Try again`, which then submits: without it the error band would
  /// stay on screen through the retry and only disappear when the retry landed.
  void reset() => state = const SettingsSubmitState();
}

/// The theme choice (BR-186). Written on selection, not behind a button.
@riverpod
class SettingsThemeController extends _$SettingsThemeController {
  @override
  SettingsSubmitState build() => const SettingsSubmitState();

  Future<void> submit(AppThemeMode themeMode) async {
    if (!state.canSubmit) return;

    state = const SettingsSubmitState(isSubmitting: true);
    try {
      await SaveThemeModeUseCase(
        ref.read(appSettingsRepositoryProvider),
      ).call(themeMode);

      if (!ref.mounted) return;
      state = const SettingsSubmitState(
        outcome: SubmitOutcome.savedAndContinue,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = settingsSubmitFailure(failure);
    }
  }

  void reset() => state = const SettingsSubmitState();
}

/// The language choice (BR-187). Same shape as the theme, same reasons.
@riverpod
class SettingsLanguageController extends _$SettingsLanguageController {
  @override
  SettingsSubmitState build() => const SettingsSubmitState();

  Future<void> submit(AppLanguage language) async {
    if (!state.canSubmit) return;

    state = const SettingsSubmitState(isSubmitting: true);
    try {
      await SaveLanguageUseCase(
        ref.read(appSettingsRepositoryProvider),
      ).call(language);

      if (!ref.mounted) return;
      state = const SettingsSubmitState(
        outcome: SubmitOutcome.savedAndContinue,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = settingsSubmitFailure(failure);
    }
  }

  void reset() => state = const SettingsSubmitState();
}

/// Back to every default (BR-189).
///
/// Its own controller rather than a fifth method on one of the others, because
/// it fails on its own and its error belongs to its own band — and because a
/// reset in flight must not read as "the theme is saving".
@riverpod
class SettingsResetController extends _$SettingsResetController {
  @override
  SettingsSubmitState build() => const SettingsSubmitState();

  Future<void> submit() async {
    if (!state.canSubmit) return;

    state = const SettingsSubmitState(isSubmitting: true);
    try {
      await ResetAppSettingsUseCase(
        ref.read(appSettingsRepositoryProvider),
      ).call();

      if (!ref.mounted) return;
      state = const SettingsSubmitState(
        outcome: SubmitOutcome.savedAndContinue,
      );
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = settingsSubmitFailure(failure);
    }
  }

  void reset() => state = const SettingsSubmitState();
}
