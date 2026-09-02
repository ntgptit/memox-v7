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
  static const Color primaryContainerLight = Color(0xFFD9E2FE);
  static const Color primaryContainerDark = Color(0xFF2E2CC2);
  static const Color onPrimaryContainerLight = Color(0xFF2E2CC2);

  /// `#D7D5FF` from the design system, replacing `#D8D8F0`. It reads the same on
  /// the container (8.87:1 against 8.96:1) and carries more of the seed's hue.
  static const Color onPrimaryContainerDark = Color(0xFFD9E2FE);

  static const Color secondaryLight = Color(0xFF5C628B);

  /// Moved with [secondaryContainerDark] at M4.10aa, and forced rather than
  /// chosen: `color_system_rules_test.dart` R3 holds a role's fill and its
  /// container within 5 degrees of hue, and taking the container to the page
  /// family while the fill stayed on the old slate opened 18. Same L\* (75.2),
  /// now 3.5 degrees off its container.
  static const Color secondaryDark = Color(0xFFA3ABD8);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF292D52);

  /// Retuned from `#E4E6EC` at M100.22, and the component that forced it is
  /// the one that had been avoiding it.
  ///
  /// Three M3 slots take this role for their selected state — the navigation
  /// indicator, the choice chip and the segmented button — and all three had
  /// been re-pointed at `primaryContainer` instead, because at `#E4E6EC` an
  /// applied filter and an unapplied one were nearly the same rectangle on a
  /// light page. That was true and measured: 4.22 L\* of step against
  /// `surfaceContainer`, where the `primaryContainer` the owner approved gave
  /// 7.16.
  ///
  /// So the tone moves to where that step already was, in the *secondary*
  /// family rather than the primary one: L\* 91.30 → 88.19 against
  /// `primaryContainer`'s 88.36, and chroma 0.031 → 0.071 so it reads tinted
  /// rather than grey. Hue stays 226 — [secondaryLight]'s own — so the pair
  /// still passes `color_system_rules_test.dart` R3's five-degree band.
  ///
  /// | ground | was | now | `primaryContainer` gave |
  /// |---|---|---|---|
  /// | `surface` | 7.39 L\* | 10.50 | 10.34 |
  /// | page | 5.24 | 8.35 | 8.18 |
  /// | `surfaceContainer` | 4.22 | 7.33 | 7.16 |
  ///
  /// [onSecondaryContainerLight] reads 9.55:1 on it, down from 10.37 and still
  /// clear of AA by more than double.
  ///
  /// **Dark did not move, and that is the finding rather than an omission.**
  /// `#332F58` already gave 7.99 L\* against `surfaceContainer` where
  /// `primaryContainer` gave 7.71 — the substitution bought dark nothing. The
  /// owner's report said "on a light page", and the measurement agreed.
  static const Color secondaryContainerLight = Color(0xFFD4DBFF);
  static const Color secondaryContainerDark = Color(0xFF3F446B);
  static const Color onSecondaryContainerLight = Color(0xFF3F446B);
  static const Color onSecondaryContainerDark = Color(0xFFDBE1FF);

  static const Color tertiaryLight = Color(0xFF844981);

  /// From the design system, replacing `#A2BAD0` — and it *is*
  /// `AppColors.infoDark`, stated as a derivation because it is deliberate:
  /// the tertiary role and the `info` semantic are the one blue the palette
  /// has, and a copied hex is a relationship the next edit can silently break.
  static const Color tertiaryDark = Color(0xFFF3B1EE);
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF51194F);
  static const Color tertiaryContainerLight = Color(0xFFFED6FB);
  static const Color tertiaryContainerDark = Color(0xFF6A3167);
  static const Color onTertiaryContainerLight = Color(0xFF6A3167);
  static const Color onTertiaryContainerDark = Color(0xFFFED6FB);

  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF680114);
  static const Color errorContainerLight = Color(0xFFFFDAD8);
  static const Color errorContainerDark = Color(0xFF86001D);
  static const Color onErrorContainerLight = Color(0xFF86001D);
  static const Color onErrorContainerDark = Color(0xFFFFDAD8);

  static const Color surfaceContainerLowestLight =
      AppSurfaceColors.surfaceElevatedLight;

  /// The dark half of this ladder moved with the four main tiers at M4.10aa —
  /// `surfaceContainerHigh`, `Highest` and `Bright` **are**
  /// `AppColors.surfaceMuted`, [secondaryContainerDark] and
  /// `AppColors.surfaceElevated`, written as derivations because leaving them
  /// as copied hex would let the ladder split into two hue families at exactly
  /// the rungs a Dialog and a Menu draw from — the drift the derivation now
  /// makes impossible rather than merely checked-for.
  static const Color surfaceContainerLowestDark = Color(0xFF03041E);
  static const Color surfaceContainerLowLight = Color(0xFFF1F3FC);
  static const Color surfaceContainerLowDark = Color(0xFF131A3A);
  // `onInverseSurfaceLight` is the same value from the other direction —
  // written there as the derivation, so this stays the source.
  static const Color surfaceContainerLight = Color(0xFFEBEEF6);
  static const Color surfaceContainerDark = Color(0xFF1A203E);
  static const Color surfaceContainerHighLight =
      AppSurfaceColors.surfaceMutedLight;
  static const Color surfaceContainerHighDark =
      AppSurfaceColors.surfaceMutedDark;
  static const Color surfaceContainerHighestLight = Color(0xFFE0E2EB);
  static const Color surfaceContainerHighestDark = Color(0xFF374060);

  /// **`surfaceDim` is the dimmest surface, which in this app is the page.**
  ///
  /// Dark says so by deriving. It used to be `0xFF0B0327` — three parts in 255
  /// away from [AppSurfaceColors.backgroundDark], near enough that nobody could see
  /// the difference and far enough that an edit to the page would have left it
  /// behind. A colour that exists twice under two names is a colour that will
  /// disagree with itself eventually.
  ///
  /// Light is deliberately *not* derived, and that is no longer an open
  /// question. In M3 a light ladder **descends** — `surface` is tone 98 and the
  /// containers step down from it — so `surfaceDim` sitting below the page is
  /// the shape, not a gap. Since M100.26 the page is in the scheme
  /// (`background == surface`), which is the half of the old note that was
  /// actually wrong.
  static const Color surfaceDimLight = Color(0xFFD7DAE2);
  static const Color surfaceDimDark = AppSurfaceColors.backgroundDark;
  static const Color surfaceBrightLight = Color(0xFFF7F9FF);
  static const Color surfaceBrightDark = Color(0xFF3D4667);

  static const Color inverseSurfaceLight = Color(0xFF2E3037);
  static const Color inverseSurfaceDark = AppColors.textPrimaryDark;
  static const Color onInverseSurfaceLight = Color(0xFFEEF1F9);
  static const Color onInverseSurfaceDark = Color(0xFF272F4E);
  static const Color inversePrimaryLight = AppColors.primaryDark;
  static const Color inversePrimaryDark = AppColors.primaryLight;

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
  static const Color primaryFixed = Color(0xFFD9E2FE);

  /// The same palette at tone 80 — ten tones dimmer, which is the
  /// `toneDeltaPair` the spec pins between this and [primaryFixed].
  static const Color primaryFixedDim = Color(0xFFB8C5F2);

  /// Tone 10. 13.26:1 on [primaryFixed], 10.01:1 on [primaryFixedDim].
  static const Color onPrimaryFixed = Color(0xFF110168);

  /// Tone 30 — the lower-emphasis ink. 7.30:1 and 5.51:1 on the same pair.
  static const Color onPrimaryFixedVariant = Color(0xFF2E2CC2);

  /// Secondary palette (keyed on [secondaryLight]) at tone 90.
  static const Color secondaryFixed = Color(0xFFDBE1FF);
  static const Color secondaryFixedDim = Color(0xFFBCC4F2);

  /// Tone 10. 13.34:1 on [secondaryFixed], 10.12:1 on [secondaryFixedDim].
  static const Color onSecondaryFixed = Color(0xFF15183A);

  /// Tone 30. 7.30:1 and 5.54:1.
  static const Color onSecondaryFixedVariant = Color(0xFF3F446B);

  /// Tertiary palette (keyed on [tertiaryLight]) at tone 90.
  static const Color tertiaryFixed = Color(0xFFFED6FB);
  static const Color tertiaryFixedDim = Color(0xFFE2BADE);

  /// Tone 10. 13.17:1 on [tertiaryFixed], 10.03:1 on [tertiaryFixedDim].
  static const Color onTertiaryFixed = Color(0xFF380037);

  /// Tone 30, and the tightest pairing of the twelve: 7.16:1 on
  /// [tertiaryFixed] and 5.45:1 on [tertiaryFixedDim], against a 4.5 floor.
  static const Color onTertiaryFixedVariant = Color(0xFF6A3167);
}
