import 'package:flutter/material.dart';

import '../foundations/app_border_colors.dart';
import '../foundations/app_colors.dart';
import '../foundations/app_material_roles.dart';
import '../foundations/app_surface_colors.dart';

/// The two `ColorScheme`s the app ships, and the only place either is built.
///
/// **Split out of `app_theme.dart` at M100.29.** That file was the composition
/// root *and* the scheme's source: 135 of its 635 lines were role-by-role
/// colour argument, so "which colour is `secondaryContainer`?" and "which
/// components does this app theme?" were the same file's business. They are not
/// the same decision and they change for different reasons — a palette move
/// (M100.25–28 moved every value in here and touched nothing below) against a
/// component gaining its first caller.
///
/// Nothing about the 45-role contract moved with it. What is passed, what is
/// refused and why are unchanged from M100.17; the guard rules that lock the
/// argument list are scoped to `lib/core/theme/**`, so they follow the code.

// The constructor, not `fromSeed(...).copyWith(...)`. Every role the app
// ships is a hand-tuned constant, and `fromSeed` had been generating a
// parallel set nobody rendered — a neutral-grey surfaceContainer ladder, a
// pink `tertiary`, a second red for `error` — which read as "there is a
// tonal palette" when there is none.
//
// **Exactly the 45 Material 3 colour roles are passed — no fewer, and
// nothing that is not one.** 26 standard roles (the `primary`, `secondary`,
// `tertiary` and `error` quartets; `surface`, `onSurface`,
// `onSurfaceVariant`; `outline` and `outlineVariant`; the `inverse*` trio;
// `shadow` and `scrim`) and 19 add-ons (`surfaceDim`, `surfaceBright`, the
// five `surfaceContainer*` rungs, and the twelve `*Fixed`). The `*Fixed`
// twelve arrived last (M99.47): until then each fell through the
// constructor's own fallback to its *base* role (`_primaryFixed ?? primary`)
// — a fill-level tone in a container-level slot, and a different value in
// each brightness for a role the spec defines as brightness-independent.
//
// The constructor accepts a few more names than that — three deprecated
// roles and one tint mechanism — and none is passed, read, dumped or
// swatched anywhere in this repository. The guard locks the names to the
// list above by allowlist rather than by naming what is out:
// `memox_v7.design_system.color_scheme_arguments_are_m3_roles` for what a
// `ColorScheme(` or a scheme's `copyWith(` may be handed, and
// `memox_v7.design_system.color_scheme_reads_are_m3_roles` for what may be
// read off one anywhere under `lib/` (M100.17).
const ColorScheme lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primaryLight,
  onPrimary: AppColors.onPrimaryLight,
  primaryContainer: AppMaterialRoles.primaryContainerLight,
  onPrimaryContainer: AppMaterialRoles.onPrimaryContainerLight,
  // The `*Fixed` family carries no brightness suffix because the role is
  // defined as the same colour in both themes; see `AppMaterialRoles`.
  primaryFixed: AppMaterialRoles.primaryFixed,
  primaryFixedDim: AppMaterialRoles.primaryFixedDim,
  onPrimaryFixed: AppMaterialRoles.onPrimaryFixed,
  onPrimaryFixedVariant: AppMaterialRoles.onPrimaryFixedVariant,
  secondary: AppMaterialRoles.secondaryLight,
  onSecondary: AppMaterialRoles.onSecondaryLight,
  secondaryContainer: AppMaterialRoles.secondaryContainerLight,
  onSecondaryContainer: AppMaterialRoles.onSecondaryContainerLight,
  secondaryFixed: AppMaterialRoles.secondaryFixed,
  secondaryFixedDim: AppMaterialRoles.secondaryFixedDim,
  onSecondaryFixed: AppMaterialRoles.onSecondaryFixed,
  onSecondaryFixedVariant: AppMaterialRoles.onSecondaryFixedVariant,
  tertiary: AppMaterialRoles.tertiaryLight,
  onTertiary: AppMaterialRoles.onTertiaryLight,
  tertiaryContainer: AppMaterialRoles.tertiaryContainerLight,
  onTertiaryContainer: AppMaterialRoles.onTertiaryContainerLight,
  tertiaryFixed: AppMaterialRoles.tertiaryFixed,
  tertiaryFixedDim: AppMaterialRoles.tertiaryFixedDim,
  onTertiaryFixed: AppMaterialRoles.onTertiaryFixed,
  onTertiaryFixedVariant: AppMaterialRoles.onTertiaryFixedVariant,
  // `error` is `danger`, not a second red system.
  error: AppColors.dangerLight,
  onError: AppMaterialRoles.onErrorLight,
  errorContainer: AppMaterialRoles.errorContainerLight,
  onErrorContainer: AppMaterialRoles.onErrorContainerLight,
  surface: AppSurfaceColors.pageLight,
  onSurface: AppColors.textPrimaryLight,
  onSurfaceVariant: AppColors.textSecondaryLight,
  surfaceDim: AppMaterialRoles.surfaceDimLight,
  surfaceBright: AppMaterialRoles.surfaceBrightLight,
  surfaceContainerLowest: AppMaterialRoles.surfaceContainerLowestLight,
  surfaceContainerLow: AppMaterialRoles.surfaceContainerLowLight,
  surfaceContainer: AppMaterialRoles.surfaceContainerLight,
  surfaceContainerHigh: AppMaterialRoles.surfaceContainerHighLight,
  surfaceContainerHighest: AppMaterialRoles.surfaceContainerHighestLight,
  // **The M3 pair, at last as a pair.** `outline` is the stroke the spec
  // asks to identify a component's boundary — the 3:1 of WCAG 1.4.11 — and
  // `outlineVariant` is the decorative hairline. Both used to be
  // `borderSubtle`, which handed any component that trusts `scheme.outline`
  // a 1.45:1 edge. The app's own widgets read the semantic tokens directly,
  // so this re-mapping changes what an *untended* widget degrades to, not
  // what the app draws.
  outline: AppBorderColors.borderControlLight,
  outlineVariant: AppBorderColors.borderSubtleLight,
  inverseSurface: AppMaterialRoles.inverseSurfaceLight,
  onInverseSurface: AppMaterialRoles.onInverseSurfaceLight,
  inversePrimary: AppMaterialRoles.inversePrimaryLight,
  shadow: AppColors.shadowLight,
  scrim: AppColors.scrimLight,
);

