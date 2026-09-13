import 'package:flutter/material.dart';

import 'app_material_roles.dart';

/// Colour tokens — the Tokyo handoff's palette (M100.86), under the names the
/// app's call sites mean.
///
/// **Two kinds of value live here, and the split is the owner's decision of
/// 2026-09-13** (`v1-freeze.md` §3c):
///
/// * **A fill** — what the kit paints: a button's container, a dot, a ring, a
///   progress arc. These are the handoff's hex, verbatim, even where they fail
///   a ratio. The owner accepted that a *non-text* use may sit under WCAG
///   1.4.11's 3:1 — light `success` reads 2.53:1 and `warning` 1.83:1 on the
///   page — and `app_theme_test.dart` pins the accepted figures as floors so
///   they record a decision rather than drift.
/// * **An ink** — the same hue as *text*. Where a fill reads under 4.5:1 on the
///   grounds text lands on (the page, the card, `Low`, the inset tile), its
///   ink is solved in CIELAB: hue and chroma held, lightness moved until the
///   worst of those grounds clears 4.6. Where the fill already clears it —
///   every dark status colour — the ink *is* the fill. `AppInk` is how a
///   feature reaches the inks; it never chooses between the two by hand.
///
/// Every name says what the colour *means*, never what it looks like.
abstract final class AppColors {
  /// The hue every neutral in both modes carries a trace of — the brand.
  static const Color seed = primaryLight;

  // --- Text -----------------------------------------------------------------

  static const Color textPrimaryLight = Color(0xFF0F1638);
  static const Color textPrimaryDark = Color(0xFFE4E8FA);
  static const Color textSecondaryLight = Color(0xFF4A5278);
  static const Color textSecondaryDark = Color(0xFFA4ACD0);

  /// The fill and border of a disabled control — the ink at 12%, flattened
  /// over the paper once (MX-VIS-002 R7), because a translucent token renders
  /// as a different colour on every ground it lands on.
  /// `app_semantic_colors_test.dart` pins each back to that blend.
  static const Color disabledSurfaceLight = Color(0xFFE2E3E7);
  static const Color disabledSurfaceDark = Color(0xFF2C3351);

  /// A disabled label or glyph — the ink at 38%, the handoff's `op-disabled`.
  /// Translucent where the fill above is solid: a disabled label has three
  /// grounds (page, card, disabled fill), a disabled fill has one.
  static const Color onDisabledLight = Color(0x610F1638);
  static const Color onDisabledDark = Color(0x61E4E8FA);

  // --- Brand ----------------------------------------------------------------

  static const Color primaryLight = Color(0xFF5265F5);
  static const Color primaryDark = Color(0xFF8B9AFF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF11173A);

  /// The brand as text — a text link, an outlined button's label, a tab label,
  /// `AppInk.accent`. Light's fill reads 3.95:1 at worst on those grounds; this
  /// reads 4.60. Dark's fill already reads 5.22, so it is the fill.
  static const Color accentInkLight = Color(0xFF425BE8);
  static const Color accentInkDark = primaryDark;

  /// The snackbar's action label. It sits on `inverseSurface`, which does not
  /// flip with the theme, so neither does this: `inversePrimary` reads 4.32:1
  /// on the slate in light and 2.40:1 in dark, and this reads 4.61 in both.
  static const Color inversePrimaryInk = Color(0xFF93A0FF);

  /// `AppInk.secondary` and `AppInk.tertiary` as text — the import preview's
  /// counts and the trash row's urgency. Light's fills read 3.23:1 and 3.15:1
  /// at worst on the grounds text lands on; these read 4.62. Dark's fills
  /// already read 5.88 and 6.03, so they are the fills.
  static const Color secondaryInkLight = Color(0xFF5263BD);
  static const Color secondaryInkDark = AppMaterialRoles.secondaryDark;
  static const Color tertiaryInkLight = Color(0xFF6C54D6);
  static const Color tertiaryInkDark = AppMaterialRoles.tertiaryDark;

