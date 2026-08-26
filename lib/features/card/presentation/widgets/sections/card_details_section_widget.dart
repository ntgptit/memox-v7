import 'package:flutter/material.dart';

import '../../../../../core/theme/app_icon_size.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_field.dart';
import '../../../domain/failures/card_validation_failure.dart';

/// The optional detail fields — example, hint, pronunciation — behind a toggle
/// (UC-04 W4/W5, BR-95).
///
/// **Collapsed by default, and that is the wireframe.** The three are optional
/// and most cards have none, so the create form (W4) shows only the affordance;
/// expanding reveals the fields (W5). The parent owns the controllers — it needs
/// their text on save — so this stays stateless and reports the toggle up.
///
/// The single [MxTextField.errorText] each field carries reads the same
/// per-field problem the sides use; the shared "at the character limit" copy
/// serves all three, because BR-95 gives them one rule and one number.
class CardDetailsSectionWidget extends StatelessWidget {
  const CardDetailsSectionWidget({
    required this.isExpanded,
    required this.onToggle,
    required this.exampleController,
    required this.hintController,
    required this.pronunciationController,
    required this.isBusy,
    this.exampleProblem,
    this.hintProblem,
    this.pronunciationProblem,
    super.key,
  });

  final bool isExpanded;
  final VoidCallback onToggle;
  final TextEditingController exampleController;
  final TextEditingController hintController;
  final TextEditingController pronunciationController;
  final bool isBusy;
  final CardValidationProblem? exampleProblem;
  final CardValidationProblem? hintProblem;
  final CardValidationProblem? pronunciationProblem;

  @override
  Widget build(BuildContext context) {
    String? errorText(CardValidationProblem? problem) =>
        problem == null ? null : context.l10n.cardDetailTooLongError;

    // `primaryAccent`, not `colorScheme.primary`: the brand fill measures 3.29:1
    // as text/glyph on the dark surface, below 4.5:1. The accent is the variant
    // that clears it — the same reason the text buttons use it.
    final accent = context.semanticColors.primaryAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // **A disclosure, and the semantics have to say so.** Without
        // `expanded` a screen reader announces a button whose label changes
        // for no stated reason — the user is told `Details` after being told
        // `Add example, hint & pronunciation` and has to infer that something
        // opened. `toggled` would be the wrong word: this is not a setting.
        Semantics(
          container: true,
          button: true,
          expanded: isExpanded,
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppSpacing.sm),
            child: ConstrainedBox(
              // The whole row is the target, not the 20dp glyph inside it.
              // `minHeight` rather than a fixed height: at `textScaler` 2.0 the
              // VI label wraps to two lines and a fixed row would clip it.
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minimumTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        isExpanded
                            ? context.l10n.cardEditorDetailsLabel
                            : context.l10n.cardEditorDetailsToggle,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: accent),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // **Trailing chevron-down, not a leading `+`, and not
                    // `chevron_right`.** `+` said "add a thing", which is what
                    // the *fields* do, not what the toggle does; `chevron_right`
                    // is the platform's word for "another screen", and this
                    // opens in place. The vertical pair is the one convention
                    // that means exactly what happens here.
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: AppIconSize.md,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isExpanded) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          MxTextField(
            controller: exampleController,
            label: context.l10n.cardExampleLabel,
            hintText: context.l10n.cardExampleHint,
            isEnabled: !isBusy,
            maxLength: kCardDetailMaxLength,
            maxLines: 2,
            minLines: 1,
            errorText: errorText(exampleProblem),
          ),
          const SizedBox(height: AppSpacing.lg),
          MxTextField(
            controller: hintController,
            label: context.l10n.cardHintLabel,
            hintText: context.l10n.cardHintHint,
            isEnabled: !isBusy,
            maxLength: kCardDetailMaxLength,
            maxLines: 2,
            minLines: 1,
            errorText: errorText(hintProblem),
          ),
          const SizedBox(height: AppSpacing.lg),
          MxTextField(
            controller: pronunciationController,
            label: context.l10n.cardPronunciationLabel,
            hintText: context.l10n.cardPronunciationHint,
            isEnabled: !isBusy,
            maxLength: kCardDetailMaxLength,
            errorText: errorText(pronunciationProblem),
          ),
        ],
      ],
    );
  }
}
