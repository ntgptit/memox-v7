import 'package:flutter/material.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_metric_well.dart';
import '../../../domain/models/card_import_result_model.dart';
import '../../states/card_import_state.dart';
import '../support/card_import_labels_widget.dart';

/// The wizard's outcome face (M4.12 states 6–8): a hero that says what
/// happened, summary rows that say how much, and — only when it helps — a
/// hint that says what to do about it. Rendered in place of the wizard
/// chrome, in the same route: an outcome is a mode of the import, not a
/// destination of its own.
///
/// **Two count sources, kept apart on purpose.** Imported and
/// duplicates-skipped come from the transaction's own result — the recheck
/// inside it is the only honest witness (BR-170). Invalid and blank come
/// from the preview, because the commit never saw those rows at all.
class CardImportResultWidget extends StatelessWidget {
  const CardImportResultWidget({
    required this.phase,
    required this.deckName,
    required this.result,
    required this.invalidCount,
    required this.blankCount,
    this.failure,
    super.key,
  });

  final CardImportPhase phase;
  final String deckName;

  /// Null exactly when [phase] is [CardImportPhase.commitFailure].
  final CardImportResult? result;

  final int invalidCount;
  final int blankCount;
  final Failure? failure;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final commit = result;
    // The hint follows the cause (state 7): invalid rows are the user's to
    // fix in the source; duplicates were skipped *by their own setting* and
    // are never framed as a broken file. Blank-only gets no hint - blank
    // rows are skipped by design (BR-169).
    final String? helperCopy = phase == CardImportPhase.completed
        ? null
        : invalidCount > 0
        ? l10n.cardImportFixInvalidHint
        : (commit?.duplicatesSkipped ?? 0) > 0
        ? l10n.cardImportDuplicatesHint
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _HeroCard(phase: phase, deckName: deckName, result: commit),
        if (phase == CardImportPhase.commitFailure &&
            failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Text(
            context.cardImportFailureLabel(failure!),
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            textAlign: TextAlign.center,
          ),
        ],
        if (commit != null) ...<Widget>[
          // `xl` between bands, both here and before the hint below: the hero,
          // the counts and the hint are three sections of one result, not
          // three surfaces of one control. It is the step the wizard's other
          // two faces already take (card_import_source_step_widget.dart,
          // card_import_preview_step_widget.dart) and the rhythm Card Detail
          // set for three stacked surfaces — `md` bound them tight enough to
          // read as one. The `md` above the failure sentence stays: that line
          // is the hero's caption, not a band of its own.
          const SizedBox(height: AppSpacing.xl),
          _SummaryCard(
            result: commit,
            invalidCount: invalidCount,
            blankCount: blankCount,
          ),
          if (helperCopy != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xl),
            MxCard.muted(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const MxIcon(Icons.info_outline, size: MxIconSize.sm),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(helperCopy, style: context.texts.bodySmall),
                  ),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// The hero (states 6–8): one icon, one title, one sentence — which face is
/// on screen is the phase's whole story.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.phase,
    required this.deckName,
    required this.result,
  });

  final CardImportPhase phase;
  final String deckName;
  final CardImportResult? result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (
      IconData heroIcon,
      AppInk heroColor,
      String title,
      String body,
    ) = switch (phase) {
      CardImportPhase.completed => (
        Icons.check_circle_outline,
        AppInk.secondary,
        l10n.cardImportSuccessTitle,
        l10n.cardImportSuccessBody(result!.imported, deckName),
      ),
      CardImportPhase.completedWithSkips => (
        Icons.warning_amber_outlined,
        AppInk.tertiary,
        l10n.cardImportSkipsTitle,
        l10n.cardImportSkipsBody(result!.imported),
      ),
      CardImportPhase.noCardsAdded => (
        Icons.info_outline,
        AppInk.tertiary,
        l10n.cardImportZeroTitle,
        l10n.cardImportZeroBody,
      ),
      _ => (
        Icons.error_outline,
        AppInk.error,
        l10n.cardImportFailureTitle,
        l10n.cardImportFailureBody,
      ),
    };

    // Flat like the whole outcome column (D20). The tone lives in the icon
    // and its well, never as a wash over the panel: a full-surface tint is
    // the "Match feedback" failure this family already renounced — colour
    // as the only signal, at block scale.
    return MxCard.flat(
      child: Column(
        children: <Widget>[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: AppSizing.touchTarget,
            height: AppSizing.touchTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.semanticColors.surfaceMuted,
              shape: BoxShape.circle,
            ),
            // 32 has no `AppIconSize` step: the hero glyph fills the dense
            // tier, which is a dimension, not a gap (A20.1 P2-12).
            child: Icon(
              heroIcon,
              size: AppSizing.controlDense,
              color: heroColor.resolve(context),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: context.texts.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: context.texts.bodyMedium!.inked(context, AppInk.quiet),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

/// The counts card: Added always, each skip cause only when it happened.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.result,
    required this.invalidCount,
    required this.blankCount,
  });

  final CardImportResult result;
  final int invalidCount;
  final int blankCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return MxCard.flat(
      padding: MxCardPadding.compact,
      child: Column(
        children: <Widget>[
          _SummaryRow(
            icon: Icons.check,
            iconColor: AppInk.secondary,
            label: l10n.cardImportAddedRowLabel,
            count: result.imported,
          ),
          if (invalidCount > 0)
            _SummaryRow(
              icon: Icons.error_outline,
              iconColor: AppInk.error,
              label: l10n.cardImportInvalidSkippedRowLabel,
              count: invalidCount,
            ),
          if (result.duplicatesSkipped > 0)
            _SummaryRow(
              icon: Icons.copy_outlined,
              iconColor: AppInk.tertiary,
              label: l10n.cardImportDuplicatesSkippedRowLabel,
              count: result.duplicatesSkipped,
            ),
          if (blankCount > 0)
            _SummaryRow(
              icon: Icons.remove,
              iconColor: AppInk.quiet,
              label: l10n.cardImportBlankIgnoredRowLabel,
              count: blankCount,
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final AppInk iconColor;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    // A bare number, not copy — nothing for the ARB to translate. It wears
    // the row's own colour (concept states 6-7): the count is the row's
    // verdict, and the trailing edge is where the eye compares them.
    final countLabel = '$count';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          // The shared well, for the same reason Confirm's rows carry it:
          // one anchored left edge down the column, one grammar across the
          // screens that count things.
          MxMetricWell(icon: icon, tint: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(label, style: context.texts.bodyMedium)),
          Text(
            countLabel,
            style: context.texts.titleSmall!
                .inked(context, iconColor)
                .copyWith(
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                ),
          ),
        ],
      ),
    );
  }
}
