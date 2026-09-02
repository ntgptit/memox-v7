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
///
/// **M100.26 finished what M100.25 started: the whole scheme is Tokyo's.** The
/// `tertiary` family follows Tokyo's `info` hue (its dark fill *is*
/// `AppColors.infoDark`, Tokyo's `#33C2FF`), the `error` family follows Tokyo's
/// `#FF1943`, and the surface-container ladder, `inverse*` pair and the
/// tertiary `*Fixed` roles are re-derived from the Tokyo surfaces and ink by
/// the same rule as before — tone and chroma kept, hue moved.
///
/// **The two accent families took Tokyo's hues at M100.25.** `primary` and
/// `secondary` come from the owner's tokyo-react-admin-dashboard palette —
/// `#5569FF` / `#6E759F` in its light theme, `#9EA4C1` for dark `secondary` —
/// with the fills at the first tone of each family that clears its ratios
/// (see `AppColors.primaryLight` and [secondaryLight]). Every container, `on*`
/// and `inverse*` role in those families keeps the tone and chroma it already
/// had and moves only its hue, so each pair's contrast and each container's
/// step off the surface ladder land within 0.1 L\* of where they were. The
/// `*Fixed` roles are regenerated from the new key colours, as their block
/// says they must be. `tertiary`, `error` and the surface ladder did not move:
/// Tokyo has no tertiary, its status colours sit outside the chroma budget
/// `app_palette_test.dart` holds, and the ladder is a depth decision (AD-14)
/// rather than a brand one.
abstract final class AppMaterialRoles {
  static const Color primaryContainerLight = Color(0xFFDADDF2);
  static const Color primaryContainerDark = Color(0xFF252C6F);
  static const Color onPrimaryContainerLight = Color(0xFF141D5D);

  /// The design system's `#D7D5FF` moved to the Tokyo hue at the same tone and
  /// chroma. It reads 8.87:1 on the container, exactly as before.
  static const Color onPrimaryContainerDark = Color(0xFFD2D6FF);

  /// Tokyo's `secondary.dark` — `darken(#6E759F, 0.2)` — rather than its
  /// `secondary.main`: white on `#6E759F` measures 4.46:1, four hundredths
  /// under AA for a label, and this is the first value of Tokyo's own family
  /// that clears it (6.32:1). Tone 40.6, where M3 asks for 40.
  static const Color secondaryLight = Color(0xFF585E7F);

