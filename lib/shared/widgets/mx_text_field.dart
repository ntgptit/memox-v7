import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/foundations/app_sizing.dart';
import '../../core/theme/extensions/theme_context_extension.dart';
import 'mx_icon_button.dart';
import '../../core/theme/extensions/app_ink.dart';

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

/// How large the typed value is set.
///
/// **A closed pair, replacing an open `TextStyle?`** (M100.36 9I). The one
/// caller that needed a different rung — the card editor's front, which is
/// the prompt a learner is shown and not an equal of the back — passed
/// `context.texts.titleLarge`, a theme rung; but the type admitted a
/// hand-built style with any colour and any size just as readily, and no
/// guard scanned it. Two values, both with a production caller.
enum MxTextFieldEmphasis {
  /// The theme's input style — `body-lg`. Every field but one.
  body,

  /// `title-lg`. The value only: label, counter, error and border stay on the
  /// theme, so a prominent field still lines up with its neighbours on every
  /// edge.
  prominent,
}

/// What the field accepts.
///
/// **Closed, because the alternative was `List<TextInputFormatter>`** (M100.36
/// 9H). A `TextInputType.number` field accepted `abc-12.5` verbatim — the soft
/// keyboard hides the letters, but paste, a hardware keyboard and a
/// third-party IME do not — and the two numeric fields then fell through to a
/// parse failure the user had to read as an error (#433 F7).
enum MxTextFieldContent {
  /// Anything.
  text,

  /// Digits only, `0–9`. The domain's card limit is an integer (BR-xx), so
  /// this is `FilteringTextInputFormatter.digitsOnly` and not a decimal
  /// mode; a field that needs `.` asks for a member that does not exist yet.
  digits,
}

/// Whether a line is held under the box for a helper, an error or the counter.
///
/// **Reserved by default, and that is the product behaviour** (M100.36 9F): a
/// form must not jump when validation appears. `InputDecorator` gives the
/// subtext row 20dp only once it has something to show, so a field without a
/// `maxLength` grew by 20dp the moment its `errorText` arrived and pushed the
/// controls under it — the two card-limit fields, whose radio group and pill
/// row sat directly below (#433 F5). The counter already held the line
/// through `maintainSize`; this holds it for every field the same way.
///
/// [none] is for a field that can never produce supporting text — no helper,
/// no error, no limit — so it does not carry 20dp of air for nothing. The
/// import paste box is the one caller.
enum MxTextFieldSupportingLine {
  /// The subtext row is laid out from the first frame, empty or not.
  reserved,

  /// No row. The field's height is its box.
  none,
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
/// The three things a caller *may* vary — how large the value is, what it
/// accepts, whether a subtext line is held — are closed enums with a
/// production caller behind every member (M100.36).
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
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.shouldAutofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.emphasis = MxTextFieldEmphasis.body,
    this.content = MxTextFieldContent.text,
    this.supportingLine = MxTextFieldSupportingLine.reserved,
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

  /// **No `isReadOnly`** (M100.36 4G). It had zero callers and no visual cue —
  /// identical ink to an editable field — so a user who reached it could not
  /// tell why typing did nothing. Removed rather than given a look nobody has
  /// asked for. The study answer's lock is `_FillInput`'s own, where the
  /// reason is written.
  final bool isEnabled;

  /// Null lets [content] decide: `digits` asks for the numeric keyboard.
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

  /// See [MxTextFieldEmphasis]. (`textAlign` left with it at M100.36: its one
  /// reason — the centred study answer — lives in `_FillInput`, and nothing
  /// else passed it.)
  final MxTextFieldEmphasis emphasis;

  /// See [MxTextFieldContent].
  final MxTextFieldContent content;

  /// See [MxTextFieldSupportingLine].
  final MxTextFieldSupportingLine supportingLine;

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

  /// The empty helper that keeps the subtext row laid out — see
  /// [MxTextFieldSupportingLine]. `null` when the caller opted out.
  String? get _reservedHelper =>
      supportingLine == MxTextFieldSupportingLine.reserved ? ' ' : null;

  @override
  Widget build(BuildContext context) {
    final bool isDigits = content == MxTextFieldContent.digits;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      style: switch (emphasis) {
        MxTextFieldEmphasis.body => null,
        MxTextFieldEmphasis.prominent => context.texts.titleLarge,
      },
      autofocus: shouldAutofocus,
      enabled: isEnabled,
      keyboardType: keyboardType ?? (isDigits ? TextInputType.number : null),
      inputFormatters: isDigits
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
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
        // A single space holds the subtext row when the caller has nothing
        // to say yet — `InputDecorator` lays the row out for any non-null
        // helper, and this is the narrowest way to ask it to. The error
        // replaces the helper in the same row, so its arrival moves nothing.
        helperText: helperText ?? _reservedHelper,
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
        // **What a screen reader says instead of "55 slash 60"** (#433 F9).
        // `TextField` sets `semanticCounterText` to the framework's localized
        // "N characters remaining" for its own counter and returns early when
        // `buildCounter` is supplied, so a custom counter has to say it
        // itself. `MaterialLocalizations` rather than the app's ARB: the
        // sentence is Flutter's and it is already in both shipped locales,
        // and a shared widget does not reach for ARB.
        semanticsLabel: MaterialLocalizations.of(
          context,
        ).remainingTextFieldCharacterCount(maxLength - currentLength),
        // The same pairing the framework's default counter paints, said
        // explicitly because a custom `buildCounter` starts from nothing.
        style: Theme.of(
          context,
        ).textTheme.bodySmall!.inked(context, AppInk.quiet),
      ),
    );
  }
}

/// From what fraction of [MxTextField.maxLength] the counter becomes visible.
const double _counterVisibleFraction = 0.8;
