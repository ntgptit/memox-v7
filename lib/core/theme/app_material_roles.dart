import 'package:flutter/material.dart';

import 'app_colors.dart';

/// The `ColorScheme` roles memox declares only because Material asks for them.
///
/// **Split out of `AppColors` at M4.10ao, and along the line the class doc
/// already drew.** `AppColors` answers *what a colour means here* — a page, a
/// card's edge, an answer remembered. These answer *what Material will draw if
/// nobody says* — a Dialog's container, a Menu's ladder rung, the `on` pair of a
/// role the MVP does not use yet. Both are colour tokens and neither is the
/// other's business: the first set is edited when the product changes its mind,
/// the second when a Material component finally renders.
///
/// **Why every one is declared rather than generated.** `ColorScheme.fromSeed`
/// produces ~30 roles, and an audit found it had generated a neutral-grey
/// `surfaceContainer` ladder, a **pink** `tertiary`, and an `error` red
/// competing with `danger` — all in hue families this app never uses. None had
/// surfaced only because the MVP has no Dialog, BottomSheet, NavigationBar, Menu
/// or Chip. Leaving them generated meant those screens would render as a
/// different app on the day they were built.
///
/// `error` is absent on purpose: it is `AppColors.danger`, not a second red.
/// So are `primary`, `surface`, `outline`, `shadow` and `scrim` — each is a
/// memox decision that Material happens to have a slot for, and each stays in
/// `AppColors` where its reasoning is.
abstract final class AppMaterialRoles {
  static const Color primaryContainerLight = Color(0xFFDCDCF2);
  static const Color primaryContainerDark = Color(0xFF2B2B6E);
  static const Color onPrimaryContainerLight = Color(0xFF1B1B5C);

  /// `#D7D5FF` from the design system, replacing `#D8D8F0`. It reads the same on
  /// the container (8.87:1 against 8.96:1) and carries more of the seed's hue.
  static const Color onPrimaryContainerDark = Color(0xFFD7D5FF);

  static const Color secondaryLight = Color(0xFF4E5468);

