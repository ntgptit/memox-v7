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
/// **Three swaps, no new colours.** Everything swapped below is an existing
/// token standing in for another; the file adds no hex, which is what keeps
/// this a re-pointing of the palette rather than a second palette to maintain.
/// The fourth row is here because it is the one a reader expects to be swapped
/// and it deliberately is not.
///
/// | token | normal | high contrast | why |
/// |---|---|---|---|
/// | `borderSubtle` | 1.08 / 1.32 | **unchanged** | a row separator identifies nothing; 1.4.11 exempts it, and the owner reviewed both stronger recipes and rejected them |
/// | `borderControl` | 3.71 / 4.68 | `onSurfaceVariant` — 5.28 / 6.47 | already passed on a card; the component boundary keeps the strongest edge |
/// | `borderAccent` | 1.80 / 3.88 | `primary` — 5.67 / 11.27 | the Today card's edge is decoration at 1.80 |
/// | `onDisabled` | 2.11 / 2.62 | the same ink at 62% — 3.81 / 5.12 | see below |
///
/// Light figure first, dark second, each measured against `surface` and
/// composited over it first (the inks carry alpha). **Re-measured at the
/// Design System V1 closure (A20.1 P2-11)**: the table had carried figures
/// from an earlier palette — `onDisabled` 2.37 / 3.20 → 4.88 / 6.33 and
/// `onSurface` 14.81 — that were 28% optimistic at the cell the 62% decision
/// rests on. The real light figure is **3.81:1**, above the 3:1 floor by a
/// smaller margin than the old table implied, and `high_contrast_figures_test`
/// now measures every cell so the table cannot drift again.
///
/// **The hairline was re-pointed twice and is now left alone** (M100.82, owner
/// review 2026-09-11). It shipped as `onSurfaceVariant` — the secondary
/// *label* ink, 5.28 / 6.47 — on a measurement that said `borderControl` was
/// the only alternative and that it failed the muted tile at 2.79 / 2.54. That
/// pairing measures **3.39 / 3.50** today: the tokens moved underneath the
/// decision (the muted tile at M100.61, the control edge at M100.48) and
/// nothing re-derived it, because a floor only ever asks whether a value is
/// dark enough. So the reason expired while the value stayed.
///
/// What that cost was visible on Library: every divider in high contrast was
/// drawn in body-label ink, and a deck-list hairline read as a rule ruled
/// across the card. The owner reviewed the repaired version — `borderControl`,
/// 3.71 / 4.68 — against the normal screen on a rendered golden and rejected
/// that too. **The hairline is the normal token in both palettes now.**
///
/// **What that trades, stated rather than buried.** A user on high contrast
/// gets no stronger separator than anyone else: 1.08:1 in light. It is a real
/// reduction against what this file used to promise, and it is not an SC
/// failure — 1.4.11 asks 3:1 of the information required to *identify* a
/// component or understand a graphic, and a line between two rows carries
/// none. The rows are told apart by their content and their spacing; the edges
/// that do identify something — a control's boundary, the Today card's accent
/// — are still swapped, and `outline` moves with `borderControl` so an
/// untended widget cannot draw a weak *component* edge either.
///
/// The ceiling that was missing is kept anyway: `app_high_contrast_test.dart`
/// asserts the hairline reads strictly quieter than `borderControl`. It holds
/// by a wide margin now, and it is the assertion that caught the flat ladder
/// in the first place — a re-point back up to the strong token is one line.
///
/// **Raising `onDisabled` is the one swap that trades something away, and it is
/// the trade the flag is asking for.** A disabled control is *supposed* to
/// recede, and 38% is what makes it read as unavailable at a glance; pushing it
/// to 62% costs some of that. But 2.11:1 in light is below the 3:1 floor for
/// any graphic a user has to perceive at all (2.11:1 in light on the current
/// palette), and a control nobody can read is
/// worse than one whose unavailability takes a moment longer to notice. 62%
/// lands at 3.81:1 in light and 5.12:1 in dark — above the 3:1 floor, and
/// still a third of `onSurface`'s 11.50 / 12.01, so the hierarchy survives.
/// The 62% is kept at that measured figure, not raised: SC 1.4.3 exempts
/// inactive components, and the floor this palette sets for itself is 3:1.
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
/// three named below diverge. A named constructor would have to list all
/// eighteen, and the seventeenth would be the one someone forgot.
AppSemanticColors highContrastSemantics(
  AppSemanticColors base,
  ColorScheme scheme,
) => base.copyWith(
  borderControl: scheme.onSurfaceVariant,
  borderAccent: scheme.primary,
  onDisabled: scheme.onSurface.withValues(alpha: highContrastDisabledAlpha),
);

/// [scheme] with the two Material border roles pointed at [hc]'s edges.
///
/// `outline` and `outlineVariant` are what an *untended* widget reads — the app's
/// own components go through `AppSemanticColors` — so they have to move with it
/// or a third-party control keeps drawing the normal-contrast hairline on a
/// screen where everything around it got stronger.
///
/// **They read the semantic pair rather than re-deriving it**, which is the
/// half M100.82 fixed. Both used to be assigned `scheme.onSurfaceVariant` here
/// while [highContrastSemantics] assigned the same value there — one decision
/// written at two call sites, so `app_divider_theme.dart`'s claim that
/// "`outlineVariant` *is* `borderSubtle`" held by coincidence and would have
/// parted the moment either side was retuned. It parts no longer.
///
/// The scheme is still the parameter the guard's role-name allowlist wants:
/// this is the one place a scheme is re-pointed rather than read.
ColorScheme highContrastScheme(ColorScheme scheme, AppSemanticColors hc) =>
    scheme.copyWith(outline: hc.borderControl, outlineVariant: hc.borderSubtle);
