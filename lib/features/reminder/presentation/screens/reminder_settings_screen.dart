import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_async_view.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_error_state.dart';
import '../../domain/models/reminder_overview_model.dart';
import '../../domain/models/reminder_time_model.dart';
import '../controllers/reminder_disable_controller.dart';
import '../controllers/reminder_enable_controller.dart';
import '../controllers/reminder_overview_controller.dart';
import '../controllers/reminder_time_controller.dart';
import '../states/reminder_submit_state.dart';
import '../widgets/overlays/reminder_time_picker_widget.dart';
import '../widgets/sections/reminder_settings_section_widget.dart';

/// Whether the daily reminder is on, and when it fires (UC-12).
///
/// **Its own route rather than a section of the Settings screen** (M6 R1). The
/// real Settings screen does not exist yet — the branch is a placeholder
/// (AD-19) — and embedding this section into it would make
/// `features/settings/presentation/` import `features/reminder/presentation/`,
/// which is the cross-feature import the boundary check rejects. A route keeps
/// the seam clean: when Settings arrives it keeps one row and changes nothing
/// here.
///
/// **Three command controllers, one screen.** Each command owns its own submit
/// state so a spinner cannot land on the control the user did not touch; this
/// screen is where the three are read together, because one card and one banner
/// is what the user sees.
///
/// Inside the Settings branch, so the bottom bar stays and Back returns to it.
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enable = ref.watch(reminderEnableControllerProvider);
    final disable = ref.watch(reminderDisableControllerProvider);
    final time = ref.watch(reminderTimeControllerProvider);

    return MxContentShell(
      title: context.l10n.reminderTitle,
      // The shell owns the scroll and the gutter (M6 G2, A2). Two rows, a
      // banner and two paragraphs fit a phone at scale 1 and do not at scale 2
      // — and the honest fix for a screen that outgrows its viewport is to let
      // it scroll, not to shrink the copy that carries the disclosure.
      isScrollable: true,
      body: MxAsyncView<ReminderOverviewModel>(
        value: ref.watch(reminderOverviewProvider),
        loadingLabel: context.l10n.reminderTitle,
        error: (_, _) => MxErrorState(
          title: context.l10n.reminderSaveErrorTitle,
          message: context.l10n.reminderSaveErrorMessage,
          retryLabel: context.l10n.reminderRetryAction,
          onRetry: () => ref.invalidate(reminderOverviewProvider),
        ),
        data: (overview) => ReminderSettingsSectionWidget(
          overview: overview,
          // A command is running if any of the three is, and the banner shows
          // whichever one failed. They are mutually exclusive in practice — one
          // card, one control at a time — so "first non-null" is a total answer
          // rather than a choice between two live errors.
          isBusy:
              enable.isSubmitting || disable.isSubmitting || time.isSubmitting,
          rejection: enable.rejection ?? disable.rejection ?? time.rejection,
          onEnabledChanged: (isEnabled) =>
              _setEnabled(ref, overview, isEnabled: isEnabled),
          onTimePressed: (current) =>
              unawaited(_pickTime(context, ref, current)),
          onRetry: () => _setEnabled(ref, overview, isEnabled: true),
        ),
      ),
    );
  }

  /// The toggle, and the banner's retry — which is the same command.
  ///
  /// Enabling carries the currently stored time, so the value the user was
  /// looking at is the one that gets scheduled. Both banners are cleared first:
  /// a failure from turning it off has nothing to say about turning it on.
  void _setEnabled(
    WidgetRef ref,
    ReminderOverviewModel overview, {
    required bool isEnabled,
  }) {
    ref.read(reminderDisableControllerProvider.notifier).reset();
    ref.read(reminderEnableControllerProvider.notifier).reset();

    unawaited(
      isEnabled
          ? ref
                .read(reminderEnableControllerProvider.notifier)
                .submit(overview.settings.time)
          : ref.read(reminderDisableControllerProvider.notifier).submit(),
    );
  }

  /// Opens the picker and applies the result.
  ///
  /// `async` rather than fire-and-forget because the dialog's result is the
  /// input to the command; the `context.mounted` guard is what stops the second
  /// half running against a screen the user left while the dialog was open.
  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderTime current,
  ) async {
    final picked = await showReminderTimePicker(context, current);
    if (picked == null || !context.mounted) return;

    final controller = ref.read(reminderTimeControllerProvider.notifier);
    controller.reset();

    await controller.submit(picked);
  }
}
