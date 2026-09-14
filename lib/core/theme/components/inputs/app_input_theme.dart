import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_sizing.dart';
import '../../foundations/app_spacing.dart';
import '../../foundations/app_stroke.dart';

/// The text field, as `MxTextField` renders it. (`MxSearchField` is its own
/// composition and reads none of this — see its file.)
///
/// Split out of `app_theme.dart` when that file crossed the 400-line guard —
/// the same seam as the buttons, the chip and the overlays: one component
/// family, every state declared by hand, read by nothing else in the theme.
///
/// **The handoff TextField (M100.92): a filled surface with a ghost edge.**
/// `surfaceContainerLowest` fill, a `1px` `outlineVariant` border (D2), radius
/// 12, a 52 minimum. The fill identifies the field, so the edge no longer has to
/// carry the 3:1 an empty outlined field once owed on its own; the ratios it
/// does reach on each ground are pinned in `control_border_grounds_test.dart`
/// (owner decision 5).
///
/// **Focus changes the border's COLOUR, not its weight — except under error.**
/// The handoff says it outright: focus is "1px solid primary border (NOT
/// 2px)". Under error the hue is already spoken for, so the stroke is the only
/// channel left to say "and it has focus": `focusedErrorBorder` alone takes
/// [AppStroke.focus] (D27, #433 F3, M100.36 4C). `OutlineInputBorder` paints
/// its side inside the box, so the change costs no layout.
///
/// **Disabled dims the whole field, not the edge** — the handoff's 0.38 on the
/// entire control, applied by `MxTextField`. The disabled border is therefore
/// the resting one, and the hint and suffix keep their resting inks: dimming
/// them here as well would dim them twice.
///
/// **Every slot below that names a colour names a `ColorScheme` role**, and
/// `m3_role_binding_guard_test.dart` reads the borders at source level.
InputDecorationTheme buildInputDecorationTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => InputDecorationTheme(
  filled: true,
  fillColor: scheme.surfaceContainerLowest,
  constraints: const BoxConstraints(minHeight: AppSizing.input),
  // 16 named, 20 drawn: `OutlineInputBorder.gapPadding` (4.0) is added to both
  // horizontal insets by `input_decorator.dart` under M3, so a field's text
  // sits 4dp further in than a `Text` padded to `AppSpacing.lg` in the same
  // column. Recorded (#433 F10) so the next person measuring 20 against a 16
  // token does not go looking for a bug.
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  ),
  border: _inputBorder(scheme.outlineVariant),
  enabledBorder: _inputBorder(scheme.outlineVariant),
  focusedBorder: _inputBorder(scheme.primary),
  errorBorder: _inputBorder(scheme.error),
  focusedErrorBorder: _inputBorderAt(scheme.error, AppStroke.focus),
  disabledBorder: _inputBorder(scheme.outlineVariant),
  // **The value's own rung, `body-lg`** (M100.36 4F): the placeholder used to
  // be a rung under the 16 that replaces it, so the text grew the moment the
  // first character landed (#433 F6). Hierarchy between hint and value is
  // colour, not size.
  hintStyle: WidgetStateTextStyle.resolveWith(
    (states) => texts.bodyLarge!.copyWith(color: scheme.onSurfaceVariant),
  ),
  // **The suffix follows the field's error state** (#433 F4): the themed
  // `IconButtonTheme` answers before the M3 default's `error` branch, so the
  // slot is stated here. Under error it is the danger ink (M100.87): the glyph
  // is read like the error text beside it, and the border keeps `error`.
  suffixIconColor: WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.error)) return semantic.dangerInk;

    return scheme.onSurfaceVariant;
  }),
);

/// Same geometry in every state — only the colour speaks.
OutlineInputBorder _inputBorder(Color color) =>
    _inputBorderAt(color, AppStroke.hairline);

/// The one state whose stroke differs: focused error, at [AppStroke.focus].
OutlineInputBorder _inputBorderAt(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
