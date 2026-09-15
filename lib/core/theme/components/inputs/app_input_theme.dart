import 'package:flutter/material.dart';

import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_spacing.dart';
import '../../foundations/app_stroke.dart';

/// The text field, as `MxTextField` renders it. (`MxSearchField` is its own
/// composition and reads none of this — see its file.)
///
/// Split out of `app_theme.dart` when that file crossed the 400-line guard —
/// the same seam as the buttons, the chip and the overlays: one component
/// family, every state declared by hand, read by nothing else in the theme.
///
/// **Focus changes the border's COLOUR, not its weight — except under error.**
/// Material's default goes 1 → 2 on focus in every state, which makes the
/// field jump and nudges anything laid out beside it; keeping the stroke at
/// [AppStroke.control] for plain focus and moving the hue to `scheme.primary` is
/// the difference between a field answering and a field shouting. But M3 uses
/// that width for a second job as well: under error the *hue* is already
/// spoken for (`error`, unfocused or focused), so the stroke is the only
/// channel left to say "and it has focus". This theme had set
/// `focusedErrorBorder` byte-identical to `errorBorder`, so an errored field
/// gave no border feedback at all when tapped (#433 F3). It now strengthens to
/// [AppStroke.focus] there and only there — the canonical
/// `_InputDecoratorDefaultsM3.outlineBorder` answer, on the canonical role
/// (M100.36 4C). `OutlineInputBorder` paints its side inside the box, so the
/// change costs no layout.
///
/// **Every slot below that names a colour names a `ColorScheme` role**, and
/// `m3_role_binding_guard_test.dart` reads the four borders at source level.
/// `disabledBorder` is the one exception — a solid blend, not a role — and
/// `m3_role_contract_test.dart` pins it as exactly that.
InputDecorationTheme buildInputDecorationTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => InputDecorationTheme(
  // Outlined, not filled. A fill makes the field a block that competes with
  // the cards around it; the reference defines the field with a stroke alone
  // and lets the page show through, so the field reads as an opening rather
  // than an object, and sits correctly on page or card with no override.
  filled: false,
  // 16 named, 20 drawn: `OutlineInputBorder.gapPadding` (4.0) is added to both
  // horizontal insets by `input_decorator.dart:2639-2645` under M3, so a
  // field's text sits 4dp further in than a `Text` padded to `AppSpacing.lg`
  // in the same column. Recorded (#433 F10) so the next person measuring 20
  // against a 16 token does not go looking for a bug; compensating with 12
  // here would break the floating label's gap.
  contentPadding: const EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  ),
  // **`outline`, not `outlineVariant`.** An empty field with a placeholder and
  // nothing else is identified by its edge alone, which is exactly the
  // information WCAG 1.4.11 asks 3:1 of; the hairline measured 1.38:1 in
  // light. A card's edge stays subtle because a card is identified by its
  // content. `control_border_grounds_test.dart` holds this on every ground a
  // field is drawn on.
  border: _inputBorder(scheme.outline),
  enabledBorder: _inputBorder(scheme.outline),
  focusedBorder: _inputBorder(scheme.primary),
  errorBorder: _inputBorder(scheme.error),
  focusedErrorBorder: _inputBorderAt(scheme.error, AppStroke.focus),
  // Solid, per MX-VIS-002 rule R7. Blended here rather than read from
  // `disabledSurface`: this is the *hairline* faded, that is the *ink*. The
  // blend base is the paper (`surfaceContainerLow`); a disabled field on the
  // page or in a dialog is blended against a slightly wrong ground, measured
  // 1.98 → 1.81 and contrast-exempt, so it stays one value (#433 §5.4).
  disabledBorder: _inputBorder(
    Color.alphaBlend(
      scheme.outline.withValues(alpha: 0.5),
      scheme.surfaceContainerLow,
    ),
  ),
  // **The value's own rung, `body-lg`, and resolved per state** (M100.36 4F).
  // The placeholder used to be `body-md` — a rung under the 16 that replaces
  // it, so the text in the field grew and shifted its line box the moment the
  // first character landed (#433 F6). M3's own hint is `bodyLarge` with an
  // `onSurfaceVariant` colour that fades to 38% when disabled; a plain
  // `TextStyle` here had no state branch, so a disabled empty field kept its
  // placeholder at full strength while everything around it faded. Hierarchy
  // between hint and value is colour, not size.
  hintStyle: WidgetStateTextStyle.resolveWith(
    (states) => texts.bodyLarge!.copyWith(
      color: states.contains(WidgetState.disabled)
          ? semantic.onDisabled
          : scheme.onSurfaceVariant,
    ),
  ),
  // **The suffix follows the field's error state** (#433 F4). `InputDecorator`
  // resolves the suffix colour as `decoration.suffixIconColor ??
  // iconButtonTheme.foregroundColor ?? defaults.suffixIconColor`
  // (`input_decorator.dart:2163-2170`), and this app themes `IconButton` — so
  // the middle link answered first and the M3 default's `error` branch was
  // never reached: the tag field's border went red and its `+` stayed grey.
  // Stating the slot here is the canonical fix; weakening `IconButtonTheme`
  // would have moved every icon button in the app.
  suffixIconColor: WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
    if (states.contains(WidgetState.error)) return scheme.error;

    return scheme.onSurfaceVariant;
  }),
);

/// Same geometry in every state — only the colour speaks.
OutlineInputBorder _inputBorder(Color color) =>
    _inputBorderAt(color, AppStroke.control);

/// The one state whose stroke differs: focused error, at [AppStroke.focus].
OutlineInputBorder _inputBorderAt(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