const ColorScheme darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.primaryDark,
  onPrimary: AppColors.onPrimaryDark,
  primaryContainer: AppMaterialRoles.primaryContainerDark,
  onPrimaryContainer: AppMaterialRoles.onPrimaryContainerDark,
  // The `*Fixed` family carries no brightness suffix because the role is
  // defined as the same colour in both themes; see `AppMaterialRoles`.
  primaryFixed: AppMaterialRoles.primaryFixed,
  primaryFixedDim: AppMaterialRoles.primaryFixedDim,
  onPrimaryFixed: AppMaterialRoles.onPrimaryFixed,
  onPrimaryFixedVariant: AppMaterialRoles.onPrimaryFixedVariant,
  secondary: AppMaterialRoles.secondaryDark,
  onSecondary: AppMaterialRoles.onSecondaryDark,
  secondaryContainer: AppMaterialRoles.secondaryContainerDark,
  onSecondaryContainer: AppMaterialRoles.onSecondaryContainerDark,
  secondaryFixed: AppMaterialRoles.secondaryFixed,
  secondaryFixedDim: AppMaterialRoles.secondaryFixedDim,
  onSecondaryFixed: AppMaterialRoles.onSecondaryFixed,
  onSecondaryFixedVariant: AppMaterialRoles.onSecondaryFixedVariant,
  tertiary: AppMaterialRoles.tertiaryDark,
  onTertiary: AppMaterialRoles.onTertiaryDark,
  tertiaryContainer: AppMaterialRoles.tertiaryContainerDark,
  onTertiaryContainer: AppMaterialRoles.onTertiaryContainerDark,
  tertiaryFixed: AppMaterialRoles.tertiaryFixed,
  tertiaryFixedDim: AppMaterialRoles.tertiaryFixedDim,
  onTertiaryFixed: AppMaterialRoles.onTertiaryFixed,
  onTertiaryFixedVariant: AppMaterialRoles.onTertiaryFixedVariant,
  error: AppColors.dangerDark,
  onError: AppMaterialRoles.onErrorDark,
  errorContainer: AppMaterialRoles.errorContainerDark,
  onErrorContainer: AppMaterialRoles.onErrorContainerDark,
  surface: AppSurfaceColors.pageDark,
  onSurface: AppColors.textPrimaryDark,
  onSurfaceVariant: AppColors.textSecondaryDark,
  surfaceDim: AppMaterialRoles.surfaceDimDark,
  surfaceBright: AppMaterialRoles.surfaceBrightDark,
  surfaceContainerLowest: AppMaterialRoles.surfaceContainerLowestDark,
  surfaceContainerLow: AppMaterialRoles.surfaceContainerLowDark,
  surfaceContainer: AppMaterialRoles.surfaceContainerDark,
  surfaceContainerHigh: AppMaterialRoles.surfaceContainerHighDark,
  surfaceContainerHighest: AppMaterialRoles.surfaceContainerHighestDark,
  // The same pair as light — see the note there.
  outline: AppBorderColors.borderControlDark,
  outlineVariant: AppBorderColors.borderSubtleDark,
  inverseSurface: AppMaterialRoles.inverseSurfaceDark,
  onInverseSurface: AppMaterialRoles.onInverseSurfaceDark,
  inversePrimary: AppMaterialRoles.inversePrimaryDark,
  shadow: AppColors.shadowDark,
  scrim: AppColors.scrimDark,
);
