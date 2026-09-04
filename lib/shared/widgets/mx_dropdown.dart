import 'package:flutter/material.dart';

/// One choice in an [MxDropdown].
class MxDropdownOption<T> {
  const MxDropdownOption({required this.value, required this.label});

  final T value;

  /// Already-localized words for the choice.
  final String label;
}

/// A compact inline select.
///
/// **Exists so no feature builds a `DropdownButton` again.** The two sites
/// that did (the import mapping rows and the sheet selector) had converged on
/// the same three lines of ceremony — `DropdownButtonHideUnderline` around
/// `DropdownButton(isExpanded: true)` — and this widget makes that the only
/// spelling: no underline, because the control sits inside form rows that
/// already draw their own structure; expanded, because a dropdown that sizes
/// to its longest option breaks the row grid it sits in. Labels ellipsize on
/// one line rather than growing the row.
///
/// The nullable-choice case ("Ignore this column") is the type's job, not a
/// special slot: instantiate with a nullable `T` and give the option a `null`
/// value.
///
/// This is the *inline* select. A field-anchored picker with a text box is
/// Material's `DropdownMenu`, which is themed and needs no wrapper.
///
/// **Disabled and error are decided, not missing** (A20.1 P2-21).
/// *Disabled* is `onChanged: null` — Material's own grammar for a
/// `DropdownButton`, which then paints the theme's disabled ink and drops
/// the tap; there is no second flag to fall out of step with it. *Error* has
/// no slot on purpose: the control sits inside form rows (the import
/// mapping, the sheet selector) and the **row** owns its validation band, so
/// a red edge here would be a second place the same fault is stated.
/// `mx_picker_render_test.dart` pins both.
class MxDropdown<T> extends StatelessWidget {
  const MxDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  });

  final T? value;

  final List<MxDropdownOption<T>> options;

  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        onChanged: onChanged,
        items: <DropdownMenuItem<T>>[
          for (final option in options)
            DropdownMenuItem<T>(
              value: option.value,
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
