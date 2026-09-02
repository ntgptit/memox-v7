import 'package:flutter/material.dart';

import 'app_interaction_states.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_spacing.dart';
import 'app_stroke.dart';

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
      over ?? scheme.surface,
    );

/// Geometry shared by every button.
///
/// 48 high before padding: the minimum touch target, enforced here rather than
/// per component so no button in the app can be built below it.
ButtonStyle buildSharedButtonStyle(ColorScheme scheme) => ButtonStyle(
  minimumSize: const WidgetStatePropertyAll<Size>(
    Size(64, AppSpacing.minimumTouchTarget),
  ),
  padding: const WidgetStatePropertyAll<EdgeInsets>(
    EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
  ),
  shape: WidgetStatePropertyAll<OutlinedBorder>(
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
  ),
  // **Hover used to fall through to `null`**, which handed it to Material's
  // default — a wash of the *foreground* colour, so a filled button hovered
  // toward white and an outlined one toward its own label. Web and desktop only,
  // and Android is the release target (AD-04) — but the web build is the E2E
  // channel, so it shows up in exactly the place this project takes screenshots.
  overlayColor: AppInteractionStates.controlOverlay(scheme),
);

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
) => FilledButtonThemeData(
  style: buildFilledStyle(
    scheme,
    semantic,
    fill: scheme.primary,
    label: scheme.onPrimary,
  ),
);

/// The tonal action: emphasis above outlined, below the brand fill.
///
/// `secondaryContainer`/`onSecondaryContainer` — the same pair the selected
/// pill already owns, so "tinted surface = secondary emphasis" stays one fact.
/// Exists for actions that repeat down a list (the deck row's Study pill):
/// a column of `primary` fills sprays the accent, a column of outlines loses
/// to the due chip beside it, and tonal is the middle the owner picked
/// (2026-08-05, recorded in `docs/reviews/design-parity-checklist.md`).
/// A `ButtonStyle`, not a `FilledButtonThemeData`: `ThemeData` has one slot
/// for both `FilledButton` variants, and this app's `filledButtonTheme`
/// already claims it for the brand fill — a second theme entry would either
/// collide or silently restyle every primary button. Callers apply it as
/// `FilledButton(style: buildFilledTonalStyle(...))`, optionally `copyWith`
/// geometry of their own.
ButtonStyle buildFilledTonalStyle(
  ColorScheme scheme,
  AppSemanticColors semantic,
) => buildFilledStyle(
  scheme,
  semantic,
  fill: scheme.secondaryContainer,
  label: scheme.onSecondaryContainer,
);

/// A filled button's colours, for any fill.
///
/// Public so `MxActionButton`'s destructive variant can be the same button with
/// a different pair rather than a second implementation. It used to reach for
/// `FilledButton.styleFrom(backgroundColor: error)`, and that is a flat
/// `WidgetStatePropertyAll` which **shadows the theme's property entirely** —
/// so a destructive button did not darken on press and, worse, stayed fully red
/// when disabled while its label went to 38%. A button that looks armed and is
/// inert is the failure this whole file exists to prevent.
ButtonStyle buildFilledStyle(
  ColorScheme scheme,
  AppSemanticColors semantic, {
  required Color fill,
  required Color label,
}) => buildSharedButtonStyle(scheme).copyWith(
  backgroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.disabledSurface;
    if (states.contains(WidgetState.pressed)) {
      return Color.lerp(
        fill,
        scheme.onSurface,
        AppStateOpacity.filledPressedBlend,
      );
    }
    // **A blend, where every other control gets an overlay.** The shared
    // `overlayColor` washes 6% of `primary`, and 6% of the accent painted on
    // the accent is the accent — the primary button had no visible hover at
    // all. `.mx-btn--primary:hover` mixes toward the ink instead, and only a
    // colour that is not already the fill can show up on it.
    if (states.contains(WidgetState.hovered)) {
      return Color.lerp(
        fill,
        scheme.onSurface,
        AppStateOpacity.filledHoverBlend,
      );
    }

    return fill;
  }),
  foregroundColor: WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

    return label;
  }),
  // **The focus ring, and it is drawn in [label] rather than in the ring
  // token.** Same argument as the hover blend directly above, one state later:
  // the shared `overlayColor` washes 10% of `primary` on focus, and 10% of the
  // accent painted on the accent is the accent — so the app's primary CTA had
  // no focus indicator at all, in either mode. Nor would the usual ring fix
  // it: `scheme.primary` is the same indigo family as the fill and
  // measures 1.02:1 on it in light. `AppInteractionStates.focusRingOf` records
  // the table; the short version is that the label colour is the one value
  // already guaranteed to read on this fill, whatever the variant.
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
    // `primaryInk`, not `primary`: the fill is Tokyo's `#5569FF` verbatim and
    // reads 3.96:1 as text on the light page (M100.27).
    accent: semantic.primaryInk,
  );

  return TextButtonThemeData(
    style: ButtonStyle(
      padding: const WidgetStatePropertyAll<EdgeInsets>(EdgeInsets.zero),
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppSpacing.minimumTouchTarget),
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
        final rung = texts.labelLarge;
        if (!states.contains(WidgetState.focused)) return rung;

        return rung?.copyWith(
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
) => OutlinedButtonThemeData(
  style: buildSharedButtonStyle(scheme).copyWith(
    foregroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return semantic.onDisabled;

      // The brand as ink, not the fill role — `primary` is Tokyo's `#5569FF`
      // verbatim since M100.27 and reads 3.96:1 as a label on the light page;
      // `primaryInk` is Tokyo's `primary.dark` there and the fill itself in
      // dark. `_OutlinedButtonDefaultsM3` names `primary`; this is the one
      // deliberate departure, and `m3_role_binding_guard_test.dart` records
      // it.
      return semantic.primaryInk;
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
