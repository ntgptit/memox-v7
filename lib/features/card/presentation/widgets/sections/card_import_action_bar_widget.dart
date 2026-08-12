import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../domain/models/card_import_preview_model.dart';
import '../../../domain/repositories/card_import_repository.dart';
import '../../controllers/card_import_commit_controller.dart';
import '../../controllers/card_import_draft_controller.dart';
import '../../controllers/card_import_query_controller.dart';
import '../../states/card_import_state.dart';

/// Free functions for the same reason every widget's in this feature are:
/// a `ref.read` written inline in `build()` is indistinguishable from the
/// unsubscribed read the guard forbids. Public because the bar's
/// Back/Continue and the screen's system-back are the same move.
void goToCardImportStep(WidgetRef ref, String deckId, CardImportStep step) =>
    ref.read(cardImportStepChoiceProvider(deckId).notifier).go(step);

/// The Preview press (UC-10 step 3): the pasted text reaches its provider
/// here and only here — never per keystroke (wireframe I4) — then the wizard
/// advances, which is what mounts the parse.
void _startPreview(WidgetRef ref, String deckId, String pastedText) {
  ref.read(cardImportPastedTextProvider(deckId).notifier).update(pastedText);
  goToCardImportStep(ref, deckId, CardImportStep.preview);
}

/// The commit (UC-10 step 7): the plan is the preview the user is looking at
/// plus the policy toggle — assembled here, validated nowhere above the
/// transaction.
Future<void> _submitImport(
  WidgetRef ref,
  String deckId,
  CardImportPreview preview, {
  required bool shouldIncludeDuplicates,
}) => ref
    .read(commitCardImportProvider(deckId).notifier)
    .submit(
      CardImportPlan(
        records: preview.records,
        shouldIncludeDuplicates: shouldIncludeDuplicates,
      ),
    );

/// `Import another file` (UC-10 step 8): every draft value back to its
/// default, the commit back to idle, the target deck kept — the providers
/// are all keyed by [deckId], so this list is the reset story in one place.
void _resetImportDraft(WidgetRef ref, String deckId) {
  ref
    ..invalidate(cardImportSourceChoiceProvider(deckId))
    ..invalidate(cardImportFilePickChoiceProvider(deckId))
    ..invalidate(cardImportPastedTextProvider(deckId))
    ..invalidate(cardImportSheetChoiceProvider(deckId))
    ..invalidate(cardImportHeaderChoiceProvider(deckId))
    ..invalidate(cardImportDuplicateChoiceProvider(deckId))
    ..read(commitCardImportProvider(deckId).notifier).reset();
  goToCardImportStep(ref, deckId, CardImportStep.source);
}

bool _hasChosenSource(WidgetRef ref, String deckId, String pastedText) {
  final kind = ref.read(cardImportSourceChoiceProvider(deckId));

  return switch (kind) {
    CardImportSourceKind.upload =>
      ref.read(cardImportFilePickChoiceProvider(deckId)).file != null,
    CardImportSourceKind.paste => pastedText.trim().isNotEmpty,
  };
}

/// The sticky action bar (wireframe I3): one primary action per step, above
/// the keyboard, never over the content — the body scrolls with its own
/// bottom padding.
class CardImportActionBarWidget extends ConsumerWidget {
  const CardImportActionBarWidget({
    required this.deckId,
    required this.step,
    required this.submit,
    required this.pasteController,
    required this.onLeave,
    super.key,
  });

  final String deckId;
  final CardImportStep step;
  final CardImportSubmitState submit;
  final TextEditingController pasteController;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Row(children: _actions(context, ref)),
    );
  }

  List<Widget> _actions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    switch (step) {
      case CardImportStep.source:
        final hasSource = _hasChosenSource(ref, deckId, pasteController.text);

        return <Widget>[
          Expanded(
            child: MxActionButton(
              label: l10n.cardImportPreviewAction,
              onPressed: hasSource
                  ? () => _startPreview(ref, deckId, pasteController.text)
                  : null,
            ),
          ),
        ];

      case CardImportStep.preview:
        final preview = ref.watch(cardImportPreviewProvider(deckId)).value;
        final mapping = ref.watch(cardImportMappingDraftProvider(deckId));
        final shouldIncludeDuplicates = ref.watch(
          cardImportDuplicateChoiceProvider(deckId),
        );
        final importable =
            preview?.importableCount(
              shouldIncludeDuplicates: shouldIncludeDuplicates,
            ) ??
            0;
        final canContinue =
            preview != null && mapping.isComplete && importable > 0;

        return <Widget>[
          Expanded(
            child: MxActionButton(
              label: l10n.cardImportBackAction,
              variant: MxActionButtonVariant.secondary,
              onPressed: () =>
                  goToCardImportStep(ref, deckId, CardImportStep.source),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MxActionButton(
              label: l10n.cardImportContinueAction,
              onPressed: canContinue
                  ? () =>
                        goToCardImportStep(ref, deckId, CardImportStep.confirm)
                  : null,
            ),
          ),
        ];

      case CardImportStep.confirm:
        if (submit.isDone) {
          return <Widget>[
            Expanded(
              child: MxActionButton(
                label: l10n.cardImportAnotherAction,
                variant: MxActionButtonVariant.secondary,
                onPressed: () => _resetImportDraft(ref, deckId),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: MxActionButton(
                label: l10n.cardImportViewCardsAction,
                onPressed: onLeave,
              ),
            ),
          ];
        }

        final preview = ref.watch(cardImportPreviewProvider(deckId)).value;
        final shouldIncludeDuplicates = ref.watch(
          cardImportDuplicateChoiceProvider(deckId),
        );
        final count =
            preview?.importableCount(
              shouldIncludeDuplicates: shouldIncludeDuplicates,
            ) ??
            0;
        final canImport = preview != null && count > 0 && submit.canSubmit;

        return <Widget>[
          Expanded(
            child: MxActionButton(
              label: l10n.cardImportBackAction,
              variant: MxActionButtonVariant.secondary,
              onPressed: submit.isSubmitting
                  ? null
                  : () =>
                        goToCardImportStep(ref, deckId, CardImportStep.preview),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: MxActionButton(
              label: submit.failure != null
                  ? l10n.cardImportTryAgainAction
                  : l10n.cardImportSubmitAction(count),
              isLoading: submit.isSubmitting,
              onPressed: canImport
                  ? () => _submitImport(
                      ref,
                      deckId,
                      preview,
                      shouldIncludeDuplicates: shouldIncludeDuplicates,
                    )
                  : null,
            ),
          ),
        ];
    }
  }
}
