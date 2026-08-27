import 'package:flutter/material.dart';

import '../../../../../core/theme/app_ink.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../domain/failures/card_validation_failure.dart';
import 'card_editor_field_widget.dart';

/// The three optional fields, in the editor's label grammar (BR-95, W5).
///
/// **A second widget rather than a flag on `CardDetailsSectionWidget`.** Create
/// mode keeps that one, unchanged, because this task redesigns *edit* and a
/// boolean that swaps an entire layout is how one screen's decision reaches a
/// screen nobody reviewed — which is exactly the regression that got through
/// the last time the two modes shared a field builder.
///
/// What differs is not small: create draws three floating-label inputs, edit
/// draws a section heading and three labelled rows with their own icons and
/// live counters.
class CardEditorDetailsWidget extends StatelessWidget {
  const CardEditorDetailsWidget({
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
    if (!isExpanded) return _buildDisclosure(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          context.l10n.cardEditorDetailsHeading,
          style: context.texts.labelMedium!.inked(context, AppInk.quiet),
        ),
        const SizedBox(height: AppSpacing.md),
        CardEditorFieldWidget(
          label: context.l10n.cardEditorExampleFieldLabel,
          icon: Icons.chat_bubble_outline,
          controller: exampleController,
          maxLength: kCardDetailMaxLength,
          isRequired: false,
          isEnabled: !isBusy,
          maxLines: 2,
          minLines: 1,
          errorText: _errorText(context, exampleProblem),
        ),
        const SizedBox(height: AppSpacing.lg),
        CardEditorFieldWidget(
          label: context.l10n.cardEditorHintFieldLabel,
          icon: Icons.lightbulb_outline,
          controller: hintController,
          maxLength: kCardDetailMaxLength,
          isRequired: false,
          isEnabled: !isBusy,
          maxLines: 2,
          minLines: 1,
          errorText: _errorText(context, hintProblem),
        ),
        const SizedBox(height: AppSpacing.lg),
        CardEditorFieldWidget(
          label: context.l10n.cardEditorPronunciationFieldLabel,
          // Decorative, and deliberately not a speaker *button*: D9 defers TTS
          // with its plugin, its permission and its own error flow. A glyph
          // that looks like play and does nothing is worse than no glyph.
          icon: Icons.volume_up_outlined,
          controller: pronunciationController,
          maxLength: kCardDetailMaxLength,
          isRequired: false,
          isEnabled: !isBusy,
          errorText: _errorText(context, pronunciationProblem),
        ),
      ],
    );
  }

  /// The shared "at the character limit" copy: BR-95 gives all three fields one
  /// rule and one number, so they get one sentence.
  String? _errorText(BuildContext context, CardValidationProblem? problem) =>
      problem == null ? null : context.l10n.cardDetailTooLongError;

  /// **A disclosure, and the semantics have to say so.** Without `expanded` a
  /// screen reader announces a button whose label changes for no stated
  /// reason. `toggled` would be the wrong word: this is not a setting.
  Widget _buildDisclosure(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      expanded: isExpanded,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppSpacing.sm),
        child: ConstrainedBox(
          // The whole row is the target, not the glyph inside it. `minHeight`
          // rather than a fixed height: at `textScaler` 2.0 the VI label wraps
          // to two lines and a fixed row would clip it.
          constraints: const BoxConstraints(
            minHeight: AppSpacing.minimumTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.cardEditorDetailsToggle,
                    style: context.texts.labelLarge!.inked(
                      context,
                      AppInk.accent,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // **Chevron-down, not a leading `+`, and not `chevron_right`.**
                // `+` said "add a thing", which is what the *fields* do, not
                // what the toggle does; `chevron_right` is the platform's word
                // for "another screen", and this opens in place.
                const MxIcon(Icons.expand_more, ink: AppInk.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
