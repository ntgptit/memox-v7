import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_surface_colors.dart';

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
/// **Why almost every one is declared rather than generated.** The twelve
/// `*Fixed` roles at the foot of this class are the exception, and the block
/// above them says why the objection below does not reach them.
/// `ColorScheme.fromSeed`
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
      AppSurfaceColors.surfaceElevatedLight;

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
  static const Color surfaceContainerHighLight =
      AppSurfaceColors.surfaceMutedLight;
  static const Color surfaceContainerHighDark =
      AppSurfaceColors.surfaceMutedDark;
  static const Color surfaceContainerHighestLight = Color(0xFFE3E5EC);
  static const Color surfaceContainerHighestDark = secondaryContainerDark;

  /// **`surfaceDim` is the dimmest surface, which in this app is the page.**
  ///
  /// Dark says so by deriving. It used to be `0xFF0B0327` — three parts in 255
  /// away from [AppSurfaceColors.backgroundDark], near enough that nobody could see
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
  static const Color surfaceDimDark = AppSurfaceColors.backgroundDark;
  static const Color surfaceBrightLight = AppSurfaceColors.surfaceElevatedLight;
  static const Color surfaceBrightDark = AppSurfaceColors.surfaceElevatedDark;

  static const Color inverseSurfaceLight = Color(0xFF2A2C3E);
  static const Color inverseSurfaceDark = Color(0xFFE7E8F0);
  static const Color onInverseSurfaceLight = surfaceContainerLight;
  static const Color onInverseSurfaceDark = Color(0xFF23253A);
  static const Color inversePrimaryLight = Color(0xFFA9A9E0);
  static const Color inversePrimaryDark = Color(0xFF3A3A9B);

  // --- The `*Fixed` families -----------------------------------------------
  //
  // **One constant per role, with no `Light`/`Dark` suffix, and that is the
  // whole point.** M3 defines a `*Fixed` role as "a substitute for the
  // container that is the same colour for the dark and light themes"
  // (`ColorScheme.primaryFixed`, and `color_spec_2021.ts` states it as a tone
  // that does not read `s.isDark`). Every other token in this file comes in a
  // pair because its two halves are different decisions; these do not, so
  // giving them a pair would create a way to spell the invariant wrongly.
  // `color_scheme_roles_test.dart` asserts light and dark resolve equal, but
  // the naming is what makes that assertion hard to break.
  //
  // **These twelve are generated, and they are the only generated colours in
  // the app.** Everything else here is hand-tuned, and the file header explains
  // why: `fromSeed` once produced a pink `tertiary` and a grey surface ladder
  // on a navy app. That objection does not transfer. A `*Fixed` role has no
  // hand-tuned counterpart to drift from — it is defined *as* a tone of its
  // own family's palette, and the tones are fixed by the spec at 90 / 80 / 10
  // / 30. Choosing them by eye would be inventing a number the spec already
  // states.
  //
  // **Each palette is keyed on this app's own role colour, not on the seed.**
  // M3 derives `secondaryPalette` and `tertiaryPalette` from the seed by hue
  // rotation, which is exactly what produced the pink `tertiary`. Keying each
  // family on [secondaryLight] / [tertiaryLight] keeps the hues the app chose
  // — HSL 224-244, inside the navy/indigo band `_isInFamily` allows — while
  // taking the tones from the spec.
  //
  // **The cost, stated.** A generated tone carries the palette's full chroma,
  // and A2's hand-tuned containers deliberately carry less: `primaryFixedDim`
  // sits at chroma 0.247 where `primaryContainerLight` sits at 0.145. So these
  // read as more saturated than the containers beside them. That is accepted
  // rather than overlooked (owner decision, 2026-08-25) — the alternative was
  // hand-tuning them into the A2 chroma band, which would have put the app's
  // numbers back in front of the spec's for a role the spec fully determines.
  //
  // Nothing renders them today. They are declared so that the day something
  // does, it draws a tone of this app's palette rather than `primary` — which
  // is what an undeclared `*Fixed` resolves to (`ColorScheme.primaryFixed`
  // reads `_primaryFixed ?? primary`), a fill-level tone in a container-level
  // slot, and different in each brightness.
  //
  // Contrast, measured against what the spec's own `ContrastCurve` asks at
  // standard contrast — `on*Fixed` >= 7:1 and `on*FixedVariant` >= 4.5:1, each
  // on both `*Fixed` and `*FixedDim`. The tightest of the twelve pairings is
  // `onTertiaryFixedVariant` on `tertiaryFixedDim` at 5.45:1.

  /// Primary palette (keyed on [AppColors.primaryLight]) at tone 90.
  static const Color primaryFixed = Color(0xFFE1E0FF);

  /// The same palette at tone 80 — ten tones dimmer, which is the
  /// `toneDeltaPair` the spec pins between this and [primaryFixed].
  static const Color primaryFixedDim = Color(0xFFC0C1FF);

  /// Tone 10. 13.26:1 on [primaryFixed], 10.01:1 on [primaryFixedDim].
  static const Color onPrimaryFixed = Color(0xFF07006D);

  /// Tone 30 — the lower-emphasis ink. 7.30:1 and 5.51:1 on the same pair.
  static const Color onPrimaryFixedVariant = Color(0xFF3736A5);

  /// Secondary palette (keyed on [secondaryLight]) at tone 90.
  static const Color secondaryFixed = Color(0xFFDDE2FB);
  static const Color secondaryFixedDim = Color(0xFFC1C6DE);

  /// Tone 10. 13.34:1 on [secondaryFixed], 10.12:1 on [secondaryFixedDim].
  static const Color onSecondaryFixed = Color(0xFF151B2C);

  /// Tone 30. 7.30:1 and 5.54:1.
  static const Color onSecondaryFixedVariant = Color(0xFF404659);

  /// Tertiary palette (keyed on [tertiaryLight]) at tone 90.
  static const Color tertiaryFixed = Color(0xFFCBE5FF);
  static const Color tertiaryFixedDim = Color(0xFFAACAE9);

  /// Tone 10. 13.17:1 on [tertiaryFixed], 10.03:1 on [tertiaryFixedDim].
  static const Color onTertiaryFixed = Color(0xFF121D26);

  /// Tone 30, and the tightest pairing of the twelve: 7.16:1 on
  /// [tertiaryFixed] and 5.45:1 on [tertiaryFixedDim], against a 4.5 floor.
  static const Color onTertiaryFixedVariant = Color(0xFF2A4A64);
}

