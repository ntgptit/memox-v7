import 'package:flutter/material.dart';

import '../../foundations/app_sizing.dart';
import '../../states/app_interaction_states.dart';
import '../../foundations/app_radius.dart';
import '../../foundations/app_semantic_colors.dart';
import '../../foundations/app_spacing.dart';
import '../../foundations/app_stroke.dart';
import '../../typography/app_typography.dart';

/// The filled, outlined, text-link and destructive button styles, and the
/// geometry the filled and outlined pair share.
///
/// Split out of `app_theme.dart` when that file crossed the 400-line guard. They
/// are the natural seam: everything here is one component family, it is the
/// longest block in the theme because every button declares every interaction
/// state by hand, and nothing else in the theme reads it.
///
/// **They declare disabled, pressed, hovered and focused explicitly.** Material
/// supplies defaults, but they are derived from the scheme and drift the moment
/// the scheme changes; naming them is what keeps the states stable. The values
/// come from [AppStateOpacity], which transcribes them from the kit's `mx.css`.

/// A disabled control's fill and border, resolved to a solid colour over the
/// ground that state actually has.
///
/// Most disabled controls sit on the page or on a card, and for those the answer
/// is already precomputed: `AppSemanticColors.disabledSurface`. This exists for
/// the one that does not — a *selected* pill that goes disabled sits on
/// `secondaryContainer`, so blending the same 12% over `surface` there would
/// erase the selection rather than dim it. The tint is the constant; the ground
/// is per state.
Color disabledSurfaceTint(ColorScheme scheme, {Color? over}) =>
    Color.alphaBlend(
      scheme.onSurface.withValues(alpha: AppStateOpacity.disabledSurfaceBlend),
      over ?? scheme.surfaceContainerLow,
    );

/// Geometry and label weight shared by every button.
///
/// 48 high before padding: the minimum touch target, enforced here rather than
/// per component so no button in the app can be built below it.
ButtonStyle buildSharedButtonStyle(
  ColorScheme scheme,
  TextTheme texts,
) => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll<Size>(
    Size(AppSizing.buttonMinWidth, AppSizing.touchTarget),
  ),
  padding: const WidgetStatePropertyAll<EdgeInsets>(
    EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
  ),
  shape: WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  ),
  // **The label rung, one weight above the app's emphatic 600** (M100.30).
  //
  // Left null this fell through to `_FilledButtonDefaultsM3.textStyle`, which
  // is `labelLarge` — so a button's label wore the same weight as a section
  // heading and a chip, and a filled action read as a coloured box with
  // ordinary text on it. Tokyo states `fontWeight: 'bold'` on `MuiButton.root`
  // for every variant, and that single declaration is most of why its actions
  // look like actions.
  //
  // Through `withWeight`, never a bare `fontWeight:`: both faces are variable,
  // and a weight that does not move the `wght` axis reports 700 and paints 600
  // — the bug `component_theme_typography_test.dart` exists for.
  textStyle: WidgetStatePropertyAll<TextStyle>(
    AppTypography.withWeight(texts.labelLarge!, buttonLabelWeight),
  ),
  // **The outlined family's state layer — `primary`, M3's own answer for a
  // control with no fill.** The filled family overrides this slot in
  // `buildFilledStyle` with its pair's `on` colour; it used to inherit this
  // one as well, which is how `primary` came to be painted over `error` on
  // every destructive press (#432 P1-1, closed at M100.36). Hover is web and
  // desktop only, and Android is the release target (AD-04) — but the web
  // build is the E2E channel, so it shows up in exactly the place this
  // project takes screenshots.
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);

/// The two fills a filled button is allowed to wear.
///
/// **An enum, because `buildFilledStyle` used to take `fill` and `label` as
/// two `Color`s** (M100.31). That is a builder API a caller can break the
/// semantic mapping through: any pair of colours went in, including a pair
/// that was not a Material role at all, and nothing above the widget could
/// see it. The builder now resolves the pair itself, so the only way to reach
/// a filled button is to name one of the pairs the design system admits.
///
/// Each member is a canonical M3 pair, and the fill, its `on` colour and the
/// state layer travel together — passing one without the others is the
/// mismatch this closes. `m3_role_binding_guard_test.dart` reads each arm
/// below at source level, so a swap to a role that happens to share a hex
/// still fails.
///
/// **`tonal` left at M100.36.** It had no production caller since #384 took
/// Card Detail's Edit back to an icon, and the study grading hierarchy (4B)
/// was settled with `secondary` for the lower-emphasis grades. A variant kept
/// for a use it might someday have is exactly what a closed API is for
/// refusing.
enum MxFilledPair {
  /// `primary` / `onPrimary` — `_FilledButtonDefaultsM3`'s own pair, and the
  /// screen's one call to action.
  brand,

