import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
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
  builder: (sheetContext) => Padding(
    padding: EdgeInsets.only(
      left: AppSpacing.lg,
      right: AppSpacing.lg,
      top: AppSpacing.lg,
      bottom: AppSpacing.lg + MediaQuery.viewInsetsOf(sheetContext).bottom,
    ),
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
Future<bool> showStarterAddAgainConfirm(BuildContext context) async =>
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.starterLibraryAlreadyInstalledTitle),
        content: Text(dialogContext.l10n.starterLibraryAlreadyInstalledMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.starterLibraryAddAgainAction),
          ),
        ],
      ),
    ) ??
    false;

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
