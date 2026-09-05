import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_button_pair.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
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
/// transaction. Try again re-submits this same retained plan: no re-pick,
/// no re-parse, and the double-submit guard in the controller ensures no
/// second transaction can overlap the first (state 8).
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

/// `Back to preview` after a failed commit (state 8): the commit state clears
/// so Confirm stops wearing the failure, and every draft value — source,
/// sheet, header, mapping, policy, preview — survives untouched, because
/// none of them lives in the commit controller.
void _backToPreview(WidgetRef ref, String deckId) {
  ref.read(commitCardImportProvider(deckId).notifier).reset();
  goToCardImportStep(ref, deckId, CardImportStep.preview);
}

/// `Import another file` (UC-10 step 8): every draft value back to its
/// default, the commit back to idle, the target deck kept — the providers
/// are all keyed by [deckId], so this list is the reset story in one place.
/// Public: the screen composes it with clearing its own paste controller —
/// the providers reset here, the `TextEditingController` is the screen's (G).
void resetCardImportDraft(WidgetRef ref, String deckId) {
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

/// The sticky action bar (wireframe I3): one primary action per presentation
/// phase, in the shell's footer slot. The CTAs follow [CardImportPhase], not
/// just the step: Parsing disables the primary under its own label, Submitting
/// locks both actions without a second spinner, and each outcome face gets its
/// own pair (states 2, 5, 6–8).
///
/// **No `SafeArea` and no `viewInsets` arithmetic here** — that was this bar's
/// job when the screen was a raw `Scaffold`, and it is the shell's now: the
/// footer is the last row of the body's column, so the body shrinking for the
/// keyboard is what keeps the bar above it, and the shell's `SafeArea` already
/// covers the gesture strip. A second inset would be paid twice, which is the
/// exact bug the card editor's migration wrote down first.
class CardImportActionBarWidget extends ConsumerWidget {
  const CardImportActionBarWidget({
    required this.deckId,
    required this.phase,
    required this.submit,
    required this.pasteController,
    required this.onReset,
    required this.onViewCards,
    super.key,
  });

  final String deckId;
  final CardImportPhase phase;
  final CardImportSubmitState submit;
  final TextEditingController pasteController;

  /// `Import another file`: the full draft reset, paste box included (G).
  final VoidCallback onReset;

  /// `View cards`, reachable only from the success-shaped outcomes (E).
  final VoidCallback onViewCards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The concept's reassurance line rides under the actions on the wizard
    // phases (states 1-4): what the primary will and will not do. Outcomes
    // and the submit panel carry their own copy, so no line competes there.
    final String? hint = switch (phase) {
      CardImportPhase.source => context.l10n.cardImportBarSourceHint,
      CardImportPhase.parsing => context.l10n.cardImportBarParsingHint,
      CardImportPhase.preview ||
      CardImportPhase.confirm => context.l10n.cardImportBarImportHint,
      _ => null,
    };

    return Padding(
      // One rhythm for both footer bands. The app has exactly two
      // `MxContentShell.footer` callers drawing the same anatomy — a pair of
      // actions over a centred quiet line — and this one used to sit 12dp
      // shorter than `CardEditorActionBarWidget`, which is the older of the
      // two and the bar the footer slot was built for.
      padding: EdgeInsets.symmetric(
        horizontal: mxScreenGutter(context),
        vertical: AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // **`MxButtonPair` where there are two actions, a full-width button
          // where there is one.** The bar used to keep its own
          // `IntrinsicHeight` + `Row`, which solved the equal-height half of
          // the pair problem and silently skipped the rest — the one-row-or-
          // stack boundary the shared widget measures against the longest
          // word. `Import 128 cards` beside `Back` at 320dp/2.0× is exactly
          // the case that rule exists for, and this bar was answering it with
          // an ellipsis.
          _actions(context, ref),
          if (hint != null)
            Padding(
              // `sm`, not `xs`: `xs` is the icon-to-label step, too tight to
              // read as the gap between a control and the line explaining it.
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                hint,
                style: context.texts.bodySmall!.inked(context, AppInk.quiet),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    switch (phase) {
      case CardImportPhase.source:
        final hasSource = _hasChosenSource(ref, deckId, pasteController.text);

        return MxActionButton(
          label: l10n.cardImportPreviewAction,
          onPressed: hasSource
              ? () => _startPreview(ref, deckId, pasteController.text)
              : null,
        );

      case CardImportPhase.parsing:
        // The decode is running: the primary says so under its own label and
        // stays put — no layout jump when rows arrive (state 2). Back keeps
        // working; it only changes the step, never the data.
        return MxButtonPair(
          secondary: MxActionButton(
            label: l10n.cardImportBackAction,
            variant: MxActionButtonVariant.secondary,
            onPressed: () =>
                goToCardImportStep(ref, deckId, CardImportStep.source),
          ),
          primary: MxActionButton(
            label: l10n.cardImportParsingAction,
            onPressed: null,
          ),
        );

      case CardImportPhase.preview:
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

        return MxButtonPair(
          secondary: MxActionButton(
            label: l10n.cardImportBackAction,
            variant: MxActionButtonVariant.secondary,
            onPressed: () =>
                goToCardImportStep(ref, deckId, CardImportStep.source),
          ),
          primary: MxActionButton(
            label: l10n.cardImportContinueAction,
            onPressed: canContinue
                ? () => goToCardImportStep(ref, deckId, CardImportStep.confirm)
                : null,
          ),
        );

      case CardImportPhase.confirm:
      case CardImportPhase.submitting:
        final preview = ref.watch(cardImportPreviewProvider(deckId)).value;
        final shouldIncludeDuplicates = ref.watch(
          cardImportDuplicateChoiceProvider(deckId),
        );
        final count =
            preview?.importableCount(
              shouldIncludeDuplicates: shouldIncludeDuplicates,
            ) ??
            0;
        final isSubmitting = phase == CardImportPhase.submitting;
        final canImport = preview != null && count > 0 && submit.canSubmit;

        return MxButtonPair(
          secondary: MxActionButton(
            label: l10n.cardImportBackAction,
            variant: MxActionButtonVariant.secondary,
            onPressed: isSubmitting
                ? null
                : () => goToCardImportStep(ref, deckId, CardImportStep.preview),
          ),
          // While submitting the label changes and the button locks — no
          // spinner here: the submit panel already carries the single
          // loading indicator this state is allowed (state 5).
          primary: MxActionButton(
            label: isSubmitting
                ? l10n.cardImportSubmittingLabel
                : l10n.cardImportSubmitAction(count),
            onPressed: !isSubmitting && canImport
                ? () => _submitImport(
                    ref,
                    deckId,
                    preview,
                    shouldIncludeDuplicates: shouldIncludeDuplicates,
                  )
                : null,
          ),
        );

      case CardImportPhase.completed:
      case CardImportPhase.completedWithSkips:
      case CardImportPhase.noCardsAdded:
        return MxButtonPair(
          secondary: MxActionButton(
            label: l10n.cardImportAnotherAction,
            variant: MxActionButtonVariant.secondary,
            onPressed: onReset,
          ),
          primary: MxActionButton(
            label: l10n.cardImportViewCardsAction,
            onPressed: onViewCards,
          ),
        );

      case CardImportPhase.commitFailure:
        final preview = ref.watch(cardImportPreviewProvider(deckId)).value;
        final shouldIncludeDuplicates = ref.watch(
          cardImportDuplicateChoiceProvider(deckId),
        );

        return MxButtonPair(
          secondary: MxActionButton(
            label: l10n.cardImportBackToPreviewAction,
            variant: MxActionButtonVariant.secondary,
            onPressed: () => _backToPreview(ref, deckId),
          ),
          primary: MxActionButton(
            label: l10n.cardImportTryAgainAction,
            onPressed: preview != null && submit.canSubmit
                ? () => _submitImport(
                    ref,
                    deckId,
                    preview,
                    shouldIncludeDuplicates: shouldIncludeDuplicates,
                  )
                : null,
          ),
        );
    }
  }
}
