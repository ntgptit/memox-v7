import 'package:flutter/material.dart';

import 'app_material_roles.dart';

/// Colour tokens — the v3 palette from
/// `design_system/MemoX Design System/colors_and_type.css` (2026-09-17,
/// GC-1 / GC-2).
///
/// **The invariant every value here obeys (AD-14).** A Material component
/// binds to the canonical M3 role its `_XxxDefaultsM3` names; when a role
/// fails a contrast or hierarchy ratio, the *palette* moves — never a
/// substitute token, never a lowered floor.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// **What is not here.** The `ColorScheme` roles this app declares only
/// because `fromSeed` would otherwise invent them — the container ladder, the
/// `tertiary` family, the `inverse*` pair — live in `AppMaterialRoles`. What
/// stays in this file is every role that is a memox decision Material happens
/// to have a slot for — `primary`, `onSurface`, `onSurfaceVariant`, `error`
/// (as `danger`), `shadow`, `scrim` — plus the legacy `AppSemanticColors`
/// values GC-2 keeps.
abstract final class AppColors {
  /// The palette's declared seed. Nothing generates from it any more —
  /// `app_theme.dart` builds its `ColorScheme`s explicitly — but the design
  /// system names it (`--color-seed`) and the parity test pins the two
  /// together.
  static const Color seed = primaryLight;

  // --- Text and lines --------------------------------------------------------

  /// `onSurface` — GC-1.
  static const Color textPrimaryLight = Color(0xFF0F1638);
  static const Color textPrimaryDark = Color(0xFFE4E8FA);

  /// `onSurfaceVariant` — GC-1.
  static const Color textSecondaryLight = Color(0xFF4A5278);
  static const Color textSecondaryDark = Color(0xFFA4ACD0);

  /// `onSurface` at 12%, flattened over `surface` (GC-2). Solid rather than
  /// translucent so a disabled control paints one colour on a page, a card
  /// and a dialog alike; `app_semantic_colors_test.dart` pins the blend.
  static const Color disabledSurfaceLight = Color(0xFFDBDEE6);
  static const Color disabledSurfaceDark = Color(0xFF242840);

  /// `onSurface` at 38% (GC-2) — translucent, because the label sits on
  /// whichever ground the disabled control does.
  static const Color onDisabledLight = Color(0x610F1638);
  static const Color onDisabledDark = Color(0x61E4E8FA);

  // --- Brand and actions -------------------------------------------------------

  /// `primary` — GC-1.
  static const Color primaryLight = Color(0xFF5265F5);
  static const Color primaryDark = Color(0xFF8B9AFF);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color onPrimaryDark = Color(0xFF11173A);

  // --- Semantic ----------------------------------------------------------------
  //
  // `danger` **is** the `error` role — GC-1's `error` row reads these same two
  // constants, one red system rather than a second. `success`/`warning` are
  // v3 literals with no `ColorScheme` slot of their own.

