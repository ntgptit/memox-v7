import 'package:flutter/material.dart';

import '../../foundations/app_decorations.dart';
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
  // **Filled since M100.101, because v3 names a fill for both states** —
  // `surface-muted` at rest and `surface-raised` on focus. It reverses the
  // decision below, which is kept because it is still the argument on the
  // other side: a fill makes the field a block that competes with the cards
  // around it, where a stroke alone lets the page show through and the field
  // reads as an opening rather than an object.
  //
  // **What the numbers say about the pair, and it is not comfortable.** With
  // the border moving to `border-ghost` at the same time, neither cue
  // separates the field from the page in light: the resting fill `#F1F4FB` is
  // **1.05:1** against the page (ΔL\* 1.76) and the ghost border is
  // **1.19:1**. A light field on the page therefore has no boundary that
  // clears any threshold — it is legible because its *text* is (16.00:1), not
  // because its edge is. Dark fares better: the resting fill is ΔL\* 9.98 off
  // the page and reads as a real step.
  //
  // The owner chose v3 with those figures in hand.
  // `control_border_grounds_test.dart` pins the border and this file's own
  // measurements are the record for the fill; restoring a boundary means a
  // fill further from the page, a stroke above ghost, or both, and belongs to
  // whichever task takes that on.
  filled: true,
  fillColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
    // Focus is the only state that moves the fill: v3 lifts the field to
    // `surface-raised` while it holds the caret and leaves it on
    // `surface-muted` otherwise. Disabled deliberately keeps the resting fill
    // — the disabled cue is the hairline and the ink, both already faded, and
    // a third channel saying the same thing is how one state ends up spelled
    // three ways.
    if (states.contains(WidgetState.focused)) {
      return scheme.surfaceContainerLowest;
    }

    return scheme.surfaceContainerLow;
  }),
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
  // information WCAG 1.4.11 asks 3:1 of; the hairline reads 1.53:1 on the page
  // and 1.30:1 on a dialog's surface — nowhere near it. `outline` measures
  // 3.44:1 on the page and 3.62:1 on a card, and 2.92:1 on a dialog's
  // `surfaceContainerHigh`, the one ground where the v3 hex lands under the
  // floor; that figure is pinned rather than fixed, because the palette ships
  // verbatim (M100.84). A card's edge stays subtle because a card is
  // identified by its content. `control_border_grounds_test.dart` holds this
  // on every ground a field is drawn on.
  border: _inputBorder(AppDecorations.hairlineEdge(scheme).color),
  enabledBorder: _inputBorder(AppDecorations.hairlineEdge(scheme).color),
  focusedBorder: _inputBorder(scheme.primary),
  errorBorder: _inputBorder(scheme.error),
  focusedErrorBorder: _inputBorderAt(scheme.error, AppStroke.focus),
  // Solid, per MX-VIS-002 rule R7. Blended here rather than read from
  // `disabledSurface`: this is the *hairline* faded, that is the *ink*. The
  // blend base is the raised paper (`surfaceContainerLowest`, v3's
  // `surface-raised`, M100.99); a disabled field on the page or in a dialog is
  // blended against a slightly wrong ground: the blend is `#BEC2D5` in light,
  // which reads 1.68:1 on the page against 1.43:1 in a dialog. Contrast-exempt either way, so it stays one value (#433 §5.4).
  disabledBorder: _inputBorder(
    Color.alphaBlend(
      scheme.outline.withValues(alpha: 0.5),
      scheme.surfaceContainerLowest,
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
  // **The error message is text, so it takes the danger ink, not `error`**
  // (GC-3, 2026-09-17). `_InputDecoratorDefaultsM3.errorStyle` is
  // `textTheme.bodySmall` in `colorScheme.error`; the rung is kept from
  // [texts] and only the role moves — the border keeps `error`, where 3:1 is
  // what a boundary owes.
  errorStyle: texts.bodySmall!.copyWith(color: semantic.dangerInk),
  // **The suffix follows the field's error state** (#433 F4). `InputDecorator`
  // resolves the suffix colour as `decoration.suffixIconColor ??
  // iconButtonTheme.foregroundColor ?? defaults.suffixIconColor`
  // (`input_decorator.dart:2163-2170`), and this app themes `IconButton` — so
  // the middle link answered first and the M3 default's `error` branch was
  // never reached: the tag field's border went red and its `+` stayed grey.
  // Stating the slot here is the canonical fix; weakening `IconButtonTheme`
  // would have moved every icon button in the app.
  //
  // **Under error it is the danger ink, not `error`** (GC-3, 2026-09-17). The
  // glyph is read like the error text beside it, and v3's `error` is a fill;
  // the border keeps `error`, where 3:1 is what a boundary owes.
  suffixIconColor: WidgetStateColor.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
    if (states.contains(WidgetState.error)) return semantic.dangerInk;

    return scheme.onSurfaceVariant;
  }),
);

/// Same geometry in every state — only the colour speaks.
/// **A hairline since M100.101**, because v3 states this edge at one dp. It
/// was [AppStroke.control]; the focused-error case keeps its heavier stroke
/// below, which is the one place the field still argues with a line.
OutlineInputBorder _inputBorder(Color color) =>
    _inputBorderAt(color, AppStroke.hairline);

/// The one state whose stroke differs: focused error, at [AppStroke.focus].
OutlineInputBorder _inputBorderAt(Color color, double width) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