  /// Moved with [secondaryContainerDark] at M4.10aa, and forced rather than
  /// chosen: `color_system_rules_test.dart` R3 holds a role's fill and its
  /// container within 5 degrees of hue, and taking the container to the page
  /// family while the fill stayed on the old slate opened 18. Same L\* (75.2),
  /// now 3.5 degrees off its container.
  static const Color secondaryDark = Color(0xFFB8B7D0);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1E2033);
  static const Color secondaryContainerLight = Color(0xFFE4E6EC);
  static const Color secondaryContainerDark = Color(0xFF332F58);
  static const Color onSecondaryContainerLight = Color(0xFF2C3141);
  static const Color onSecondaryContainerDark = Color(0xFFD9DCE7);

  static const Color tertiaryLight = Color(0xFF45647F);

  /// From the design system, replacing `#A2BAD0` — and it *is*
  /// `AppColors.infoDark`, stated as a derivation because it is deliberate:
  /// the tertiary role and the `info` semantic are the one blue the palette
  /// has, and a copied hex is a relationship the next edit can silently break.
  static const Color tertiaryDark = AppColors.infoDark;
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF17232E);
  static const Color tertiaryContainerLight = Color(0xFFE1E9F0);
  static const Color tertiaryContainerDark = Color(0xFF33465A);
  static const Color onTertiaryContainerLight = Color(0xFF22394B);
  static const Color onTertiaryContainerDark = Color(0xFFD5E0EA);

  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF2C1319);
  static const Color errorContainerLight = Color(0xFFF8DDE1);
  static const Color errorContainerDark = Color(0xFF5E2831);
  static const Color onErrorContainerLight = Color(0xFF641421);
  static const Color onErrorContainerDark = Color(0xFFF5D3D8);

  static const Color surfaceContainerLowestLight =
      AppColors.surfaceElevatedLight;

  /// The dark half of this ladder moved with the four main tiers at M4.10aa —
  /// `surfaceContainerHigh`, `Highest` and `Bright` **are**
  /// `AppColors.surfaceMuted`, [secondaryContainerDark] and
  /// `AppColors.surfaceElevated`, written as derivations because leaving them
  /// as copied hex would let the ladder split into two hue families at exactly
  /// the rungs a Dialog and a Menu draw from — the drift the derivation now
  /// makes impossible rather than merely checked-for.
  static const Color surfaceContainerLowestDark = Color(0xFF0A0326);
  static const Color surfaceContainerLowLight = Color(0xFFFAFAFC);
  static const Color surfaceContainerLowDark = Color(0xFF151134);
  // `onInverseSurfaceLight` is the same value from the other direction —
  // written there as the derivation, so this stays the source.
  static const Color surfaceContainerLight = Color(0xFFF1F2F6);
  static const Color surfaceContainerDark = Color(0xFF221E44);
  static const Color surfaceContainerHighLight = AppColors.surfaceMutedLight;
  static const Color surfaceContainerHighDark = AppColors.surfaceMutedDark;
  static const Color surfaceContainerHighestLight = Color(0xFFE3E5EC);
  static const Color surfaceContainerHighestDark = secondaryContainerDark;

  /// **`surfaceDim` is the dimmest surface, which in this app is the page.**
  ///
  /// Dark says so by deriving. It used to be `0xFF0B0327` — three parts in 255
  /// away from [AppColors.backgroundDark], near enough that nobody could see
  /// the difference and far enough that an edit to the page would have left it
  /// behind. A colour that exists twice under two names is a colour that will
  /// disagree with itself eventually.
  ///
  /// Light is deliberately *not* derived, and that is the open question rather
  /// than an oversight: `#DEE0E7` is **darker** than the light page, so the
  /// ladder there runs the other way and `surfaceDim` sits below a page that
  /// is not in the scheme at all. Straightening that is a surface-ladder
  /// change with pixels behind it, not a rename — see the token audit.
  static const Color surfaceDimLight = Color(0xFFDEE0E7);
  static const Color surfaceDimDark = AppColors.backgroundDark;
  static const Color surfaceBrightLight = AppColors.surfaceElevatedLight;
  static const Color surfaceBrightDark = AppColors.surfaceElevatedDark;

  static const Color inverseSurfaceLight = Color(0xFF2A2C3E);
  static const Color inverseSurfaceDark = Color(0xFFE7E8F0);
  static const Color onInverseSurfaceLight = surfaceContainerLight;
  static const Color onInverseSurfaceDark = Color(0xFF23253A);
  static const Color inversePrimaryLight = Color(0xFFA9A9E0);
  static const Color inversePrimaryDark = Color(0xFF3A3A9B);
}

/// The brand ink, in the shade this theme can actually print it — a selected
/// pill's label, the navigation bar's active tab, the hero's eyebrow.
///
/// **Not simply `primary`, and not simply `onPrimaryContainer`.** The owner's
/// mockup asks the active state and the eyebrow to read as the brand colour
/// (owner review, 2026-08-20), and in light they can: `primary` measures
/// 5.6:1 on `primaryContainer` and 8.0:1 on `surface`. In dark `primaryDark`
/// is deliberately held low — see [AppColors.primaryDark] — so the same ink
/// measures **2.13:1** on the container and **2.90:1** on the surface, and the
/// visual audit fails both. Dark therefore takes the M3 partner, which is the
/// same hue a few steps up and clears every floor on both grounds.
///
/// One function rather than a copy per call site: the pill, the tab and the
/// eyebrow have to agree about what "brand" looks like, and they did not when
/// each resolved its own.
Color brandInk(ColorScheme scheme) => scheme.brightness == Brightness.light
    ? scheme.primary
    : scheme.onPrimaryContainer;
