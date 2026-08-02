import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/submit_outcome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_action_button.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_text_field.dart';
import '../../domain/failures/card_validation_failure.dart';
import '../controllers/card_create_controller.dart';
import '../states/card_submit_state.dart';

/// The card editor — create mode (UC-04 W4).
///
/// **This slice is create-only, and deliberately narrow.** Edit mode, the
/// optional-detail fields, tags and delete are later slices; the screen is built
/// so they add fields and a title branch rather than reshape what is here. The
/// two required sides, the two save paths and the inline validation are the
/// spine the wireframe (W4) draws.
///
/// It navigates nothing itself: the controller reports a [SubmitOutcome] and this
/// widget reacts — pop on `savedAndClose`, clear the form on `savedAndContinue`
/// — because a controller holding a `BuildContext` is the crash
/// `command_query_separation_test.dart` exists to forbid.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final TextEditingController _front = TextEditingController();
  final TextEditingController _back = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  CardCreate get _controller =>
      ref.read(cardCreateProvider(widget.deckId).notifier);

  void _save(SubmitDisposition disposition) => _controller.submit(
    rawFront: _front.text,
    rawBack: _back.text,
    disposition: disposition,
  );

  String? _frontError(CardValidationProblem? problem) => switch (problem) {
    CardValidationProblem.frontEmpty => context.l10n.cardFrontEmptyError,
    CardValidationProblem.frontTooLong => context.l10n.cardFrontTooLongError,
    _ => null,
  };

  String? _backError(CardValidationProblem? problem) => switch (problem) {
    CardValidationProblem.backEmpty => context.l10n.cardBackEmptyError,
    CardValidationProblem.backTooLong => context.l10n.cardBackTooLongError,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cardCreateProvider(widget.deckId));

    ref.listen<CardSubmitState>(cardCreateProvider(widget.deckId), (
      previous,
      next,
    ) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();
        return;
      }
      // Save-and-add-another: empty the form, return focus to the front, and
      // clear the outcome so the next save is a fresh attempt (UC-04 A4).
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        _front.clear();
        _back.clear();
        _frontFocus.requestFocus();
        _controller.reset();
      }
    });

    final busy = state.isSubmitting;

    return MxContentShell(
      title: context.l10n.cardEditorCreateTitle,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
        tooltip: context.l10n.cardEditorClose,
      ),
      isScrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxTextField(
            controller: _front,
            focusNode: _frontFocus,
            label: context.l10n.cardFrontLabel,
            hintText: context.l10n.cardFrontHint,
            isEnabled: !busy,
            shouldAutofocus: true,
            maxLength: kCardFrontMaxLength,
            maxLines: 2,
            minLines: 1,
            errorText: _frontError(state.frontProblem),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.lg),
          MxTextField(
            controller: _back,
            label: context.l10n.cardBackLabel,
            hintText: context.l10n.cardBackHint,
            isEnabled: !busy,
            maxLength: kCardBackMaxLength,
            maxLines: 4,
            minLines: 2,
            errorText: _backError(state.backProblem),
          ),
          if (state.failure != null) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.cardEditorSaveFailed,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          MxActionButton(
            label: context.l10n.cardEditorSave,
            onPressed: busy ? null : () => _save(SubmitDisposition.close),
            isLoading: busy,
          ),
          const SizedBox(height: AppSpacing.md),
          MxActionButton(
            label: context.l10n.cardEditorSaveAndAdd,
            variant: MxActionButtonVariant.secondary,
            onPressed: busy ? null : () => _save(SubmitDisposition.addAnother),
          ),
        ],
      ),
    );
  }
}
