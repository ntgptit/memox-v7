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
import '../controllers/reminder_time_draft_controller.dart';
import '../states/reminder_submit_state.dart';
import '../widgets/overlays/reminder_time_picker_widget.dart';
import '../widgets/sections/reminder_settings_section_widget.dart';

/// Whether the daily reminder is on, and when it fires (UC-17).
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
/// is what the user sees. The banner's retry is dispatched back to the command
/// that produced it — a single hardwired retry turned "turning it off failed"
/// into "turn it on again", which is the opposite of what the user asked for.
class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enable = ref.watch(reminderEnableControllerProvider);
    final disable = ref.watch(reminderDisableControllerProvider);
    final time = ref.watch(reminderTimeControllerProvider);
    // Watched rather than only read, and the value is deliberately unused here:
    // the draft is auto-dispose, and a provider nothing subscribes to is
    // disposed the frame after `_pickTime` writes it — so the retry read `null`
    // every time and silently re-submitted the stored time. The subscription is
    // what gives it the screen's lifetime, and popping the route still clears
    // it.
    ref.watch(reminderTimeDraftControllerProvider);

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
        // **The read failed, so the save copy is the wrong sentence.** "Your
        // change wasn't saved" describes an event that has not happened: the
        // user has changed nothing, the screen simply could not be filled in.
        // `settingsLoadErrorTitle` says the same thing one screen up, and this
        // is its counterpart.
        error: (_, _) => MxErrorState(
          title: context.l10n.reminderLoadErrorTitle,
          message: context.l10n.writeErrorMessage,
          retryLabel: context.l10n.retryAction,
          onRetry: () => ref.invalidate(reminderOverviewProvider),
        ),
        data: (overview) => ReminderSettingsSectionWidget(
          overview: overview,
          // A command is running if any of the three is. They are mutually
          // exclusive in practice — one card, one control at a time — and each
          // submit clears the other two, so at most one rejection is ever live.
          isBusy:
              enable.isSubmitting || disable.isSubmitting || time.isSubmitting,
          rejection: enable.rejection ?? disable.rejection ?? time.rejection,
          onEnabledChanged: (isEnabled) =>
              _setEnabled(ref, overview, isEnabled: isEnabled),
          onTimePressed: (current) =>
              unawaited(_pickTime(context, ref, current)),
          onRetry: () => _retry(ref, overview),
        ),
      ),
    );
  }

  /// The toggle.
  ///
  /// Enabling carries the currently stored time, so the value the user was
  /// looking at is the one that gets scheduled.
  void _setEnabled(
    WidgetRef ref,
    ReminderOverviewModel overview, {
    required bool isEnabled,
  }) {
    // Clear the *other* commands' banners, never this one's: `reset()` on the
    // controller about to run would also clear `isSubmitting`, which is the
    // double-submit guard, and two concurrent enables mean two permission
    // prompts and two interleaved compensating writes (BR-227, BR-228).
    ref.read(reminderTimeControllerProvider.notifier).reset();

    if (!isEnabled) {
      ref.read(reminderEnableControllerProvider.notifier).reset();

      return unawaited(
        ref.read(reminderDisableControllerProvider.notifier).submit(),
      );
    }

    ref.read(reminderDisableControllerProvider.notifier).reset();

    unawaited(
      ref
          .read(reminderEnableControllerProvider.notifier)
          .submit(overview.settings.time),
    );
  }

  /// Opens the picker and applies the result.
  ///
  /// `async` rather than fire-and-forget because the dialog's result is the
  /// input to the command; the `context.mounted` guard is what stops the second
  /// half running against a screen the user left while the dialog was open.
  ///
  /// The picked value is remembered before it is submitted, so a failed
  /// reschedule — which rolls the stored time back — still has the user's
  /// choice to retry with.
  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    ReminderTime current,
  ) async {
    final picked = await showReminderTimePicker(context, current);
    if (picked == null || !context.mounted) return;

    ref.read(reminderTimeDraftControllerProvider.notifier).remember(picked);
    ref.read(reminderEnableControllerProvider.notifier).reset();
    ref.read(reminderDisableControllerProvider.notifier).reset();

    await ref.read(reminderTimeControllerProvider.notifier).submit(picked);
  }

  /// The banner's recovery: re-run **the command that failed**, not a fixed one.
  ///
  /// Three commands can produce a retryable rejection, and hardwiring the retry
  /// to enable meant a failed cancel offered the user a button that turned the
  /// reminder back on. Reading which controller holds the rejection is the only
  /// thing that makes "Try again" mean what the copy says it means (UC-17 E3).
  void _retry(WidgetRef ref, ReminderOverviewModel overview) {
    if (ref.read(reminderDisableControllerProvider).rejection != null) {
      return _setEnabled(ref, overview, isEnabled: false);
    }

    if (ref.read(reminderTimeControllerProvider).rejection != null) {
      final draft = ref.read(reminderTimeDraftControllerProvider);
      ref.read(reminderEnableControllerProvider.notifier).reset();
      ref.read(reminderDisableControllerProvider.notifier).reset();

      return unawaited(
        ref
            .read(reminderTimeControllerProvider.notifier)
            .submit(draft ?? overview.settings.time),
      );
    }

    _setEnabled(ref, overview, isEnabled: true);
  }
}
