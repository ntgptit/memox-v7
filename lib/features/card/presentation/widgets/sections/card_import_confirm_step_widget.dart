import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
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
      ],
    );
  }
}
