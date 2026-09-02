import 'package:flutter/material.dart';

import '../../core/theme/foundations/app_sizing.dart';
import 'mx_icon_button.dart';

/// A button drawn inside a field, at its trailing edge.
///
/// **A typed triple rather than a `suffixIcon` widget slot.** A widget slot
/// would let a caller put anything in a field — a second text style, a coloured
/// glyph, a whole `Row` — and [MxTextField]'s entire reason for existing is
/// that it refuses those. What a field's trailing action actually varies in is
/// three things, so the type carries exactly three.
///
/// It exists because a tag field that only submits on the keyboard's `done` key
/// has an action nobody can see: on a form full of visible buttons, the way to
/// commit a tag was a key on a keyboard that is not on screen until the field
/// is focused.
@immutable
class MxTextFieldAction {
  const MxTextFieldAction({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;

  /// Already-localized. Required for the same reason [MxIconButton] requires
  /// one: an icon inside a field is otherwise announced as a blank button.
  final String semanticLabel;

  /// `null` disables the action while leaving it visible — a tag field with
  /// nothing typed in it still has to show *where* the add button is.
  final VoidCallback? onPressed;
}

/// Where a field's name is painted.
///
/// **Two placements, one accessible name.** Material floats the label onto the
/// border, which is right for a form of short fields and wrong for one where
/// the name carries more than the name — the card editor puts `Required` and a
/// live `3 / 60` counter on the same row, and none of that fits in a floating
/// label.
///
/// [external] only stops this widget *painting* the label. The caller still
/// passes it, and is responsible for putting it on screen and for merging it
/// into the field's semantics node — `MergeSemantics` around the label row and
/// the field is what makes a screen reader announce them as one control. The
/// label is not optional in either placement, because a field with no name is
/// unlabelled to a screen reader whichever way it is drawn.
enum MxTextFieldLabelPlacement {
  /// Material's floating label. Every existing caller.
  floating,

  /// Drawn by the caller, above the field.
  external,
}

/// The app's text input.
///
/// Takes no `Color`, no `TextStyle` and no `InputDecoration`: every visual
/// decision comes from `InputDecorationTheme`, which is where focus, error and
/// disabled are already defined once for the whole app (M3.5). A caller able to
/// pass decoration would be able to invent a second input style, and the first
/// screen to do it would look correct in isolation and wrong beside the others.
///
/// **It knows nothing about the rules it enforces.** [maxLength] is a number the
/// caller supplies and [errorText] is a string the caller has already localized
/// and already decided to show. BR-01's 200 characters and BR-08's 60 and 240
/// live with the feature that owns them — a shared widget carrying a business
/// limit is a business rule nobody can find, and it is wrong the moment a second
/// screen has a different limit. BR-08 became two numbers at M4.10at, which is
/// that last sentence happening.
///
/// It also does not trim. Trimming here would silently change what the caller
/// validated, so the value it reports and the value it was given stay the same
/// string.
class MxTextField extends StatelessWidget {
  const MxTextField({
    required this.controller,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.isEnabled = true,
    this.isReadOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.shouldAutofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.trailingAction,
    this.labelPlacement = MxTextFieldLabelPlacement.floating,
    super.key,
  });

  final TextEditingController controller;

  /// Already-localized, and required.
  ///
  /// Not optional, because a floating label is the only persistent name the
  /// field has: a hint-only field is unlabelled the moment the user types, both
  /// on screen and to a screen reader.
  final String label;

  /// Already-localized.
  final String? hintText;
  final String? helperText;

  /// Already-localized. Non-null puts the field in its error state.
  ///
  /// The state is carried by real error text rather than a boolean, so the
  /// error is never expressed by colour alone — a red outline with no message
  /// tells a colour-blind user that something is different and not what.
  final String? errorText;

  final bool isEnabled;

  /// Focusable and selectable, but not editable. Distinct from `isEnabled: false`,
  /// which greys the field out and removes it from the focus order.
  final bool isReadOnly;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;

  /// `null` lets the field grow without limit — what a front/back editor wants.
  final int? maxLines;

  /// The caller's limit, enforced by the counter and the input formatter.
  final int? maxLength;

  final FocusNode? focusNode;
  final bool shouldAutofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// How the typed value sits in the field.
  ///
  /// **Two axes, and only one of them is closed.** This widget refuses a
  /// `decoration` on purpose — a caller that could pass one would invent a
  /// second input *style*, and then there are two. The text itself is a
  /// different question: `fill` asks a learner to type one word as the answer to
  /// a card, and the handout draws that centred and large (§6) for the same
  /// reason the card above it is centred and large. Left-aligned 16 in a field
  /// under a 30pt prompt reads as a form field on a study screen.
  final TextAlign textAlign;

  /// The typed value's own style. Null keeps the theme's.
  final TextStyle? textStyle;

  /// A button at the field's trailing edge. Null for a field that commits some
  /// other way, or does not commit at all.
  final MxTextFieldAction? trailingAction;

  /// Whether this widget paints [label] itself. Default keeps Material's
  /// floating label, which is every caller that existed before the card editor.
  final MxTextFieldLabelPlacement labelPlacement;

  /// How many lines [helperText] and [errorText] may occupy before they
  /// ellipsize.
  ///
  /// **An app-wide change, not a per-caller option, and that is deliberate.**
  /// Material's default is one line, and it was found by rendering: the card
  /// editor's BR-10 sentence painted `Editing the text doesn't change this
  /// card'…` — cut mid-word, mid-apostrophe, saying nothing. A message that
  /// does not fit is worse than no message, because it takes the space and
  /// withholds the meaning.
  ///
  /// **A parameter was the obvious shape and it is the wrong one.** It would
  /// leave every existing field on the truncating default and hand the next
  /// author the same defect to rediscover. There is no field in this app whose
  /// error is better read cut in half, so there is nothing for a caller to
  /// decide. It applies to the error as well, so the two states cannot resize
  /// the field differently.
  static const int _maxMessageLines = 3;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textAlign: textAlign,
      style: textStyle,
      autofocus: shouldAutofocus,
      enabled: isEnabled,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      buildCounter: _buildCounter,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: switch (labelPlacement) {
          MxTextFieldLabelPlacement.floating => label,
          // Not painted, and not lost: the caller draws it and merges it.
          MxTextFieldLabelPlacement.external => null,
        },
        hintText: hintText,
        helperText: helperText,
        helperMaxLines: _maxMessageLines,
        errorText: errorText,
        errorMaxLines: _maxMessageLines,
        suffixIcon: _buildSuffix(),
        // **Stated, because the default is 48 wide and 48 tall only by
        // accident.** `InputDecorator` gives a suffix the field's own height
        // when it has one to give, and a single-line field is shorter than the
        // touch floor at small text scales — so the button would be tappable
        // over a box narrower than the guideline asks for while looking exactly
        // right.
        suffixIconConstraints: trailingAction == null
            ? null
            : const BoxConstraints(
                minWidth: AppSizing.touchTarget,
                minHeight: AppSizing.touchTarget,
              ),
      ),
    );
  }

  Widget? _buildSuffix() {
    final action = trailingAction;
    if (action == null) return null;

    return MxIconButton(
      icon: action.icon,
      semanticLabel: action.semanticLabel,
      onPressed: action.onPressed,
    );
  }

  /// The counter speaks only when the limit is near.
  ///
  /// A `0/240` under an empty field is noise about a rule the user is nowhere
  /// close to breaking; from [_counterVisibleFraction] of the limit it becomes
  /// the warning it exists to be. Hidden, it still keeps its line
  /// (`maintainSize`), so its arrival never reflows the field below —
  /// state-change layout stability is the same rule the error slot follows.
  Widget? _buildCounter(
    BuildContext context, {
    required int currentLength,
    required int? maxLength,
    required bool isFocused,
  }) {
    if (maxLength == null) return null;
    // **An external label owns the counter too.** The card editor draws
    // `55 / 60` in its label row; this one appeared under the field the moment
    // the value passed 80% of the limit, so one field showed the same number
    // twice, in two formats, in two places. It stays *reserved* rather than
    // removed — the slot is what keeps the field's height stable when an error
    // arrives, which is the reason the hidden state below exists at all.
    final isOwnedByCaller =
        labelPlacement == MxTextFieldLabelPlacement.external;
    final isNearLimit = currentLength >= maxLength * _counterVisibleFraction;

    return Visibility(
      visible: isNearLimit && !isOwnedByCaller,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: Text(
        '$currentLength/$maxLength',
        // The same pairing the framework's default counter paints, said
        // explicitly because a custom `buildCounter` starts from nothing.
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// From what fraction of [MxTextField.maxLength] the counter becomes visible.
const double _counterVisibleFraction = 0.8;
