import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_confirm_dialog.dart';
import '../../../../../shared/widgets/mx_dialog_tone.dart';
import '../../../../../shared/widgets/mx_sheet_insets.dart';
import '../../../domain/models/deck_template_model.dart';
import '../../../domain/models/scheduler_type_model.dart';
import '../../../domain/repositories/deck_template_repository.dart';
import '../../controllers/starter_library_controller.dart';
import '../items/deck_scheduler_picker_widget.dart';

/// The one question a copy needs answered before it exists: which schedule.
///
/// A sheet rather than an inline control because the choice is consequential —
/// it locks after the first review (BR-05) — and because the template only
/// *suggests* a default (BR-34): the moment of copying is the one moment the
/// user actually owns the decision.
///
/// Returns what the install did, or null when it was cancelled or failed —
/// the caller draws nothing for null, because nothing happened.
Future<DeckTemplateInstallOutcome?> showStarterInstallSheet(
  BuildContext context, {
  required DeckTemplate template,
  bool shouldAllowDuplicate = false,
}) => showModalBottomSheet<DeckTemplateInstallOutcome>(
  context: context,
  isScrollControlled: true,
  // **This sheet used to clear the keyboard and nothing else.** It has no text
  // field, so `viewInsets.bottom` was always zero and there was no `SafeArea`
  // either — which put the scheduler picker's primary action underneath the
  // Android navigation bar on every device that has one. `MxSheetInsets` is the
  // one place that formula lives now.
  builder: (sheetContext) => MxSheetInsets(
    child: SingleChildScrollView(
      child: _StarterInstallForm(
        template: template,
        shouldAllowDuplicate: shouldAllowDuplicate,
      ),
    ),
  ),
);

/// The BR-38 confirmation: a copy exists, and only a deliberate yes makes a
/// second one.
///
/// Returns true only for the explicit confirm. The dialog names the fact —
/// "already in your library" — because the rule is about informed intent: a
/// user who re-taps a starter by accident must land on Cancel, not on a
/// duplicate.
Future<bool> showStarterAddAgainConfirm(BuildContext context) {
  final l10n = context.l10n;

  return showMxConfirm(
    context,
    title: l10n.starterLibraryAlreadyInstalledTitle,
    message: l10n.starterLibraryAlreadyInstalledMessage,
    confirmLabel: l10n.starterLibraryAddAgainAction,
    cancelLabel: l10n.commonCancelAction,
    // **The two axes disagreeing, which is why there are two.** Nothing is
    // destroyed and nothing is hidden, so the severity is `info` — the dialog
    // reports a fact the tile the user just tapped could not show them. But a
    // stray Enter still leaves a duplicate deck to find and delete, so the
    // action axis is `cautious`: Cancel keeps the focus, without the
    // destructive colour that would overstate what is happening.
    //
    // This is what the function's own doc has always promised — "a user who
    // re-taps a starter by accident must land on Cancel" — and what the bare
    // `AlertDialog` it used to build did not do.
    variant: MxConfirmDialogVariant.cautious,
    tone: MxDialogTone.info,
  );
}

class _StarterInstallForm extends ConsumerStatefulWidget {
  const _StarterInstallForm({
    required this.template,
    required this.shouldAllowDuplicate,
  });

  final DeckTemplate template;

  /// True only after the BR-38 confirm: this install is a deliberate second
  /// copy, and the repository may skip its idempotency short-circuit for it.
  final bool shouldAllowDuplicate;

  @override
  ConsumerState<_StarterInstallForm> createState() =>
      _StarterInstallFormState();
}

class _StarterInstallFormState extends ConsumerState<_StarterInstallForm> {
  /// Starts at the template's suggestion (BR-34) and belongs to the user from
  /// there.
  late SchedulerType _scheduler = widget.template.defaultSchedulerType;

  Future<void> _install() async {
    final outcome = await ref
        .read(starterInstallControllerProvider.notifier)
        .install(
          widget.template,
          schedulerType: _scheduler,
          allowDuplicate: widget.shouldAllowDuplicate,
        );
    if (!mounted || outcome == null) return;

    // Success closes the sheet and hands the outcome to the caller; a failure
    // keeps the sheet up with its error line and the button live for a retry.
    Navigator.of(context).pop(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final install = ref.watch(starterInstallControllerProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(widget.template.title.value, style: context.texts.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.starterLibraryCardCount(widget.template.cardCount),
          style: context.texts.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.starterLibrarySchedulerPrompt,
          style: context.texts.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DeckSchedulerPickerWidget(
          // Titled two lines up as "Review schedule".
          sectionLabel: null,
          selected: _scheduler,
          isEnabled: !install.isInstalling,
          // The picker's callback is nullable for its disabled branch; a null
          // here would be a choice nobody made, so it is ignored rather than
          // stored.
          onChanged: (value) {
            if (value == null) return;
            setState(() => _scheduler = value);
          },
        ),
        if (install.error != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.starterLibraryInstallFailed,
            style: context.texts.bodySmall?.copyWith(
              color: context.semanticColors.danger,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        MxActionButton(
          label: context.l10n.starterLibraryInstallAction,
          isLoading: install.isInstalling,
          onPressed: install.isInstalling ? null : _install,
        ),
      ],
    );
  }
}
