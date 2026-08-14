import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../../study/domain/models/new_card_order_model.dart';
import '../../domain/models/app_language_model.dart';
import '../../domain/models/app_settings_model.dart';
import '../../domain/models/app_theme_mode_model.dart';
import '../controllers/app_settings_controller.dart';
import '../controllers/settings_write_controller.dart';
import '../states/settings_submit_state.dart';
import '../widgets/overlays/settings_reset_confirm_widget.dart';
import '../widgets/sections/settings_choice_section_widget.dart';
import '../widgets/sections/settings_reset_section_widget.dart';
import '../widgets/sections/settings_study_defaults_section_widget.dart';
import '../widgets/support/settings_labels_widget.dart';

/// The app's global options (UC-12).
///
/// Replaces the placeholder that stood here since M3 (AD-19). The branch, its
/// path and its position in the shell are unchanged — which is what that
/// decision was betting on.
///
/// **One read for the whole screen** (AD-13, BR-182). Four values, one row, one
/// stream: three groups reading three providers would be three snapshots, and
/// the screen could then show a theme from after a write beside a card limit
/// from before it.
///
/// **Four writes, four controllers.** Each group locks only itself while it is
/// saving and carries only its own failure (BR-188, wireframe S7, S8).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  /// The gap between one group and the next heading, and between the last card
  /// and the reset action. Named because the geometry contract measures it.
  static const double sectionGap = AppSpacing.xl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MxContentShell(
      title: context.l10n.settingsTitle,
      isScrollable: true,
      body: MxAsyncView<AppSettingsModel>(
        value: ref.watch(appSettingsProvider),
        loadingLabel: context.l10n.settingsLoadingLabel,
        error: (_, _) => MxErrorState(
          title: context.l10n.settingsLoadErrorTitle,
          message: context.l10n.writeErrorMessage,
          retryLabel: context.l10n.retryAction,
          // Rebuilding the provider, not re-navigating: the stream failed, and
          // a fresh subscription is the only thing that can change the answer.
          onRetry: () => ref.invalidate(appSettingsProvider),
        ),
        data: (settings) => _Body(settings: settings),
      ),
    );
  }
}

/// The three groups and the reset action.
///
/// Split from the screen so the async boundary above holds exactly one thing:
/// with the body inline, every `ref.watch` of a write controller would sit
/// inside the builder of the read, and a rebuild of one would rebuild all four.
class _Body extends ConsumerWidget {
  const _Body({required this.settings});

  final AppSettingsModel settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studyDefaults = ref.watch(settingsStudyDefaultsControllerProvider);
    final theme = ref.watch(settingsThemeControllerProvider);
    final language = ref.watch(settingsLanguageControllerProvider);
    final reset = ref.watch(settingsResetControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SettingsStudyDefaultsSectionWidget(
          initialCardLimit: settings.cardLimit,
          initialNewCardOrder: settings.newCardOrder,
          isSubmitting: studyDefaults.isSubmitting,
          cardLimitProblem: studyDefaults.cardLimitProblem,
          failure: studyDefaults.failure,
          onSave: (rawCardLimit, newCardOrder) => _saveStudyDefaults(
            ref,
            rawCardLimit: rawCardLimit,
            newCardOrder: newCardOrder,
          ),
        ),
        const SizedBox(height: SettingsScreen.sectionGap),
        SettingsChoiceSectionWidget<AppThemeMode>(
          sectionLabel: context.l10n.settingsAppearanceSection,
          values: AppThemeMode.values,
          selected: settings.themeMode,
          labelOf: context.themeModeLabel,
          isSubmitting: theme.isSubmitting,
          failure: theme.failure,
          onChanged: (mode) => _saveTheme(ref, mode),
        ),
        const SizedBox(height: SettingsScreen.sectionGap),
        SettingsChoiceSectionWidget<AppLanguage>(
          sectionLabel: context.l10n.settingsLanguageSection,
          values: AppLanguage.values,
          selected: settings.language,
          labelOf: context.languageLabel,
          isSubmitting: language.isSubmitting,
          failure: language.failure,
          onChanged: (value) => _saveLanguage(ref, value),
        ),
        const SizedBox(height: SettingsScreen.sectionGap),
        SettingsResetSectionWidget(
          isSubmitting: reset.isSubmitting,
          failure: reset.failure,
          onReset: () => unawaited(_openResetConfirm(context, ref)),
          onRetry: () => unawaited(_openResetConfirm(context, ref)),
        ),
      ],
    );
  }

  /// The notifiers are read when a control is used, never during a build.
  ///
  /// `ref.read` inside `build()` takes a value without subscribing, which is how
  /// a screen ends up showing state it will never be told has changed — the
  /// guard rule `no_ref_read_in_build` exists for exactly that.
  void _saveStudyDefaults(
    WidgetRef ref, {
    required String rawCardLimit,
    required NewCardOrder newCardOrder,
  }) => unawaited(
    ref
        .read(settingsStudyDefaultsControllerProvider.notifier)
        .submit(rawCardLimit: rawCardLimit, newCardOrder: newCardOrder),
  );

  void _saveTheme(WidgetRef ref, AppThemeMode mode) => unawaited(
    ref.read(settingsThemeControllerProvider.notifier).submit(mode),
  );

  void _saveLanguage(WidgetRef ref, AppLanguage language) => unawaited(
    ref.read(settingsLanguageControllerProvider.notifier).submit(language),
  );

  /// Clears the previous attempt **before** asking again.
  ///
  /// Without this the dialog would find a latched outcome from the last reset
  /// and close on its own frame, and a stale error band would still be under
  /// it. Re-asking is a fresh attempt, so it starts from a clean state.
  Future<void> _openResetConfirm(BuildContext context, WidgetRef ref) async {
    ref.read(settingsResetControllerProvider.notifier).reset();

    return showSettingsResetConfirm(context);
  }
}