  /// `error` / `onError` — the destructive action. `error` is `danger` in this
  /// palette, so this is not a second red.
  destructive;

  /// The fill, read off the scheme rather than handed in.
  Color fillOf(ColorScheme scheme) => switch (this) {
    MxFilledPair.brand => scheme.primary,
    MxFilledPair.destructive => scheme.error,
  };

  /// The label that travels with [fillOf].
  Color labelOf(ColorScheme scheme) => switch (this) {
    MxFilledPair.brand => scheme.onPrimary,
    MxFilledPair.destructive => scheme.onError,
  };

  /// The state layer painted over [fillOf] on hover, focus and press.
  ///
  /// **The same role as [labelOf], stated separately on purpose.** M3 paints a
  /// filled button's state layer in the fill's own `on` colour
  /// (`_FilledButtonDefaultsM3.overlayColor` → `onPrimary`), which in this
  /// palette is white or near-black on every pair — so the layer moves
  /// lightness and leaves hue alone. Naming it here rather than reusing
  /// [labelOf] is what lets the source guard pin *this* slot: a future pair
  /// whose label and layer part would have to say so in two places, and
  /// `mx_action_button_composite_state_test.dart` asserts the two agree.
  Color stateLayerOf(ColorScheme scheme) => switch (this) {
    MxFilledPair.brand => scheme.onPrimary,
    MxFilledPair.destructive => scheme.onError,
  };
}

/// The primary action: `MxActionButton`'s `primary` variant.
///
/// Reads `scheme.primary` / `scheme.onPrimary` itself — it used to take the
/// pair as `actionFill` / `actionLabel` parameters that every caller filled
/// from `AppColors`, which gave one meaning two sources that merely happened
/// to agree. The high-contrast themes were where they were set to part:
/// `highContrastScheme` transforms the scheme while the relayed constants
/// would have stayed the normal-contrast values, so the day that transform
/// touches `primary`, buttons built from parameters would have quietly kept
/// the old brand (theme-composition review, 2026-08).
FilledButtonThemeData buildFilledButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => FilledButtonThemeData(
  style: buildFilledStyle(scheme, semantic, texts, pair: MxFilledPair.brand),
);

/// A filled button's colours, for one of the admitted pairs.
///
/// Public so `MxActionButton`'s destructive variant can be the same button with
/// a different pair rather than a second implementation. It used to reach for
/// `FilledButton.styleFrom(backgroundColor: error)`, and that is a flat
/// `WidgetStatePropertyAll` which **shadows the theme's property entirely** —
/// so a destructive button did not darken on press and, worse, stayed fully red
/// when disabled while its label went to 38%. A button that looks armed and is
/// inert is the failure this whole file exists to prevent.
///
/// **One state mechanism, and it is Material's** (M100.36). The resting fill
/// is its role in every enabled state; hover, focus and press arrive as a
/// state layer in the pair's `on` colour at the SDK's own alphas
/// (`AppStateOpacity.stateLayer*`). Until M100.36 this builder lerped the
/// fill toward `onSurface` *and* inherited `controlOverlay` — `primary` at
/// 6/10/12% — from the shared style, so two mechanisms painted at once: a
/// no-op on the brand fill that cancelled part of the blend, and an indigo
/// wash on the error fill that rotated its hue (#432 §5). The blend and its
/// two tokens are gone; the overlay is now the pair's own.
///
/// [pair] rather than two `Color`s since M100.31 — see [MxFilledPair].
ButtonStyle buildFilledStyle(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts, {
  required MxFilledPair pair,
}) {
  final Color fill = pair.fillOf(scheme);
  final Color label = pair.labelOf(scheme);
  final Color layer = pair.stateLayerOf(scheme);

  return buildSharedButtonStyle(scheme, texts).copyWith(
    // Disabled is the only state that changes the fill. Everything else is
    // the state layer's job, exactly as `_FilledButtonDefaultsM3` has it.
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return semantic.disabledSurface;
      }

      return fill;
    }),
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

      return label;
    }),
    // Pressed → focused → hovered, the order `_FilledButtonDefaultsM3` reads
    // them in: a pressed control is also hovered, and reading hover first
    // would make every press look like a hover.
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return layer.withValues(alpha: AppStateOpacity.stateLayerPressed);
      }
      if (states.contains(WidgetState.focused)) {
        return layer.withValues(alpha: AppStateOpacity.stateLayerFocus);
      }
      if (states.contains(WidgetState.hovered)) {
        return layer.withValues(alpha: AppStateOpacity.stateLayerHover);
      }

      return null;
    }),
    // **The focus ring, drawn in [label].** `_FilledButtonDefaultsM3` declares
    // no `side` at all, so this slot carries no canonical role to displace —
    // the one condition under which a separate indicator is admitted (M100.36
    // 4A). It is needed because the state layer alone measures under the 3:1
    // WCAG 1.4.11 asks of a focus indicator: `onPrimary` at 10% over `primary`
    // is 1.29:1 in light (`focus_ring_contrast_test.dart` pins it), and the
    // ring token `primary` is the fill itself. The label colour is the one
    // value already guaranteed to read on this fill, whatever the pair.
    //
    // Null everywhere else, so the button keeps its borderless resting shape —
    // a filled button is a fill, not a fill inside a frame.
    side: WidgetStateProperty.resolveWith((states) {
      // Unreachable in practice — `ButtonStyleButton` refuses focus while
      // disabled — but stated so the resolver reads in the same disabled-first
      // order as every other one in this file.
      if (states.contains(WidgetState.disabled)) return null;
      if (states.contains(WidgetState.focused)) {
        return AppInteractionStates.focusIndicatorOf(label);
      }

      return null;
    }),
  );
}