  // --- Status ---------------------------------------------------------------

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF2BA88B);
  static const Color successDark = Color(0xFF6FE0BD);
  static const Color successInkLight = Color(0xFF027861);
  static const Color successInkDark = successDark;

  /// Card due soon, a streak at risk. The kit's warning is its streak orange —
  /// its Banner gives the `warning` tone to `streak`.
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFFC658);
  static const Color warningInkLight = Color(0xFF955E00);
  static const Color warningInkDark = warningDark;

  /// Answer forgotten, destructive action, reset. `error` is `danger`, not a
  /// second red.
  static const Color dangerLight = Color(0xFFDC2D4E);
  static const Color dangerDark = Color(0xFFFF8FA3);
  static const Color dangerInkLight = Color(0xFFCF1B44);
  static const Color dangerInkDark = dangerDark;

  /// Status that carries a fact. **The brand family, not a fifth hue**: the
  /// kit's Banner gives its `info` tone to `primary`.
  static const Color infoLight = primaryLight;
  static const Color infoDark = primaryDark;
  static const Color infoInkLight = accentInkLight;
  static const Color infoInkDark = accentInkDark;

  // --- Status containers ----------------------------------------------------
  //
  // **Derived, because the handoff names no container for success or warning,
  // and by the method its own containers follow.** Light is the fill at 15%
  // over white — the kit's `primaryContainer` and `errorContainer` reconstruct
  // at 15–17% — and dark is the fill at 28% over the page, where the kit's dark
  // `primaryContainer` reconstructs at 27–31%. The ink on each is solved in
  // CIELAB to 7:1, inside the band the kit's own `on*Container` pairs occupy
  // (7.8–10.8). `danger` has no pair here: it reuses `errorContainer`.

  static const Color successContainerLight = Color(0xFFDFF2EE);
  static const Color successContainerDark = Color(0xFF264951);
  static const Color onSuccessContainerLight = Color(0xFF005A48);
  static const Color onSuccessContainerDark = Color(0xFF7EEFCB);

  static const Color warningContainerLight = Color(0xFFFEF0DA);
  static const Color warningContainerDark = Color(0xFF4F4235);
  static const Color onWarningContainerLight = Color(0xFF744800);
  static const Color onWarningContainerDark = Color(0xFFFFD58F);

  /// `info` is the brand family, so its container pair is the brand's.
  static const Color infoContainerLight =
      AppMaterialRoles.primaryContainerLight;
  static const Color infoContainerDark = AppMaterialRoles.primaryContainerDark;
  static const Color onInfoContainerLight =
      AppMaterialRoles.onPrimaryContainerLight;
  static const Color onInfoContainerDark =
      AppMaterialRoles.onPrimaryContainerDark;

  // --- Progress -------------------------------------------------------------

  /// The kit's progress draws in `primary` on the inactive track its slider
  /// uses, `surfaceContainerHighest`: 3.50:1 in light and 3.85:1 in dark.
  static const Color progressTrackLight =
      AppMaterialRoles.surfaceContainerHighestLight;
  static const Color progressTrackDark =
      AppMaterialRoles.surfaceContainerHighestDark;
  static const Color progressFillLight = primaryLight;
  static const Color progressFillDark = primaryDark;

  // --- Due chip -------------------------------------------------------------

  /// The warm pill that says how many cards are waiting. The kit spends one
  /// warm family on everything time-pressured, so this is the warning pair.
  static const Color streakContainerLight = warningContainerLight;
  static const Color streakContainerDark = warningContainerDark;
  static const Color onStreakContainerLight = onWarningContainerLight;
  static const Color onStreakContainerDark = onWarningContainerDark;

  // --- Outside the app surface ----------------------------------------------

  /// The letterbox around the phone-sized frame on the web build. It paints
  /// outside `MaterialApp`, where no `ColorScheme` reaches, and must read as
  /// "not the app" in both modes.
  static const Color webLetterbox = Color(0xFF6E759F);

  /// A modal scrim's base, laid over the page at 45%. **Dark is pure black**,
  /// as the handoff has it; `color_system_rules_test.dart` exempts that role
  /// from the seed-trace rules by name.
  static const Color scrimLight = Color(0xFF0A0E27);
  static const Color scrimDark = Color(0xFF000000);

  /// The colour a cast shadow is mixed from, at the alpha `shadowsFor` gives
  /// each level. Pure black in dark, for the reason [scrimDark] is.
  static const Color shadowLight = Color(0xFF0F1638);
  static const Color shadowDark = Color(0xFF000000);
}