  static const Color successLight = Color(0xFF2BA88B);
  static const Color successDark = Color(0xFF6FE0BD);
  static const Color warningLight = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFFFC658);
  static const Color dangerLight = Color(0xFFDC2D4E);
  static const Color dangerDark = Color(0xFFFF8FA3);

  // --- Text inks (GC-3, owner answer A1) --------------------------------------
  //
  // Same hue and saturation as the fill above; lightness moved to the first
  // value that reads >= 4.5:1 on all five text grounds of its mode. A dark
  // ink that already clears 4.5:1 as the fill derives from the fill constant
  // instead of repeating the hex. `inversePrimaryInk` is invariant: its one
  // ground, `inverseSurface`, does not change with theme.

  /// From [primaryLight]/[primaryDark] (4.52 / 4.52).
  static const Color accentInkLight = Color(0xFF3E53F4);
  static const Color accentInkDark = Color(0xFF8D9CFF);

  /// From [dangerLight]/[dangerDark] (4.52 / 5.27 as the fill).
  static const Color dangerInkLight = Color(0xFFC82141);
  static const Color dangerInkDark = dangerDark;

  /// From [successLight]/[successDark] (4.56 / 7.10 as the fill).
  static const Color successInkLight = Color(0xFF1E7460);
  static const Color successInkDark = successDark;

  /// v3's own `on-warning` in light (11.22); dark clears 4.5:1 as the fill
  /// (7.32).
  static const Color warningInkLight = Color(0xFF3A2A00);
  static const Color warningInkDark = warningDark;

  /// From `AppMaterialRoles.secondaryLight/Dark` (4.53 / 5.00 as the fill).
  static const Color secondaryInkLight = Color(0xFF4B5CD0);
  static const Color secondaryInkDark = AppMaterialRoles.secondaryDark;

  /// From `AppMaterialRoles.tertiaryLight/Dark` (4.54 / 5.12 as the fill).
  static const Color tertiaryInkLight = Color(0xFF6945F2);
  static const Color tertiaryInkDark = AppMaterialRoles.tertiaryDark;

  /// On `AppMaterialRoles.inverseSurfaceLight/Dark` (`#34395D`, invariant) —
  /// 4.56 in both modes, so one constant serves both.
  static const Color inversePrimaryInk = Color(0xFF919FFF);

  // --- Status containers ------------------------------------------------------
  //
  // success/warning containers are v3 `*-soft`: the fill at 10%/18% (success)
  // or 12%/18% (warning) flattened over `surfaceContainerLowest` (GC-2). Each
  // `on*Container` derives from the matching ink (GC-2) rather than repeating
  // the hex.
  //
  // `info`/`infoContainer`/`onInfoContainer` are unchanged (owner answer A2)
  // — outside the v3 palette.

  static const Color successContainerLight = Color(0xFFEAF6F3);
  static const Color successContainerDark = Color(0xFF243E52);
  static const Color onSuccessContainerLight = successInkLight;
  static const Color onSuccessContainerDark = successInkDark;

  static const Color warningContainerLight = Color(0xFFFEF3E2);
  static const Color warningContainerDark = Color(0xFF3D393F);
  static const Color onWarningContainerLight = warningInkLight;
  static const Color onWarningContainerDark = warningInkDark;

  static const Color infoContainerLight = Color(0xFFDEE8EC);
  static const Color infoContainerDark = Color(0xFF153D4E);
  static const Color onInfoContainerLight = Color(0xFF003247);
  static const Color onInfoContainerDark = Color(0xFFC7E0EB);

  // --- Progress ---------------------------------------------------------------
  //
  // Its own family, not the accent: a bar drawn in `primary` beside a button
  // drawn in `primary` leaves nothing telling the eye which one it can press.
  // v3 points both at existing roles (GC-2) rather than naming new colours.

  /// = `surfaceContainerHigh`.
  static const Color progressTrackLight =
      AppMaterialRoles.surfaceContainerHighLight;
  static const Color progressTrackDark =
      AppMaterialRoles.surfaceContainerHighDark;

  /// = `primary`.
  static const Color progressFillLight = primaryLight;
  static const Color progressFillDark = primaryDark;

  // --- Due chip -----------------------------------------------------------

  /// v3 paints overdue counts in the warning family (GC-2): the due chip
  /// reuses `warningContainer`/`onWarningContainer` rather than owning a
  /// separate warm pair.
  static const Color streakContainerLight = warningContainerLight;
  static const Color streakContainerDark = warningContainerDark;
  static const Color onStreakContainerLight = onWarningContainerLight;
  static const Color onStreakContainerDark = onWarningContainerDark;

  /// Status that genuinely carries information: streak, counters, "3 of 20".
  /// Not a decorative accent — plain metadata uses `textSecondary`.
  static const Color infoLight = Color(0xFF00729A);
  static const Color infoDark = Color(0xFF33C2FF);

  /// The letterbox around the phone-sized frame on the web build.
  ///
  /// **A non-theme constant, deliberately**: it paints outside `MaterialApp`,
  /// where no `ColorScheme` or extension can reach, and it must not change
  /// with the user's theme — the surround is "not the app" in both modes.
  ///
  /// Outside the app surface entirely — Android never shows it (AD-04) — but it
  /// is still a colour, and a colour in a widget is a colour the theme cannot
  /// change. It has to read as "not the app" rather than as another panel.
  ///
  /// `#6E7288` from `design_system/tokens/colors.css`, replacing `#14162A`. The
  /// design system reaches the same goal from the opposite direction: its own
  /// `ui_kits/memox-app/index.html` paints exactly this grey behind the phone
  /// frame, so the surround is *lighter* than every app surface in dark mode
  /// instead of darker than every one in light. Either reads as "not the app";
  /// this one is the design's.
  static const Color webLetterbox = Color(0xFF6E759F);

  /// `scrim` — GC-1. The colour a modal scrim is laid over the page in.
  static const Color scrimLight = Color(0xFF0A0E27);
  static const Color scrimDark = Color(0xFF000000);

  /// `shadow` — GC-1. Independent of [scrimLight]/[scrimDark]: both happen to
  /// read `#000000` in dark, but a scrim takes the page out of reach and a
  /// shadow is cast by an object, so the two stay declared separately rather
  /// than aliased.
  static const Color shadowLight = Color(0xFF0F1638);
  static const Color shadowDark = Color(0xFF000000);
}