/// A text link's label colour, resolved per state.
///
/// Public for the same reason as [buildFilledStyle]: `MxTextButton`'s
/// destructive variant is the same link with `danger` as its accent, not a
/// second implementation. Every state is a blend of the accent toward the ink
/// — `.mx-textbtn` is the one control in the kit with no surface to wash, so
/// its states are carried by the text itself. Focus adds no colour: the
/// label's underline is the focus indicator, and it is drawn by `MxTextButton`
/// where the decoration cannot inherit into icon glyphs.
WidgetStateProperty<Color> textLinkForeground(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color accent,
}) => WidgetStateProperty.resolveWith((states) {
  if (states.contains(WidgetState.disabled)) return semantic.onDisabled;
  if (states.contains(WidgetState.pressed)) {
    return Color.lerp(
      accent,
      scheme.onSurface,
      AppStateOpacity.textPressedBlend,
    )!;
  }
  if (states.contains(WidgetState.hovered)) {
    return Color.lerp(
      accent,
      scheme.onSurface,
      AppStateOpacity.textHoverBlend,
    )!;
  }

  return accent;
});

/// The low-emphasis action: `MxTextButton`, a bare label in the flow of the
/// content.
///
/// **No padding, no radius and no hover surface — that is the entire point.**
/// Material's `TextButton` insets its label by 12 and paints a tinted overlay
/// on hover, and a text button with a background is an outlined button with
/// the border turned off. Zero padding keeps the label on the same vertical
/// line as everything else in the column; the overlay is suppressed, and every
/// state lives on the text through [textLinkForeground].
///
/// **The 48 floor is kept as height, not as padding.** `AppSpacing` calls the
/// touch target a floor rather than a step for exactly this case: the label
/// may sit flush, but the thing a finger has to hit may not shrink to the
/// height of a line of text. The width floor is zero rather than Material's
/// 64 — a link that pads itself out re-introduces the misalignment on the
/// trailing side, and `tapTargetSize: padded` gives the finger its horizontal
/// 48 without drawing it.
///
/// **Colour is `primary`.** It used to be a separate accent token, because the
/// old dark `primary` was a fill tone measuring 3.33:1 as bare text — failing
/// AA at label size. Since M100.18 inverted it to tone 80 it reads 10.02:1 on
/// the card, so the role carries its own label.
///
/// **Focus is an underline, and it is declared here rather than only in
/// `MxTextButton`.** Suppressing the overlay takes the wash away, and the zero
/// padding leaves no border to draw a ring on — a ring would trace the glyphs
/// themselves. `MxTextButton` had already answered that with a rule under the
/// label at [AppStroke.focus]; stating the same thing in the theme is what
/// makes a *bare* `TextButton` — the `SnackBarAction` this doc comment
/// anticipates — mark itself too, instead of resolving to the one control in
/// the app with no focus-visible state at all. The component keeps its own
/// resolver: it also underlines on hover, and it re-reads the state-blended
/// colour so the rule cannot disagree with the text above it.
///
/// This is the design system's definition of a text button, so anything that
/// builds a `TextButton` inherits the link shape — a future `SnackBarAction`
/// included. A caller that genuinely needs Material's padded button declares
/// its own style; none exists today.
TextButtonThemeData buildTextButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) {
  final foreground = textLinkForeground(
    scheme,
    semantic,
    accent: scheme.primary,
  );

  return TextButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppSizing.touchTarget),
      ),
      alignment: AlignmentDirectional.centerStart,
      // No hover surface and no ripple — the states live on the text.
      overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      foregroundColor: foreground,
      iconColor: foreground,
      // `labelLarge` restated, because `ButtonStyle.textStyle` is taken
      // wholesale rather than merged: a partial style here would drop the
      // rung's size, leading and tracking on its way past
      // `TextButton.defaultStyleOf`.
      textStyle: WidgetStateProperty.resolveWith((states) {
        // Re-weighted like every other button (M100.30). Tokyo's
        // `fontWeight: 'bold'` sits on `MuiButton.root`, which is the base all
        // three variants share — a text button that stayed at the rung would be
        // the one action in the app set lighter than the others.
        final rung = AppTypography.withWeight(
          texts.labelLarge!,
          buttonLabelWeight,
        );
        if (!states.contains(WidgetState.focused)) return rung;

        return rung.copyWith(
          decoration: TextDecoration.underline,
          // Explicit, for the reason `MxTextButton` records: left null the
          // engine picks a default that does not track the state-blended
          // foreground, and the rule visibly disagrees with its own label.
          decorationColor: foreground.resolve(states),
          decorationThickness: AppStroke.focus,
        );
      }),
    ),
  );
}

