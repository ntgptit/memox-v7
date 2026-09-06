import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_pressable.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../domain/failures/card_validation_failure.dart';
import 'card_editor_field_widget.dart';

/// The three optional fields, in the editor's label grammar (BR-95, W5).
///
/// **One widget for both modes, which it was not.** It was written as edit's
/// half of a pair, beside a create-only `CardDetailsSectionWidget` that drew
/// the same three values as floating-label inputs behind a leading `+`. The
/// pair was right while create had not been reviewed — a boolean that swaps an
/// entire layout is how one screen's decision reaches a screen nobody looked
/// at. The app-wide screen-consistency pass then looked at it (SC-C6-02) and
/// measured what the split cost: five card values in two field grammars on one
/// screen, the same front at two sizes. So the create copy is gone and this
/// takes both callers.
///
/// What create still varies is content, not grammar — a placeholder for each
/// field of a form that opens empty, and the keyboard's `done` on the last one,
/// because create's form ends here and edit's scrolls on into tags and Trash.
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
    this.examplePlaceholder,
    this.hintPlaceholder,
    this.pronunciationPlaceholder,
    this.pronunciationTextInputAction,
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

  /// Already-localized placeholders, or null for all three.
  ///
  /// Create opens on an empty form and says what each optional field is for;
  /// edit opens on a card that has already answered the question, so it passes
  /// none rather than covering the values it loaded.
  final String? examplePlaceholder;
  final String? hintPlaceholder;
  final String? pronunciationPlaceholder;

  /// The keyboard's action key on the last field. Create's form ends here so it
  /// asks for `done`; edit scrolls on into the tags and the Trash card and
  /// leaves the default (M100.36 9K).
  final TextInputAction? pronunciationTextInputAction;

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
          hintText: examplePlaceholder,
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
          hintText: hintPlaceholder,
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
          hintText: pronunciationPlaceholder,
          maxLength: kCardDetailMaxLength,
          isRequired: false,
          isEnabled: !isBusy,
          errorText: _errorText(context, pronunciationProblem),
          textInputAction: pronunciationTextInputAction,
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
      // The whole row is the target, not the glyph inside it — MxPressable
      // floors it at 48 and keeps the wrap room textScaler 2.0 needs.
      child: MxPressable(
        onTap: onToggle,
        shape: MxPressableShape.sm,
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
    );
  }
}
