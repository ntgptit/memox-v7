import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/state/submit_outcome.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_action_button.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../controllers/card_create_controller.dart';
import '../../states/card_submit_state.dart';
import 'card_details_section_widget.dart';

/// The editor's create mode: two sides, the optional details, and two ways to
/// save (UC-04 W4, A4).
///
/// **Moved out of `CardEditorScreen` unchanged, and that is the point.** Edit
/// mode is being redesigned; create is explicitly out of that scope. While both
/// modes shared the screen's five `TextEditingController`s and its field
/// builder, every decision taken for edit landed here too — which is how a
/// front field on a screen nobody had reviewed silently changed size the last
/// time these two shared a builder.
///
/// One instance is only ever one mode, so nothing was shared at runtime; what
/// was shared was the *risk*. Every behaviour below is the one create already
/// had: floating labels, the counter that appears near the limit, no tags, no
/// delete, no pinned footer, no discard guard.
class CardCreateFormWidget extends ConsumerStatefulWidget {
  const CardCreateFormWidget({required this.deckId, super.key});

  final String deckId;

  @override
  ConsumerState<CardCreateFormWidget> createState() =>
      _CardCreateFormWidgetState();
}

class _CardCreateFormWidgetState extends ConsumerState<CardCreateFormWidget> {
  final TextEditingController _front = TextEditingController();
  final TextEditingController _back = TextEditingController();
  final TextEditingController _example = TextEditingController();
  final TextEditingController _hint = TextEditingController();
  final TextEditingController _pronunciation = TextEditingController();
  final FocusNode _frontFocus = FocusNode();

  /// The optional-detail fields start collapsed (W4); nothing here can open
  /// them but a tap, because a new card has no detail to reveal.
  bool _detailsExpanded = false;

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _example.dispose();
    _hint.dispose();
    _pronunciation.dispose();
    _frontFocus.dispose();
    super.dispose();
  }

  void _submit({SubmitDisposition disposition = SubmitDisposition.close}) => ref
      .read(cardCreateProvider(widget.deckId).notifier)
      .submit(
        rawFront: _front.text,
        rawBack: _back.text,
        rawExample: _example.text,
        rawHint: _hint.text,
        rawPronunciation: _pronunciation.text,
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
    final provider = cardCreateProvider(widget.deckId);
    final state = ref.watch(provider);

    ref.listen<CardSubmitState>(provider, (previous, next) {
      if (next.shouldClose && !(previous?.shouldClose ?? false)) {
        Navigator.of(context).pop();

        return;
      }
      // Save-and-add-another: empty the form, return focus to the front, and
      // clear the outcome so the next save is a fresh attempt (UC-04 A4).
      if (next.shouldClearDraft && !(previous?.shouldClearDraft ?? false)) {
        _front.clear();
        _back.clear();
        _example.clear();
        _hint.clear();
        _pronunciation.clear();
        _frontFocus.requestFocus();
        ref.read(provider.notifier).reset();
      }
    });

    final busy = state.isSubmitting;

    return Column(
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
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.error,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        CardDetailsSectionWidget(
          isExpanded: _detailsExpanded,
          onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
          exampleController: _example,
          hintController: _hint,
          pronunciationController: _pronunciation,
          isBusy: busy,
          exampleProblem: state.exampleProblem,
          hintProblem: state.hintProblem,
          pronunciationProblem: state.pronunciationProblem,
        ),
        const SizedBox(height: AppSpacing.xl),
        MxActionButton(
          label: context.l10n.cardEditorSave,
          onPressed: busy ? null : _submit,
          isLoading: busy,
        ),
        const SizedBox(height: AppSpacing.md),
        MxActionButton(
          label: context.l10n.cardEditorSaveAndAdd,
          variant: MxActionButtonVariant.secondary,
          onPressed: busy
              ? null
              : () => _submit(disposition: SubmitDisposition.addAnother),
        ),
      ],
    );
  }
}
