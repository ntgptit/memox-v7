import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../states/card_submit_state.dart';
import 'card_details_section_widget.dart';

/// The editor's create mode: two sides and the optional details (UC-04 W4, A4).
///
/// **Its own file, and that is the point.** Edit mode has been redesigned twice;
/// create is explicitly out of that scope. While both modes shared one field
/// builder, every decision taken for edit landed here too — which is how a front
/// field on a screen nobody had reviewed silently changed size the last time
/// these two shared a builder. `CardEditorFormWidget` is edit's; this is
/// create's, and neither reads the other.
///
/// **What it does not own is the save.** The two dispositions live in
/// `CardCreateActionBarWidget`, pinned in `MxContentShell.footer` — the pair
/// used to be the last child of this column, inside the scroll, on a screen
/// that autofocuses its first field and so meets the user with the keyboard
/// already up (SC-C1-02). The screen owns the controllers, the submit state and
/// the outcome, exactly as it does for edit; this widget is handed them.
///
/// Every other behaviour below is the one create already had: floating labels,
/// the counter that appears near the limit, no tags, no delete, no discard
/// guard.
class CardCreateFormWidget extends StatefulWidget {
  const CardCreateFormWidget({
    required this.state,
    required this.isBusy,
    required this.front,
    required this.back,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.frontFocus,
    super.key,
  });

  final CardSubmitState state;
  final bool isBusy;
  final TextEditingController front;
  final TextEditingController back;
  final TextEditingController example;
  final TextEditingController hint;
  final TextEditingController pronunciation;
  final FocusNode frontFocus;

  @override
  State<CardCreateFormWidget> createState() => _CardCreateFormWidgetState();
}

class _CardCreateFormWidgetState extends State<CardCreateFormWidget> {
  /// The optional-detail fields start collapsed (W4); nothing here can open
  /// them but a tap, because a new card has no detail to reveal.
  bool _detailsExpanded = false;

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
    final state = widget.state;
    final busy = widget.isBusy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxTextField(
          controller: widget.front,
          focusNode: widget.frontFocus,
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
          controller: widget.back,
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
            style: context.texts.bodyMedium!.inked(context, AppInk.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        CardDetailsSectionWidget(
          isExpanded: _detailsExpanded,
          onToggle: () => setState(() => _detailsExpanded = !_detailsExpanded),
          exampleController: widget.example,
          hintController: widget.hint,
          pronunciationController: widget.pronunciation,
          isBusy: busy,
          exampleProblem: state.exampleProblem,
          hintProblem: state.hintProblem,
          pronunciationProblem: state.pronunciationProblem,
        ),
      ],
    );
  }
}
