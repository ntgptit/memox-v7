import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../../domain/entities/deck_entity.dart';
import '../../../domain/models/scheduler_type_model.dart';
import '../../controllers/deck_write_controller.dart';
import '../../states/deck_submit_state.dart';
import '../items/deck_scheduler_picker_widget.dart';
import '../support/deck_labels_widget.dart';

/// Confirmation for the one-way branch-to-root conversion (UC-23).
Future<void> showDeckPromoteSubDeckConfirm(
  BuildContext context, {
  required DeckEntity deck,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => _PromoteSubDeckSheet(
    deck: deck,
    onClose: () => Navigator.of(sheetContext).pop(),
  ),
);

class _PromoteSubDeckSheet extends ConsumerStatefulWidget {
  const _PromoteSubDeckSheet({required this.deck, required this.onClose});

  final DeckEntity deck;
  final VoidCallback onClose;

  @override
  ConsumerState<_PromoteSubDeckSheet> createState() =>
      _PromoteSubDeckSheetState();
}

class _PromoteSubDeckSheetState extends ConsumerState<_PromoteSubDeckSheet> {
  SchedulerType _scheduler = SchedulerType.eightBox;

  @override
  Widget build(BuildContext context) {
    final provider = promoteSubDeckToRootControllerProvider(widget.deck.id);
    final submit = ref.watch(provider);
    ref.listen<DeckSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        widget.onClose();
      }
    });

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                context.l10n.deckPromoteTitle,
                style: context.texts.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.deckPromoteBody,
                style: context.texts.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.deckPromoteHistoryNotice,
                style: context.texts.bodySmall!.inked(context, AppInk.quiet),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.deckPromoteSchedulerLabel,
                style: context.texts.labelLarge,
              ),
              DeckSchedulerPickerWidget(
                sectionLabel: null,
                selected: _scheduler,
                isEnabled: !submit.isSubmitting,
                shouldShowLockNotice: false,
                onChanged: (value) =>
                    setState(() => _scheduler = value ?? _scheduler),
              ),
              if (submit.failure case final failure?) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.deckWriteFailure(failure),
                  style: context.texts.bodySmall!.inked(context, AppInk.danger),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              MxButtonPair(
                primary: MxActionButton(
                  label: context.l10n.deckPromoteConfirm,
                  variant: MxActionButtonVariant.destructive,
                  isLoading: submit.isSubmitting,
                  onPressed: submit.isSubmitting
                      ? null
                      : () => ref
                            .read(provider.notifier)
                            .submit(schedulerType: _scheduler),
                ),
                secondary: MxActionButton(
                  label: context.l10n.commonCancelAction,
                  variant: MxActionButtonVariant.secondary,
                  onPressed: submit.isSubmitting ? null : widget.onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
