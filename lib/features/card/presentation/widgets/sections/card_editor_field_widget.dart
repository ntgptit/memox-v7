import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_text_field.dart';

/// One editor field: a label row above, the input below.
///
/// **A feature composite, not a new shared widget.** What varies here is
/// entirely the card editor's business — an upper-case section name, a
/// `Required`/`optional` word, and a counter that is always on rather than
/// appearing near the limit. Pushing any of that into [MxTextField] would put
/// one screen's grammar in every screen's input.
///
/// **The label row is the reason the floating label is off.** Material floats
/// the name onto the border, which has room for a name and nothing else; this
/// row carries three things and a live count. [MxTextFieldLabelPlacement.external]
/// stops the field painting a second copy — it does not stop the field *having*
/// the name, which is what the [MergeSemantics] below is for: the label, the
/// requirement, the counter and the input are announced as one control rather
/// than as four things that happen to be near each other.
class CardEditorFieldWidget extends StatelessWidget {
  const CardEditorFieldWidget({
    required this.label,
    required this.controller,
    required this.maxLength,
    required this.isRequired,
    required this.isEnabled,
    this.icon,
    this.errorText,
    this.helperText,
    this.maxLines = 1,
    this.minLines,
    this.emphasis = MxTextFieldEmphasis.body,
    this.focusNode,
    this.textInputAction,
    super.key,
  });

  /// Already-localized, and the section grammar of the concept: `FRONT`,
  /// `BACK · MEANING`, `EXAMPLE SENTENCE`.
  final String label;

  final TextEditingController controller;

  /// From the domain constants, never a literal — BR-08 gives the two sides 60
  /// and 240, and BR-95 gives the details 240.
  final int maxLength;

  /// Draws `Required` or `optional` beside the label. **A word, not a colour**:
  /// a red asterisk tells a colour-blind user that something is different and
  /// not what.
  final bool isRequired;

  final bool isEnabled;

  /// Decorative only — the concept puts a small glyph beside the optional
  /// detail names. It is excluded from semantics because it says nothing a
  /// screen reader has not already been told by [label], and an unexcluded
  /// glyph inside a merged control reads as an action.
  final IconData? icon;

  final String? errorText;
  final String? helperText;
  final int maxLines;
  final int? minLines;

  /// See [MxTextFieldEmphasis].
  final MxTextFieldEmphasis emphasis;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildLabelRow(context),
          // Tighter than the gap between fields: a label belongs to the box
          // under it, and equal gaps make it float between the two.
          const SizedBox(height: AppSpacing.sm),
          MxTextField(
            controller: controller,
            focusNode: focusNode,
            label: label,
            labelPlacement: MxTextFieldLabelPlacement.external,
            isEnabled: isEnabled,
            maxLength: maxLength,
            maxLines: maxLines,
            minLines: minLines,
            errorText: errorText,
            helperText: helperText,
            emphasis: emphasis,
            textInputAction: textInputAction,
          ),
        ],
      ),
    );
  }

  Widget _buildLabelRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          // MxIcon excludes itself from semantics when unlabeled, which is
          // what the ExcludeSemantics wrapper used to say by hand.
          MxIcon(icon!, size: MxIconSize.sm),
          const SizedBox(width: AppSpacing.xs),
        ],
        // **One flexible child, not two.** `Flexible(label)` beside a `Spacer`
        // — which is an `Expanded` — split the free space evenly, so the label
        // was cut at half the row while the counter floated up to 91dp short of
        // the field's right edge. Measured at 390dp: `EXAMPLE SENTENCE` needed
        // 132 and was given 120, with ~180 free beside it; the five counters
        // landed at 282.9 / 353.5 / 374.0 / 284.4 / 374.0 against a surface
        // edge of 374. Giving the label-and-marker group the whole remainder
        // pins the counter to the edge and lets the label take what it needs.
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              // **The name gets three quarters, the marker one.** With the
              // marker laid out at its full width first, `CÂU VÍ DỤ` came out
              // **18.2dp** at 320 and text scale 2.0 — one glyph and an
              // ellipsis — while `không bắt buộc` kept all 171. That inverts
              // what the row is for: the name identifies the field, the marker
              // qualifies it.
              Flexible(
                flex: 3,
                child: Text(
                  label,
                  style: context.texts.labelMedium!.inked(
                    context,
                    AppInk.quiet,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  isRequired
                      ? context.l10n.cardEditorFieldRequired
                      : context.l10n.cardEditorFieldOptional,
                  style: context.texts.labelSmall!.inked(
                    context,
                    isRequired ? AppInk.accent : AppInk.quiet,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        // **Always on, unlike the app-wide counter.** `MxTextField` hides its
        // own until 80% of the limit, because `0 / 240` under an empty field is
        // noise about a rule nobody is near. Here the row exists anyway and the
        // concept reserves the space, so hiding the number would leave a gap
        // that fills itself later and shifts the label.
        //
        // **Listening to the controller, not reading it once.** The parent
        // rebuilds when the form flips dirty — once — so a counter read during
        // that build would freeze on the character count of the first keystroke.
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            context.l10n.cardEditorFieldCounter(
              value.text.characters.length,
              maxLength,
            ),
            style: context.texts.labelSmall!.inked(context, AppInk.quiet),
          ),
        ),
      ],
    );
  }
}
