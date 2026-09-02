import 'package:flutter/material.dart';

import 'app_stroke.dart';

/// The state-layer alphas, and the one place they are written down.
///
/// Every value below is transcribed from `design_system/components/mx.css`, and
/// the CSS selector it came from is named beside it. They are not
/// interchangeable: the design gives a row, a card and a control three different
/// hover weights on purpose, because the same wash reads as heavier on a
/// full-width row than on a 48-wide button.
///
/// **What this file replaces is not a set of literals — it is a set of silences.**
/// Before it, `MxCard` and `MxListTile` declared no interaction colours at all,
/// so hover, focus and press came from `ThemeData.hoverColor` and friends: a
/// hardcoded black wash with no seed in it, identical in light and dark, and
/// invisible to `design_audit/` because it exists only as a framework default. A
/// missing decision looks the same as a made one until someone measures it.
abstract final class AppStateOpacity {
  /// A row — `button.mx-tile:hover`, 7% of the secondary text colour.
  static const double hoverRow = 0.07;

  /// An icon-only control — `.mx-iconbtn:hover`, 8% of the secondary text
  /// colour. Heavier than a row because the target is a fraction of the width.
  static const double hoverIcon = 0.08;

  /// An outlined or text-weight control — `.mx-btn--secondary:hover`, 6% of the
  /// accent.
  static const double hoverControl = 0.06;

  /// A card — `.mx-card__action:hover`, 4% of the accent. The lightest of the
  /// four: a card is the largest hover area in the app.
  static const double hoverCard = 0.04;

  /// Press — `.mx-btn--secondary:active` and `.mx-iconbtn:active`, 12% of the
  /// accent.
  static const double pressed = 0.12;

  /// Press on a card — `.mx-card__action:active`, 10%.
  ///
  /// **Two percent under [pressed], and the kit disagrees with itself here.**
  /// `mx.css`'s own header comment says press is a 12% overlay everywhere; the
  /// `.mx-card__action:active` rule it introduces says 10%. The rule is the
  /// behaviour and the comment is the summary, so the rule wins — the same
  /// precedence `docs/document-conventions.md` §9 sets between a rule and the
  /// prose around it.
  static const double pressedCard = 0.10;

  /// Keyboard focus — a 10% overlay, from `mx.css`'s interaction-model header.
  ///
  /// The overlay is never the whole indicator: focus-visible also draws a ring
  /// at [AppStroke.focus]. A 10% wash measures ~1.15:1 against the surface
  /// behind it, and WCAG 1.4.11 asks 3:1 of a focus indicator — on its own it
  /// marks the focused control for people who can already see where they are.
  static const double focus = 0.10;

  /// How far a filled button's fill moves toward the ink on hover —
  /// `.mx-btn--primary:hover`, `color-mix(primary 94%, text-primary)`.
  ///
  /// A *blend*, not an overlay, and that distinction is the bug this fixes. A
  /// 6% accent overlay painted on an accent fill is the accent again: the
  /// primary button had no visible hover at all, because the one state layer it
  /// had was the same colour as the thing underneath it.
  static const double filledHoverBlend = 0.06;

  /// The same, on press — `.mx-btn--primary:active`, 88%.
  static const double filledPressedBlend = 0.12;

  /// How far a text link's label moves toward the ink on hover —
  /// `.mx-textbtn:hover`, `color-mix(… 85%, var(--color-text-primary))`.
  ///
  /// A blend of the label's own colour, like [filledHoverBlend]: `.mx-textbtn`
  /// is the one control in the kit with no surface to wash, so its states are
  /// carried by the text itself rather than by an overlay painted over it.
  static const double textHoverBlend = 0.15;

  /// The same, on press — `.mx-textbtn:active`, 72%.
  static const double textPressedBlend = 0.28;

  /// A disabled label or glyph — `--color-on-disabled`, 38% of the primary text
  /// colour. Translucent by design: a disabled label sits on the page, on a
  /// card and on a disabled fill, so there is no one ground to precompute over.
  static const double disabledContent = 0.38;

  /// How a disabled fill is derived from the ink — 12%, blended to a solid over
  /// the surface. See `AppSemanticColors.disabledSurface`, which holds the
  /// result; this constant records where the result came from.
  static const double disabledSurfaceBlend = 0.12;
}

/// The interaction states, resolved.
///
/// One `WidgetStateProperty` per control shape, so a card hovered in one feature
/// and a card hovered in another cannot land on different washes. The shapes are
/// four because the design gives four weights — see [AppStateOpacity].
///
/// Focus resolves to a wash here and to a ring at the call site. Both are
/// needed: the wash says *something* is focused, the ring says *which*, and only
/// the ring carries enough contrast to do that job.
abstract final class AppInteractionStates {
  /// Buttons — filled, outlined and text-weight.
  static WidgetStateProperty<Color?> controlOverlay(ColorScheme scheme) =>
      _overlay(
        scheme,
        hoverColor: scheme.primary,
        hoverAlpha: AppStateOpacity.hoverControl,
      );

