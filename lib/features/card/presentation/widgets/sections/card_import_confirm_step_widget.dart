import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../controllers/card_import_commit_controller.dart';
import 'card_import_submit_progress_widget.dart';

/// Step 3 — confirm and submit (UC-10 steps 6–7).
///
/// Two faces, switched by the commit's own state: the confirm summary while
/// nothing runs, and the one submit panel while the transaction is in flight
/// (state 5). Every outcome — success, skips, zero added, failure — is the
/// screen's result mode, not this step's: once the commit resolves, the
/// screen stops rendering this widget at all. No per-row progress is ever
/// faked — the batch is atomic, so there is nothing honest to count up (W4).
class CardImportConfirmStepWidget extends ConsumerWidget {
  const CardImportConfirmStepWidget({
    required this.deckId,
    required this.deckName,
    required this.preview,
    required this.shouldIncludeDuplicates,
    super.key,
  });

  final String deckId;
  final String deckName;
  final CardImportPreview preview;
  final bool shouldIncludeDuplicates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submit = ref.watch(commitCardImportProvider(deckId));
    final l10n = context.l10n;
    final willWrite = preview.importableCount(
      shouldIncludeDuplicates: shouldIncludeDuplicates,
    );

    // The commit in flight replaces the whole confirmation (state 5): the
    // one loader, the count it is writing, and the don't-close line — the
    // sticky bar's disabled "Importing…" is a state, not a second spinner.
    if (submit.isSubmitting) {
      return CardImportSubmitProgressWidget(count: willWrite);
    }

    // The same summary-row language the result faces speak (states 6-7):
    // one grouped card, an icon-led row per fact, the count on the trailing
    // edge — so Confirm, Result and Preview read as one family, not three
    // designs. Zero counts stay visible on purpose: this is the contract
    // being agreed to, and "Blank rows ignored 0" is part of it.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.cardImportConfirmHeading, style: context.texts.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        MxCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Text(
                  l10n.cardImportConfirmTargetLabel(deckName),
                  style: context.texts.titleSmall,
                ),
              ),
              _ConfirmRow(
                icon: Icons.check,
                color: AppInk.secondary,
                label: l10n.cardImportConfirmImportRowLabel,
                count: willWrite,
              ),
              _ConfirmRow(
                icon: Icons.copy_outlined,
                color: AppInk.tertiary,
                label: shouldIncludeDuplicates
                    ? l10n.cardImportConfirmDuplicatesIncludedRowLabel
                    : l10n.cardImportDuplicatesSkippedRowLabel,
                count: preview.duplicateCount,
              ),
              _ConfirmRow(
                icon: Icons.error_outline,
                color: AppInk.error,
                label: l10n.cardImportInvalidSkippedRowLabel,
                count: preview.invalidCount,
              ),
              _ConfirmRow(
                icon: Icons.remove,
                color: AppInk.quiet,
                label: l10n.cardImportBlankIgnoredRowLabel,
                count: preview.blankCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One fact of the plan: icon, label, and the count on the trailing edge —
/// the result faces' `_SummaryRow` geometry, restated here because the two
/// widgets deliberately share a *language*, not a class: Confirm's rows are
/// the plan, Result's are the transaction's answer, and coupling them would
/// let one screen's edit silently restyle the other.
class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final AppInk color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final countLabel = '$count';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          // `sm` is the same 16 `AppSpacing.lg` used to spell here.
          MxIcon(icon, ink: color, size: MxIconSize.sm),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.texts.bodyMedium)),
          Text(
            countLabel,
            style: context.texts.titleSmall!.inked(context, color),
          ),
        ],
      ),
    );
  }
}
