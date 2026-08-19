import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../controllers/settings_write_controller.dart';
import '../../states/settings_submit_state.dart';

/// Asks before putting every app option back to its default (BR-217, UC-16 A3).
///
/// **The message names what is *not* touched.** Two actions in this app begin
/// with the word "Reset", and the other one increments a scheduler generation
/// and clears every card's schedule (BR-42). Saying "your decks and learning
/// progress are not affected" is the only thing that tells them apart at the
/// moment of the decision.
///
/// `MxConfirmDialog`, the app's confirmation idiom, in its destructive variant
/// — the same one Deck's delete uses. Nothing new is built here.
///
/// **The dialog closes on success and the error stays behind it.** A failed
/// reset shows in the reset group's own error band with `Try again`; a dialog
/// that stayed open to carry the failure would hold the user inside a decision
/// they have already made (wireframe W4).
Future<void> showSettingsResetConfirm(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) =>
      _SettingsResetDialog(onClose: () => Navigator.of(dialogContext).pop()),
);

class _SettingsResetDialog extends ConsumerWidget {
  const _SettingsResetDialog({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submit = ref.watch(settingsResetControllerProvider);

    // Watching the transition rather than acting inside `submit` is what keeps
    // the controller free of a `BuildContext` it must never hold.
    ref.listen<SettingsSubmitState>(settingsResetControllerProvider, (
      previous,
      next,
    ) {
      // **Close on a failure too.** The first version returned early whenever
      // `outcome` was null, and `submitStateFromFailure` produces exactly that
      // — a state carrying a `failure` and no outcome. So a failed reset left
      // the dialog standing, unchanged and silent, while the error band and its
      // retry rendered on the section *behind* the scrim. The band is where W4
      // says the failure belongs, and it can only be read once this is gone.
      final bool hasSettled = next.outcome != null || next.failure != null;
      final bool hasSettledAlready =
          previous?.outcome != null || previous?.failure != null;
      if (!hasSettled || hasSettledAlready) return;
      onClose();
    });

    return MxConfirmDialog(
      title: context.l10n.settingsResetConfirmTitle,
      message: context.l10n.settingsResetDescription,
      confirmLabel: context.l10n.settingsResetConfirmAction,
      cancelLabel: context.l10n.commonCancelAction,
      variant: MxConfirmDialogVariant.destructive,
      isSubmitting: submit.isSubmitting,
      onConfirm: () => _confirm(ref),
      onCancel: onClose,
    );
  }

  /// The notifier, read when the button is pressed rather than during a build.
  ///
  /// A method rather than an inline closure: `ref.read` inside `build()` takes
  /// a value without subscribing, and the guard rule `no_ref_read_in_build`
  /// cannot tell a read that happens *during* a build from one that happens in
  /// a callback declared there. Naming the callback makes the difference
  /// visible to a reader as well as to the guard.
  void _confirm(WidgetRef ref) =>
      unawaited(ref.read(settingsResetControllerProvider.notifier).submit());
}