/// The secondary action: `MxActionButton`'s `secondary` variant.
///
/// **`primary` and `outline`, which is what `_OutlinedButtonDefaultsM3` names
/// for both slots — restored at M100.22.**
///
/// The label read `semantic.secondaryAction`, a slate that is not in the brand
/// family at all (`#454B5E` light, `#C3C6D2` dark). That token dates from when
/// dark `primary` was a fill tone measuring 3.33:1 as bare text; M100.18
/// inverted it to tone 80 and the role now reads **7.27:1 in light and 10.01:1
/// in dark** on a card, 6.89 and 11.35 on the page. There is nothing left for a
/// substitute to buy, and a secondary button whose label is not the brand
/// colour is the one control that disagrees with every link beside it.
///
/// The edge read `semantic.borderControl`, which *is* `scheme.outline` — the
/// scheme has bound them since the role audit. Saying `outline` changes no
/// pixel and removes the second name.
OutlinedButtonThemeData buildOutlinedButtonTheme(
  ColorScheme scheme,
  AppSemanticColors semantic,
  TextTheme texts,
) => OutlinedButtonThemeData(
  style: buildSharedButtonStyle(scheme, texts).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

      return scheme.primary;
    }),
    side: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(color: semantic.disabledSurface);
      }
      // The ring, at the one stroke every focus indicator in the app uses. It
      // replaces the hairline rather than sitting outside it, so focus costs no
      // layout — an `OutlinedBorder`'s side is painted on the shape, not added
      // to the box.
      // **`primary`, and this one is Material's own answer rather than the
      // app's.** `_OutlinedButtonDefaultsM3.side` resolves focus to
      // `_colors.primary` before it falls through to `outline` — the single
      // component in this theme whose canonical *border role* changes with
      // focus. So it is written as the role, not routed through
      // `AppInteractionStates`, which exists for slots M3 leaves empty.
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: scheme.primary, width: AppStroke.focus);
      }

      // `scheme.outline`. The two names were the same value — the scheme binds
      // `outline` to `borderControlLight`/`Dark` — and the M100.3 census that
      // set that value stands: it is `#7D7D85` and `#7D79A2` since M100.22, and
      // scores 3.95/4.16 on a card, 3.74/4.72 on the page and 3.65/3.84 on
      // `surfaceContainer`, all clear of the 3:1 WCAG 1.4.11 asks of a control
      // boundary.
      //
      // Chips take `outlineVariant` instead, and that is M3's split rather than
      // this app's: a filter row of eight pills at 3:1 competes with the content
      // it filters, and a chip carries a fill and a label as well as an edge.
      return BorderSide(color: scheme.outline);
    }),
  ),
);

/// The weight every button label wears.
///
/// **A second emphatic weight, and the app had exactly one before** — 600, the
/// value `AppInk`'s `isEmphasized` still means. This is not that: 600 emphasises
/// a word inside running text, and a button is not running text. Tokyo draws the
/// distinction the same way — `MuiButton.root` is `fontWeight: 'bold'` while
/// `typography.button` is 600 — and it is a large part of why its actions read
/// as pressable rather than as coloured labels.
///
/// One constant rather than three literals: the filled, outlined and text
/// builders all resolve through it, and a button family set one weight apart
/// from its siblings is exactly the drift a shared style exists to stop.
const FontWeight buttonLabelWeight = FontWeight.w700;