/// The ink of a control that is **selected** — a selected pill's label, the
/// navigation bar's active tab.
///
/// **Not simply `primary`, and not simply `onPrimaryContainer`.** The owner's
/// mockup asks the active state to read as the brand colour (owner review,
/// 2026-08-20), and in light it can: `primary` measures 5.57:1 on
/// `primaryContainer` and 6.89:1 on `background`. In dark `primaryDark` is
/// deliberately held low — see [AppColors.primaryDark] — so the same ink
/// measures **2.13:1** on the container, and the visual audit fails it. Dark
/// therefore takes the M3 partner, which is the same hue a few steps up and
/// clears every floor on both grounds: 8.87:1 and 13.68:1.
///
/// **Named for the question, not for the colour, because
/// `AppSemanticColors.primaryAccent` answers a different one and the two used
/// to collide.** That token is *the brand hue as a label on a surface* — a
/// link, an accent glyph on a card or a page. This one is *the ink of a
/// selected control*, whose ground is the selection's own tint. They agree in
/// light by construction (both resolve to `primary`) and part company in dark,
/// which is what made them look like two spellings of one idea.
///
/// **They are not, and merging them was measured rather than argued.**
/// `primaryAccent` in dark is the focus ring's brighter indigo, chosen to stay
/// recognisably *brand* on a page — and on a selected pill's
/// `primaryContainer` fill it measures **4.06:1**, under the 4.5 a 12px label
/// needs. Merging the other way is no better: `onPrimaryContainer` in light is
/// `#1B1B5C`, which reads as black text rather than as the brand. Each token
/// takes the value that is both legible on *its* ground and still the brand;
/// the grounds differ, so the values do. `app_selected_ink_test.dart` pins all
/// four numbers so a future merge has to fail a test rather than a review.
///
/// One function rather than a copy per call site: the pill and the tab have to
/// agree about what "selected" looks like, and they did not when each resolved
/// its own.
Color selectedInk(ColorScheme scheme) => scheme.brightness == Brightness.light
    ? scheme.primary
    : scheme.onPrimaryContainer;
