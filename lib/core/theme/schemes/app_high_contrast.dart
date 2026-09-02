import 'package:flutter/material.dart';

import '../foundations/app_semantic_colors.dart';

/// The palette shift Flutter applies when the platform reports
/// `MediaQuery.highContrast`.
///
/// **Until now the flag was read by nothing.** `MaterialApp` has
/// `highContrastTheme` and `highContrastDarkTheme` slots and the app left both
/// null, so a user who had turned the setting on in Android's accessibility
/// menu got exactly the same pixels as one who had not. That is worth naming
/// as a gap rather than as a default: the app *already knows* its hairline is
/// the weakest thing it draws — `AppSemanticColors.borderControl` exists
/// because `borderSubtle` measures 1.45:1 on a card and WCAG 1.4.11 asks 3:1 —
/// so the one palette that should have answered the flag had already been
/// worked out and was only being spent on controls.
///
/// **Three swaps, no new colours.** Everything below is an existing token
/// standing in for another; the file adds no hex, which is what keeps this a
/// re-pointing of the palette rather than a second palette to maintain.
///
/// | token | normal | high contrast | why |
/// |---|---|---|---|
/// | `borderSubtle` | 1.45 / 2.04 | `onSurfaceVariant` — 6.41 / 7.30 | every hairline reaches 3:1 on all three grounds |
/// | `borderControl` | 3.19 / 3.00 | `onSurfaceVariant` — 6.41 / 7.30 | already passed on a card, but 2.79 / 2.54 on a muted tile |
/// | `borderAccent` | 1.89 / 1.45 | `primary` — 7.27 / 10.02 | the Today card's edge is decoration at 1.45 |
/// | `onDisabled` | 2.37 / 3.20 | the same ink at 62% — 4.88 / 6.33 | see below |
///
/// Light figure first, dark second, each measured against `surface`.
///
/// **Why `onSurfaceVariant` and not `borderControl` for the hairline.**
/// `borderControl` is the 3:1 edge, and it clears 3:1 on a card and on the page
/// — but on a *muted tile* it reaches only 2.79:1 in light and 2.54:1 in dark,
/// and the inset tile is exactly where the app puts a row of options. A
/// high-contrast palette that still has a ground it fails on has not done the
/// one thing it exists for. The secondary ink clears every ground in both
/// modes, at 5.61:1 at its tightest.
///
/// That the border and the secondary label then share a colour is the normal
/// shape of a high-contrast mode, not a collision: what the flag asks for is
/// fewer distinct greys, each further from its ground.
///
/// **Raising `onDisabled` is the one swap that trades something away, and it is
/// the trade the flag is asking for.** A disabled control is *supposed* to
/// recede, and 38% is what makes it read as unavailable at a glance; pushing it
/// to 62% costs some of that. But 2.37:1 in light is below the 3:1 floor for
/// any graphic a user has to perceive at all, and a control nobody can read is
/// worse than one whose unavailability takes a moment longer to notice. 62%
/// lands at 4.88:1 — legible, and still less than a third of `onSurface`'s
/// 14.81:1, so the hierarchy survives.
///
/// **What is deliberately NOT changed.** Not `primary`, not the semantic four,
/// not the surface ladder. High contrast is a legibility setting, not a second
/// design: moving the brand or the success green would make the app a different
/// app for the people who turned it on, and every one of those already clears
/// its floor. The focus indicator is untouched for the same reason: it is
/// `scheme.primary`, which clears 3:1 on every ground it lands on.
///
/// The alpha the raised disabled ink is built from — the base is
/// `AppStateOpacity.disabledContent`, 38%.
const double highContrastDisabledAlpha = 0.62;

/// [base] with its borders and its disabled ink re-pointed for high contrast.
///
/// Takes the built extension rather than rebuilding one from `AppColors`, so a
/// token added to `AppSemanticColors` arrives here already carried and only the
/// four named below diverge. A named constructor would have to list all
/// eighteen, and the seventeenth would be the one someone forgot.
AppSemanticColors highContrastSemantics(
  AppSemanticColors base,
  ColorScheme scheme,
) => base.copyWith(
  borderSubtle: scheme.onSurfaceVariant,
  borderControl: scheme.onSurfaceVariant,
  borderAccent: scheme.primary,
  onDisabled: scheme.onSurface.withValues(alpha: highContrastDisabledAlpha),
);

/// [scheme] with the two Material border roles pointed at the same stronger
/// edge.
///
/// `outline` and `outlineVariant` are what an *untended* widget reads — the app's
/// own components go through `AppSemanticColors` — so they have to move with it
/// or a third-party control keeps drawing the normal-contrast hairline on a
/// screen where everything around it got stronger.
///
/// The parameter is `scheme` rather than `base` on purpose: the guard's
/// role-name allowlist recognises a scheme by the three names the codebase
/// gives it, and this is the one place a scheme is re-pointed rather than read.
ColorScheme highContrastScheme(ColorScheme scheme) => scheme.copyWith(
  outline: scheme.onSurfaceVariant,
  outlineVariant: scheme.onSurfaceVariant,
);
