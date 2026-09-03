import 'package:flutter/material.dart';

/// Caret, selection and the drag handles in a text field.
///
/// Left to Material these come from `primary` at an opacity it chooses. Naming
/// them matters most for `selectionColor`: the default is light enough that
/// selected text on a tinted card is hard to see it is selected at all.
TextSelectionThemeData buildTextSelectionTheme(ColorScheme scheme) =>
    TextSelectionThemeData(
      cursorColor: scheme.primary,
      selectionColor: scheme.primary.withValues(alpha: 0.24),
      selectionHandleColor: scheme.primary,
    );
