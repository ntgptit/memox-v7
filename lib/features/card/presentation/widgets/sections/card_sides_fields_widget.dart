import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/card_validation_failure.dart';
import '../../states/card_submit_state.dart';

/// The two sides every card has, and the banner that says a save did not land
/// (UC-04 W4/W6, BR-07, BR-08).
///
/// Shared by both editor modes, which is why it is a widget rather than a
/// method: create and edit differ in what surrounds these two fields and in
/// nothing about the fields themselves, and the one time they drifted apart it
/// was because each had its own copy of the same builder.
///
/// The parent owns the controllers — it needs their text on save — so this
/// stays stateless.
class CardSidesFieldsWidget extends StatelessWidget {
  const CardSidesFieldsWidget({
    required this.frontController,
    required this.backController,
    required this.state,
    required this.isBusy,
    this.frontFocusNode,
    this.shouldAutofocus = false,
    this.backHelperText,
    super.key,
  });

  final TextEditingController frontController;
  final TextEditingController backController;
  final CardSubmitState state;
  final bool isBusy;
  final FocusNode? frontFocusNode;
  final bool shouldAutofocus;

  /// Already-localized. Edit mode's only addition, and a helper rather than a
  /// line of its own: BR-10's reassurance is *about* these fields, and as a
  /// floating `Text` below them it belonged to neither — it read as a heading
  /// for whatever came next.
  final String? backHelperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        MxTextField(
          controller: frontController,
          focusNode: frontFocusNode,
          label: context.l10n.cardFrontLabel,
          hintText: context.l10n.cardFrontHint,
          isEnabled: !isBusy,
          shouldAutofocus: shouldAutofocus,
          maxLength: kCardFrontMaxLength,
          maxLines: 2,
          minLines: 1,
          errorText: _frontError(context, state.frontProblem),
          textInputAction: TextInputAction.next,
          // **The front is the card, and the form did not say so.** Both sides
          // were drawn at the same body size, so they read as a pair of equals
          // — while the front is the prompt a learner is shown and the back is
          // the answer. The value only: label, counter, error and border stay
          // on the theme, so the two fields still line up on every edge.
          textStyle: context.texts.titleLarge,
        ),
        const SizedBox(height: AppSpacing.lg),
        MxTextField(
          controller: backController,
          label: context.l10n.cardBackLabel,
          hintText: context.l10n.cardBackHint,
          helperText: backHelperText,
          isEnabled: !isBusy,
          maxLength: kCardBackMaxLength,
          maxLines: 4,
          minLines: 2,
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