  /// Icon-only controls. Hover is the neutral, not the accent —
  /// `.mx-iconbtn:hover` washes with the secondary text colour, so a row of
  /// icons in an app bar does not light up in brand colour under the pointer.
  static WidgetStateProperty<Color?> iconOverlay(ColorScheme scheme) =>
      _overlay(
        scheme,
        hoverColor: scheme.onSurfaceVariant,
        hoverAlpha: AppStateOpacity.hoverIcon,
      );

  /// A tappable card.
  static WidgetStateProperty<Color?> cardOverlay(ColorScheme scheme) =>
      _overlay(
        scheme,
        hoverColor: scheme.primary,
        hoverAlpha: AppStateOpacity.hoverCard,
        pressedAlpha: AppStateOpacity.pressedCard,
      );

  /// A row in a list.
  static WidgetStateProperty<Color?> rowOverlay(ColorScheme scheme) => _overlay(
    scheme,
    hoverColor: scheme.onSurfaceVariant,
    hoverAlpha: AppStateOpacity.hoverRow,
  );

  /// The focus-visible ring every control draws, at the one stroke and the one
  /// colour: `primary`.
  ///
  /// **This used to take a token of its own, and the token was the bug**
  /// (M100.18, M100.19). WCAG 1.4.11 asks 3:1 of a focus indicator, and the
  /// old dark `primary` was a fill tone that missed it on the two grounds a
  /// focused control actually sits on — a card at 2.90:1 and a selected pill's
  /// own fill at 2.11:1. The answer taken then was a second token; the answer
  /// taken since is to move the palette, because a component belongs on the
  /// role M3 gives it.
  ///
  /// | ground | `primary` dark, now |
  /// |---|---|
  /// | `background` | 11.36:1 |
  /// | `surface` | 10.02:1 |
  /// | `primaryContainer` | 7.37:1 |
  /// | `secondaryContainer` | 7.31:1 |
  ///
  /// Light was never in question: 6.89 / 7.27 / 5.57 / 6.02. Pinned per ground,
  /// in both modes, by `focus_ring_contrast_test.dart`.
  /// **Only for a slot Material 3 leaves empty.** M100.23 renamed this from
  /// `focusRing` because the old name invited exactly the misuse it was being
  /// put to: four components were resolving *their canonical border role* to
  /// this, so tabbing onto a chip, a segment, a switch or a ticked checkbox
  /// swapped a semantic role for an interaction cue. A Material colour slot
  /// carries what the component *is*; focus is what is happening to it, and the
  /// two must not share a channel.
  ///
  /// Two callers remain and both are legitimate, because `_FilledButtonDefaultsM3`
  /// and `_IconButtonDefaultsM3` declare no `side` at all — there is no
  /// canonical role in those slots to displace. Everywhere else the focus cue
  /// belongs in [controlOverlay] or [iconOverlay], which is where Material's own
  /// defaults put it.
  ///
  /// `OutlinedButton` is the one component whose *border* legitimately turns
  /// `primary` on focus, and it does not call this: `_OutlinedButtonDefaultsM3
  /// .side` names the role itself, so `app_button_themes.dart` writes
  /// `scheme.primary` where the source guard can read it.
  static BorderSide focusIndicator(ColorScheme scheme) =>
      focusIndicatorOf(scheme.primary);

  /// The same ring — same stroke, same shape — in a colour the caller supplies.
  ///
  /// **For the one control whose ground is not a surface.** Every ring above
  /// is drawn on a page, a card or a pill's own fill, and `primary` clears 3:1
  /// on all three. A *filled* button's ground is `primary` itself, so the ring
  /// would be that colour on that colour — 1.00:1, which is not a weak ring
  /// but no ring at all.
  ///
  /// So the filled button draws its ring in its **own label colour**, the one
  /// value already guaranteed to read on that fill: `onPrimary` on `primary`,
  /// `onError` on `error`, `onSecondaryContainer` on `secondaryContainer` —
  /// 5.76:1 at the tightest. Deriving it from the pair the button already
  /// carries is what keeps a future variant from needing a new measurement.
  ///
  /// `focus_ring_contrast_test.dart` pins both halves.
  static BorderSide focusIndicatorOf(Color color) =>
      BorderSide(color: color, width: AppStroke.focus);

  /// Ordered pressed → focused → hovered, and the order is load-bearing: a
  /// control being pressed is also hovered, and reading hover first would make
  /// every press look like a hover.
  static WidgetStateProperty<Color?> _overlay(
    ColorScheme scheme, {
    required Color hoverColor,
    required double hoverAlpha,
    double pressedAlpha = AppStateOpacity.pressed,
  }) => WidgetStateProperty.resolveWith((states) {
    if (states.contains(WidgetState.pressed)) {
      return scheme.primary.withValues(alpha: pressedAlpha);
    }
    if (states.contains(WidgetState.focused)) {
      return scheme.primary.withValues(alpha: AppStateOpacity.focus);
    }
    if (states.contains(WidgetState.hovered)) {
      return hoverColor.withValues(alpha: hoverAlpha);
    }

    return null;
  });
}
