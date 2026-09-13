import 'package:flutter/material.dart';

/// The `ColorScheme` roles memox declares only because Material asks for them.
///
/// **Every value here is the Tokyo handoff's, verbatim** (M100.86). The handoff
/// (`memox-flutter-handoff.json`, generated 2026-09-13 from
/// `ui_kits/mobile/flutter-prompt.html`) names 33 of the 45 roles in both
/// themes. This file holds the ones `AppColors`, `AppBorderColors` and
/// `AppSurfaceColors` do not own, plus the twelve `*Fixed` roles the handoff
/// leaves out.
///
/// **A hex here is never retuned for contrast.** Where a role fails a ratio as
/// *text*, the answer is a separate ink in `AppColors`, not a moved hex — the
/// owner's decision of 2026-09-13 (`v1-freeze.md` §3c). A role is what the kit
/// draws as a fill, a surface or a hairline. Two pairs are recorded below
/// because they fail as labels and nothing uses them that way yet.
///
/// **Declared, never generated**, apart from the `*Fixed` block. `fromSeed`
/// once produced a pink `tertiary` and a grey surface ladder on a navy app, and
/// every role left to it is a role nobody chose.
abstract final class AppMaterialRoles {
  static const Color primaryContainerLight = Color(0xFFE0E5FE);
  static const Color primaryContainerDark = Color(0xFF2D346A);
  static const Color onPrimaryContainerLight = Color(0xFF1A2580);
  static const Color onPrimaryContainerDark = Color(0xFFD9DFFF);