  /// Tokyo's dark-theme `secondary`, taken as is. Tone 67.8 rather than M3's
  /// 80, and kept there for the reason AD-14 gives: the trigger to move a hex
  /// is a failing ratio, and none fails — [onSecondaryDark] reads 6.55:1 on it,
  /// it reads 6.93:1 on the card and 7.86:1 on the page, and
  /// `color_system_rules_test.dart` R3 holds at 0.07 degrees from its
  /// container.
  static const Color secondaryDark = Color(0xFF9EA4C1);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1C2033);

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
  /// **Dark did not move at M100.22, and that is the finding rather than an
  /// omission.** `#332F58` already gave 7.99 L\* against `surfaceContainer`
  /// where `primaryContainer` gave 7.71 — the substitution bought dark nothing.
  /// The owner's report said "on a light page", and the measurement agreed.
  ///
  /// M100.25 then moved the hue to Tokyo's secondary (HSL 229, from 226) at the
  /// same tone: the step against `surfaceContainer` is 7.26 L\* and
  /// [onSecondaryContainerLight] reads 9.51:1 on it.
  static const Color secondaryContainerLight = Color(0xFFDADDEB);

  /// **Dark moved at M100.25, and in moving it stopped being a surface rung.**
  /// Until then it was `#332F58` — the same hex as
  /// `AppSurfaceColors.surfaceEmphasisDark` — and [surfaceContainerHighestDark]
  /// derived the ladder's top rung from *this* constant. Tokyo's secondary sits
  /// at HSL 230 where the dark surface family sits at 246, so a container that
  /// stayed on the ladder could not pass R3 against its own fill. Same tone
  /// (21.9) and chroma, hue moved: 8.18 L\* above `surfaceContainer`, 7.24:1
  /// under `primary` as a focus ring, and the ladder now takes its rung from
  /// the surface token it was always equal to.
  static const Color secondaryContainerDark = Color(0xFF2A3259);
  static const Color onSecondaryContainerLight = Color(0xFF2E3141);
  static const Color onSecondaryContainerDark = Color(0xFFDADCE7);

  static const Color tertiaryLight = Color(0xFF3C6678);

  /// From the design system, replacing `#A2BAD0` — and it *is*
  /// `AppColors.infoDark`, stated as a derivation because it is deliberate:
  /// the tertiary role and the `info` semantic are the one blue the palette
  /// has, and a copied hex is a relationship the next edit can silently break.
  static const Color tertiaryDark = AppColors.infoDark;
  static const Color onTertiaryLight = Color(0xFFFFFFFF);
  static const Color onTertiaryDark = Color(0xFF13242B);
  static const Color tertiaryContainerLight = Color(0xFFE0EAEE);
  static const Color tertiaryContainerDark = Color(0xFF2B4854);
  static const Color onTertiaryContainerLight = Color(0xFF1C3A47);
  static const Color onTertiaryContainerDark = Color(0xFFD3E1E7);

  static const Color onErrorLight = Color(0xFFFFFFFF);
  static const Color onErrorDark = Color(0xFF2C1318);
  static const Color errorContainerLight = Color(0xFFF8DDE2);
  static const Color errorContainerDark = Color(0xFF5E2832);
  static const Color onErrorContainerLight = Color(0xFF641423);
  static const Color onErrorContainerDark = Color(0xFFF4D3D9);

  static const Color surfaceContainerLowestLight =
      AppSurfaceColors.surfaceElevatedLight;

  /// The dark half of this ladder moved with the four main tiers at M4.10aa —
  /// `surfaceContainerHigh`, `Highest` and `Bright` **are**
  /// `AppSurfaceColors.surfaceMuted`, `AppSurfaceColors.surfaceEmphasis` and
  /// `AppSurfaceColors.surfaceElevated`, written as derivations because leaving
  /// them as copied hex would let the ladder split into two hue families at
  /// exactly the rungs a Dialog and a Menu draw from — the drift the derivation
  /// now makes impossible rather than merely checked-for. `Highest` derived
  /// from [secondaryContainerDark] until M100.25, when that role left the
  /// surface family for Tokyo's hue; the rung itself did not move.
  static const Color surfaceContainerLowestDark = Color(0xFF010624);
  static const Color surfaceContainerLowLight = Color(0xFFF9FAFB);
  static const Color surfaceContainerLowDark = Color(0xFF0D1335);
  // `onInverseSurfaceLight` is the same value from the other direction —
  // written there as the derivation, so this stays the source.
  static const Color surfaceContainerLight = Color(0xFFF0F2F6);
  static const Color surfaceContainerDark = Color(0xFF1A2045);
  static const Color surfaceContainerHighLight =
      AppSurfaceColors.surfaceMutedLight;
  static const Color surfaceContainerHighDark =
      AppSurfaceColors.surfaceMutedDark;
  static const Color surfaceContainerHighestLight = Color(0xFFE2E5EB);
  static const Color surfaceContainerHighestDark =
      AppSurfaceColors.surfaceEmphasisDark;

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
  static const Color surfaceDimLight = Color(0xFFDDE0E6);
  static const Color surfaceDimDark = AppSurfaceColors.backgroundDark;
  static const Color surfaceBrightLight = AppSurfaceColors.surfaceElevatedLight;
  static const Color surfaceBrightDark = AppSurfaceColors.surfaceElevatedDark;

  static const Color inverseSurfaceLight = Color(0xFF252D3D);
  static const Color inverseSurfaceDark = Color(0xFFE6E9EF);
  static const Color onInverseSurfaceLight = surfaceContainerLight;
  static const Color onInverseSurfaceDark = Color(0xFF1D273A);

  /// The snackbar's action ink. 6.20:1 on [inverseSurfaceLight] and 7.59:1 on
  /// [inverseSurfaceDark], which is body-text AA in both.
  static const Color inversePrimaryLight = Color(0xFFA4ABE0);
  static const Color inversePrimaryDark = Color(0xFF333C9C);

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
  // — HSL 230-238, inside the navy/indigo band `_isInFamily` allows — while
  // taking the tones from the spec.
  //
  // **The cost, stated.** A generated tone carries the palette's full chroma,
  // and A2's hand-tuned containers deliberately carry less: `primaryFixedDim`
  // sits at chroma 0.263 where `primaryContainerLight` sits at 0.094. So these
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
  static const Color primaryFixed = Color(0xFFDFE0FF);

  /// The same palette at tone 80 — ten tones dimmer, which is the
  /// `toneDeltaPair` the spec pins between this and [primaryFixed].
  ///
  /// One hex with `AppColors.primaryDark` by construction — both are tone 80
  /// of the palette keyed on `primaryLight`, which is also how `fromSeed`
  /// relates the two. Kept as its own literal rather than derived, because a
  /// `*Fixed` role is defined by the spec's tone and must never follow a
  /// brightness-suffixed token.
  static const Color primaryFixedDim = Color(0xFFBCC2FF);

  /// Tone 10. 13.27:1 on [primaryFixed], 10.05:1 on [primaryFixedDim].
  static const Color onPrimaryFixed = Color(0xFF000B62);

  /// Tone 30 — the lower-emphasis ink. 7.24:1 and 5.48:1 on the same pair.
  static const Color onPrimaryFixedVariant = Color(0xFF2636B1);

  /// Secondary palette (keyed on [secondaryLight]) at tone 90.
  static const Color secondaryFixed = Color(0xFFDDE1FF);
  static const Color secondaryFixedDim = Color(0xFFBFC4EA);

  /// Tone 10. 13.33:1 on [secondaryFixed], 10.07:1 on [secondaryFixedDim].
  static const Color onSecondaryFixed = Color(0xFF131937);

  /// Tone 30. 7.24:1 and 5.47:1.
  static const Color onSecondaryFixedVariant = Color(0xFF3F4565);

  /// Tertiary palette (keyed on [tertiaryLight]) at tone 90.
  static const Color tertiaryFixed = Color(0xFFBEE9FE);
  static const Color tertiaryFixedDim = Color(0xFFA2CDE1);

  /// Tone 10. 13.17:1 on [tertiaryFixed], 10.03:1 on [tertiaryFixedDim].
  static const Color onTertiaryFixed = Color(0xFF001F2A);

  /// Tone 30, and the tightest pairing of the twelve: 7.16:1 on
  /// [tertiaryFixed] and 5.45:1 on [tertiaryFixedDim], against a 4.5 floor.
  static const Color onTertiaryFixedVariant = Color(0xFF204C5D);
}
