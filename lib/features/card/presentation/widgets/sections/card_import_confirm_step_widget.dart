import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../../domain/models/card_import_result_model.dart';
import '../../controllers/card_import_commit_controller.dart';
import '../support/card_import_labels_widget.dart';

/// Step 3 — confirm, submit, and the result (UC-10 steps 6–8).
///
/// Three faces of one step, switched by the commit's own state: the confirm
/// summary while nothing ran, an error line with the draft intact after a
/// failed commit (E5), and the result once the one transaction landed. No
/// per-row progress is ever faked — the batch is atomic, so there is nothing
/// honest to count up (wireframe W4).
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
    final result = submit.result;
    if (result != null) {
      return _ResultView(preview: preview, result: result, deckName: deckName);
    }

    final l10n = context.l10n;
    final willWrite = preview.importableCount(
      shouldIncludeDuplicates: shouldIncludeDuplicates,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(l10n.cardImportConfirmHeading, style: context.texts.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        MxCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.cardImportConfirmTargetLabel(deckName),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportConfirmWriteLabel(willWrite),
                style: context.texts.bodyMedium,
              ),
              Text(
                shouldIncludeDuplicates
                    ? l10n.cardImportConfirmDuplicateIncludeLabel(
                        preview.duplicateCount,
                      )
                    : l10n.cardImportConfirmDuplicateSkipLabel(
                        preview.duplicateCount,
                      ),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportConfirmInvalidLabel(preview.invalidCount),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportSummaryBlankLabel(preview.blankCount),
                style: context.texts.bodyMedium,
              ),
            ],
          ),
        ),
        if (submit.failure != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Icon(
                Icons.error_outline,
                size: AppSpacing.lg,
                color: context.colors.error,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  context.cardImportFailureLabel(submit.failure!),
                  style: context.texts.bodyMedium?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (submit.isSubmitting) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Semantics(
              label: context.l10n.cardImportSubmittingLabel,
              child: const CircularProgressIndicator(),
            ),
          ),
        ],
      ],
    );
  }
}

/// The success view (UC-10 step 8): what happened, and the two ways out. The
/// invalid count comes from the preview — the commit never saw those rows —
/// while the duplicate count comes from the transaction's own recheck.
class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.preview,
    required this.result,
    required this.deckName,
  });

  final CardImportPreview preview;
  final CardImportResult result;
  final String deckName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Icon(
          Icons.check_circle_outline,
          size: AppSpacing.xxl,
          // The selected-mark token, same reasoning as the source cards.
          color: context.colors.secondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.cardImportResultHeading,
          style: context.texts.titleMedium,
          textAlign: TextAlign.center,
        ),
        Text(
          l10n.cardImportConfirmTargetLabel(deckName),
          style: context.texts.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        MxCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                l10n.cardImportResultImportedLabel(result.imported),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportResultDuplicatesLabel(result.duplicatesSkipped),
                style: context.texts.bodyMedium,
              ),
              Text(
                l10n.cardImportResultInvalidLabel(preview.invalidCount),
                style: context.texts.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
