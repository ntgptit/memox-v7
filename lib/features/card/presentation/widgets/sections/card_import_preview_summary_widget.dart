import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_switch_row.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../items/card_import_row_preview_widget.dart';
import '../support/card_import_labels_widget.dart';

/// The duplicate-policy command, a free function for the same reason the
/// step's are: a `ref.read` written inline in `build()` is indistinguishable
/// from the unsubscribed read the guard forbids.
void _updateDuplicateChoice(
  WidgetRef ref,
  String deckId, {
  required bool value,
}) => ref
    .read(cardImportDuplicateChoiceProvider(deckId).notifier)
    .update(shouldIncludeDuplicates: value);

/// How many preview rows render before the "…and N more" footer takes over
/// (wireframe W3's 10–20 band). Display truncation only: the counts and the
/// commit always cover every row.
const int kCardImportPreviewRowLimit = 15;

/// The counts, the duplicate policy, and the first rows (UC-10 step 5).
class CardImportPreviewSummaryWidget extends ConsumerWidget {
  const CardImportPreviewSummaryWidget({
    required this.deckId,
    required this.preview,
    required this.shouldIncludeDuplicates,
    super.key,
  });

  final String deckId;
  final CardImportPreview preview;
  final bool shouldIncludeDuplicates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final shown = preview.rows.take(kCardImportPreviewRowLimit).toList();
    final hiddenCount = preview.rows.length - shown.length;

    final importable = preview.importableCount(
      shouldIncludeDuplicates: shouldIncludeDuplicates,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // The section heading with the readiness verdict beside it (state 3):
        // what the classification concluded, before the rows prove it. The
        // same outside-the-panel label grammar Card Detail's bands use; the
        // baseline row wraps intentionally when a narrow screen cannot hold
        // both — the count drops under the label rather than ellipsizing.
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: AppSpacing.sm,
          children: <Widget>[
            Text(
              l10n.cardImportPreviewHeading.toUpperCase(),
              style: context.textStyles.sectionLabel.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            Text(
              l10n.cardImportPreviewReadyOfTotal(importable, preview.totalRows),
              style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // **The verdict, the policy and the rows are one panel** (concept
        // states 3-4): the chips say what the classification found, the
        // toggle is the one decision that changes the plan, and the rows are
        // the evidence — three faces of one group, so they share one surface
        // instead of floating between sections.
        MxCard.flat(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // One chip per status that actually occurred (state 4): a
              // glyph, the word and the count together, never colour alone
              // (W7). Ready always renders — "Ready · 0" is the honest
              // headline of an all-broken file.
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: <Widget>[
                  _StatusChip(
                    status: CardImportRowStatus.ready,
                    count: preview.readyCount,
                  ),
                  if (preview.invalidCount > 0)
                    _StatusChip(
                      status: CardImportRowStatus.invalid,
                      count: preview.invalidCount,
                    ),
                  if (preview.duplicateCount > 0)
                    _StatusChip(
                      status: CardImportRowStatus.duplicateExisting,
                      count: preview.duplicateCount,
                    ),
                  if (preview.blankCount > 0)
                    _StatusChip(
                      status: CardImportRowStatus.blank,
                      count: preview.blankCount,
                    ),
                ],
              ),
              MxSwitchRow(
                label: l10n.cardImportIncludeDuplicatesLabel,
                isOn: shouldIncludeDuplicates,
                onChanged: (value) =>
                    _updateDuplicateChoice(ref, deckId, value: value),
              ),
              Divider(
                height: AppSpacing.xs,
                color: context.colors.outlineVariant,
              ),
              for (var index = 0; index < shown.length; index++) ...<Widget>[
                if (index > 0)
                  Divider(
                    height: AppSpacing.xs,
                    color: context.colors.outlineVariant,
                  ),
                CardImportRowPreviewWidget(row: shown[index]),
              ],
              if (hiddenCount > 0)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                  ),
                  child: Text(
                    l10n.cardImportMoreRowsLabel(hiddenCount),
                    style: context.texts.bodySmall!.inked(
                      context,
                      AppInk.quiet,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One status chip (state 4): the status word, its count, and the container
/// pair its rows use — plus the glyph, so colour never carries the meaning
/// alone. The two duplicate kinds share one chip word; the row detail is
/// where "already in deck" and "duplicate in file" tell themselves apart.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.count});

  final CardImportRowStatus status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    // **Status is a semantic, not an accent** (M100.21). `ready` used to draw
    // `secondaryContainer` and `duplicate` `tertiaryContainer` — the two roles
    // M3 reserves for balancing an interface, standing in for "good" and
    // "noted" because the semantics had no containers. They do now.
    //
    // `invalid` keeps `errorContainer`: a row that failed to parse *is* an
    // error, which is the one place on this screen where that role is meant.
    // `blank` stays neutral — an empty row is not a status, it is an absence.
    final (
      IconData icon,
      Color background,
      AppInk foreground,
    ) = switch (status) {
      CardImportRowStatus.ready => (
        Icons.check,
        semantic.successContainer,
        AppInk.onSuccessContainer,
      ),
      CardImportRowStatus.invalid => (
        Icons.error_outline,
        colors.errorContainer,
        AppInk.onErrorContainer,
      ),
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile => (
        Icons.copy_outlined,
        semantic.infoContainer,
        AppInk.onInfoContainer,
      ),
      CardImportRowStatus.blank => (
        Icons.remove,
        colors.surfaceContainerHigh,
        AppInk.quiet,
      ),
    };
    final label = switch (status) {
      CardImportRowStatus.duplicateExisting ||
      CardImportRowStatus.duplicateInFile =>
        context.l10n.cardImportStatusDuplicateChipLabel,
      _ => context.cardImportRowStatusLabel(status),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            MxIcon(icon, ink: foreground, size: MxIconSize.sm),
            const SizedBox(width: AppSpacing.xs),
            Text(
              context.l10n.cardImportStatusCountChip(label, count),
              style: context.texts.labelMedium!.inked(context, foreground),
            ),
          ],
        ),
      ),
    );
  }
}
