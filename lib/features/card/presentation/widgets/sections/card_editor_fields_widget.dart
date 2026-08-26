import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../states/card_submit_state.dart';

/// The two required sides of a card, plus the banner a failed write leaves
/// behind — shared by the editor's create and edit modes (UC-04 W4, A1).
///
/// **Front is set larger than back, and the pair is the point.** They carried
/// the same style until an owner review asked what the form was showing: front
/// is the word being learned, back is what it means, and during a review the
/// study screen renders the front large and alone. A form that paints the two
/// identically hides which of them the learner will actually be looking at, so
/// the field is set at `titleLarge` — the same rung the app bar's own title
/// uses (owner review, 2026-08-26).
///
/// **Not `headlineSmall`, which was the other candidate.** The field sits in a
/// column of ordinary form labels and counters; the headline rungs are for text
/// that owns its screen, and at `maxLines: 2` a headline-sized front pushed the
/// back field off a 320-wide screen at a large text scale.
///
/// Split out of `card_editor_screen.dart` when the pinned save bar and the
/// unsaved-changes guard took the screen past the 400-line limit. The seam is
/// the one the screen already had: this is the part both modes render
/// identically, and everything the screen kept differs between them.
class CardEditorFieldsWidget extends StatelessWidget {
  const CardEditorFieldsWidget({
    required this.state,
    required this.frontController,
    required this.backController,
    required this.frontFocus,
    required this.isBusy,
    required this.shouldAutofocus,
    this.backHelperText,
    super.key,
  });

  final CardSubmitState state;
  final TextEditingController frontController;
  final TextEditingController backController;
  final FocusNode frontFocus;
  final bool isBusy;

  /// Create autofocuses the front field; edit opens on a card that is already
  /// written, so it does not steal the keyboard.
  final bool shouldAutofocus;

  /// Already-localized, and edit mode's alone: BR-10's reassurance that editing
  /// the text leaves the study progress alone.
  ///
  /// **A helper on the field rather than a paragraph after it.** It used to be
  /// a loose `Text` floating between the back field and the details toggle,
  /// attached to neither — a sentence about the form, rendered as if it were
  /// about whatever it happened to sit beside (owner review, 2026-08-26). The
  /// back field is the last of the two the sentence is about, so it is where
  /// the line belongs.
  final String? backHelperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxTextField(
          controller: frontController,
          focusNode: frontFocus,
          label: context.l10n.cardFrontLabel,
          hintText: context.l10n.cardFrontHint,
          isEnabled: !isBusy,
          shouldAutofocus: shouldAutofocus,
          maxLength: kCardFrontMaxLength,
          maxLines: 2,
          minLines: 1,
          textStyle: context.texts.titleLarge,
          errorText: _frontError(context, state.frontProblem),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: AppSpacing.lg),
        MxTextField(
          controller: backController,
          label: context.l10n.cardBackLabel,
          hintText: context.l10n.cardBackHint,
          isEnabled: !isBusy,
          maxLength: kCardBackMaxLength,
          maxLines: 4,
          minLines: 2,
          helperText: backHelperText,
          errorText: _backError(context, state.backProblem),
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
      ],
    );
  }

  String? _frontError(BuildContext context, CardValidationProblem? problem) =>
      switch (problem) {
        CardValidationProblem.frontEmpty => context.l10n.cardFrontEmptyError,
        CardValidationProblem.frontTooLong =>
          context.l10n.cardFrontTooLongError,
        _ => null,
      };

  String? _backError(BuildContext context, CardValidationProblem? problem) =>
      switch (problem) {
        CardValidationProblem.backEmpty => context.l10n.cardBackEmptyError,
        CardValidationProblem.backTooLong => context.l10n.cardBackTooLongError,
        _ => null,
      };
}