  /// The muted brand. **White on it is 3.79:1 in light**, under the 4.5 a label
  /// needs — no control fills with `secondary` today; one that does needs an
  /// ink rather than a retuned hex.
  static const Color secondaryLight = Color(0xFF6E7CD9);
  static const Color secondaryDark = Color(0xFF9DA8E8);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1A2150);
  static const Color secondaryContainerLight = Color(0xFFE3E6F7);
  static const Color secondaryContainerDark = Color(0xFF343C78);
  static const Color onSecondaryContainerLight = Color(0xFF262E6E);
  static const Color onSecondaryContainerDark = Color(0xFFDDE2FB);

  /// The violet signature accent. **White on it is 3.69:1 in light**, recorded
  /// for the reason [secondaryLight] is.
  static const Color tertiaryLight = Color(0xFF8B6FF5);
  static const Color tertiaryDark = Color(0xFFB5A0FF);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF240B63);
  static const Color tertiaryContainerLight = Color(0xFFEBE3FE);
  static const Color tertiaryContainerDark = Color(0xFF443078);
  static const Color onTertiaryContainerLight = Color(0xFF33177E);
  static const Color onTertiaryContainerDark = Color(0xFFE6DCFF);

  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF52061B);
  static const Color errorContainerLight = Color(0xFFFBDDE3);
  static const Color errorContainerDark = Color(0xFF7A2036);
  static const Color onErrorContainerLight = Color(0xFF7A0A23);
  static const Color onErrorContainerDark = Color(0xFFFFD9DF);

  // --- The surface ladder -------------------------------------------------
  //
  // **The paper is `surfaceContainerLowest`, not `Low`.** The handoff draws its
  // card on the lowest rung: in light that is pure white *above* a tinted page
  // (`surface`, `#F7F9FE`), and `Low` and every rung after it sit *below* the
  // page. In dark the ladder climbs from the page in L\*:
  // 4.7 → 10.4 → 14.7 → 19.3 → 24.4 → 28.4. M3's `_CardDefaultsM3` names `Low`;
  // the kit outranks it here (owner decision, 2026-09-13), so the card theme,
  // `MxCard` and every other paper read `Lowest`.
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestDark = Color(0xFF131A3A);

  /// The input fill and the kit's sheet ground.
  static const Color surfaceContainerLowLight = Color(0xFFF1F4FB);
  static const Color surfaceContainerLowDark = Color(0xFF1B2249);

  /// A resting chip, an inset tile, a segmented track.
  static const Color surfaceContainerLight = Color(0xFFE9EDF7);
  static const Color surfaceContainerDark = Color(0xFF232B5A);

  /// A dialog and a bottom sheet.
  static const Color surfaceContainerHighLight = Color(0xFFE2E7F3);
  static const Color surfaceContainerHighDark = Color(0xFF2C356E);

  /// An inactive switch or slider track.
  static const Color surfaceContainerHighestLight = Color(0xFFDAE0EF);
  static const Color surfaceContainerHighestDark = Color(0xFF353D7E);

  /// Light's `surfaceDim` is the same value as its `Highest` rung, and dark's
  /// sits below the page — both are the handoff's own figures.
  static const Color surfaceDimLight = Color(0xFFDAE0EF);
  static const Color surfaceDimDark = Color(0xFF060925);

  /// Dark's `surfaceBright` is one hex with `surfaceContainerDark`: the kit's
  /// brightest dark surface is its middle rung, not a sixth one.
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceBrightDark = Color(0xFF232B5A);

  /// **The snackbar slate does not flip with the theme** — one value in both
  /// modes, by the handoff's design.
  static const Color inverseSurfaceLight = Color(0xFF34395D);
  static const Color inverseSurfaceDark = Color(0xFF34395D);
  static const Color onInverseSurfaceLight = Color(0xFFE8EAFC);
  static const Color onInverseSurfaceDark = Color(0xFFE8EAFC);

  /// The action inside a snackbar, as a *role*. It reads 4.32:1 on the slate
  /// in light and 2.40:1 in dark, so the snackbar's action label takes
  /// `AppColors.inversePrimaryInk*` instead.
  static const Color inversePrimaryLight = Color(0xFF8B9AFF);
  static const Color inversePrimaryDark = Color(0xFF5265F5);

  // --- The `*Fixed` families ------------------------------------------------
  //
  // **One constant per role, with no `Light`/`Dark` suffix.** M3 defines a
  // `*Fixed` role as the same colour in both themes, and
  // `color_scheme_roles_test.dart` holds light and dark equal.
  //
  // **Generated, because the handoff does not name them.** Each family is a
  // `TonalPalette` keyed on the handoff's own role — `primary` `#5265F5`,
  // `secondary` `#6E7CD9`, `tertiary` `#8B6FF5` — read at the spec's tones with
  // `material_color_utilities`, the SDK's own generator: 90 / 80 for the fills,
  // 10 / 30 for the inks. Nothing renders them today; they are declared so an
  // untended widget draws this palette's tone rather than falling back to the
  // base role (`_primaryFixed ?? primary`).

  /// Primary palette at tone 90.
  static const Color primaryFixed = Color(0xFFDFE0FF);

  /// Primary palette at tone 80.
  static const Color primaryFixedDim = Color(0xFFBCC2FF);

  /// Primary palette at tone 10.
  static const Color onPrimaryFixed = Color(0xFF000B62);

  /// Primary palette at tone 30.
  static const Color onPrimaryFixedVariant = Color(0xFF182EC6);

  /// Secondary palette at tone 90 — one hex with [primaryFixed], because the
  /// two keys share a hue and differ only in chroma.
  static const Color secondaryFixed = Color(0xFFDFE0FF);
  static const Color secondaryFixedDim = Color(0xFFBBC3FF);
  static const Color onSecondaryFixed = Color(0xFF000E5E);
  static const Color onSecondaryFixedVariant = Color(0xFF2F3D97);

  /// Tertiary palette at tone 90.
  static const Color tertiaryFixed = Color(0xFFE7DEFF);
  static const Color tertiaryFixedDim = Color(0xFFCBBEFF);
  static const Color onTertiaryFixed = Color(0xFF1E0060);
  static const Color onTertiaryFixedVariant = Color(0xFF4B28B2);
}
