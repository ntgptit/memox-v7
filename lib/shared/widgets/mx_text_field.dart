import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: shouldAutofocus,
      enabled: isEnabled,
      readOnly: isReadOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
      ),
    );
  }
}
