import 'package:flutter/material.dart';

/// The `ColorScheme` roles memox declares only because Material asks for them.
///
/// **Values are literals from `design_system/MemoX Design System/colors_and_type.css`
/// (2026-09-17) — the v3 handoff (GC-1).** `AppColors` holds the six roles that
/// are a memox decision Material happens to have a slot for (`primary`,
/// `surface`, `onSurface`, `onSurfaceVariant`, `outline` via `AppBorderColors`,
/// `shadow`, `scrim`, `error` as `danger`); this file holds the rest of the 45
/// `ColorScheme` roles, plus the twelve brightness-invariant `*Fixed` roles.
/// Every constant here is independent — none derives from another role or from
/// a legacy token, so the table in GC-1 is the single source for each value.
abstract final class AppMaterialRoles {
  static const Color primaryContainerLight = Color(0xFFE0E5FE);
  static const Color primaryContainerDark = Color(0xFF2D346A);
  static const Color onPrimaryContainerLight = Color(0xFF1A2580);
  static const Color onPrimaryContainerDark = Color(0xFFD9DFFF);

  static const Color secondaryLight = Color(0xFF6E7CD9);
  static const Color secondaryDark = Color(0xFF9DA8E8);
  static const Color onSecondaryLight = Color(0xFFFFFFFF);
  static const Color onSecondaryDark = Color(0xFF1A2150);
  static const Color secondaryContainerLight = Color(0xFFE3E6F7);
  static const Color secondaryContainerDark = Color(0xFF343C78);
  static const Color onSecondaryContainerLight = Color(0xFF262E6E);
  static const Color onSecondaryContainerDark = Color(0xFFDDE2FB);

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

  // --- Surface ladder --------------------------------------------------------
  //
  // Five containers plus dim/bright, each a v3 literal. `AppSurfaceColors`'
  // legacy names (`paper`, `surfaceSelected`, `surfaceMuted`, `surfaceElevated`)
  // derive FROM these now — the role is the source, never the other way round.
  static const Color surfaceDimLight = Color(0xFFDAE0EF);
  static const Color surfaceDimDark = Color(0xFF060925);
  static const Color surfaceBrightLight = Color(0xFFFFFFFF);
  static const Color surfaceBrightDark = Color(0xFF232B5A);
  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestDark = Color(0xFF131A3A);
  static const Color surfaceContainerLowLight = Color(0xFFF1F4FB);
  static const Color surfaceContainerLowDark = Color(0xFF1B2249);
  static const Color surfaceContainerLight = Color(0xFFE9EDF7);
  static const Color surfaceContainerDark = Color(0xFF232B5A);
  static const Color surfaceContainerHighLight = Color(0xFFE2E7F3);
  static const Color surfaceContainerHighDark = Color(0xFF2C356E);
  static const Color surfaceContainerHighestLight = Color(0xFFDAE0EF);
  static const Color surfaceContainerHighestDark = Color(0xFF353D7E);

  /// Both brightnesses are the same v3 literal — see [onInverseSurfaceLight].
  static const Color inverseSurfaceLight = Color(0xFF34395D);
  static const Color inverseSurfaceDark = Color(0xFF34395D);

  /// Both brightnesses are the same v3 literal, unrelated to
  /// [surfaceContainerLight]'s value now — GC-1 gives `onInverseSurface` one
  /// figure for both modes rather than deriving it from the ladder.
  static const Color onInverseSurfaceLight = Color(0xFFE8EAFC);
  static const Color onInverseSurfaceDark = Color(0xFFE8EAFC);
  static const Color inversePrimaryLight = Color(0xFF8B9AFF);
  static const Color inversePrimaryDark = Color(0xFF5265F5);

  // --- The `*Fixed` families --------------------------------------------------
  //
  // Brightness-invariant by M3 definition, so one constant per role rather than
  // a Light/Dark pair. Literals from `colors_and_type.css` lines 128-141 (R2) —
  // no longer generated tones of primary/secondary/tertiary.
  static const Color primaryFixed = Color(0xFFE0E5FE);
  static const Color primaryFixedDim = Color(0xFFC2CBFD);
  static const Color onPrimaryFixed = Color(0xFF0B1252);
  static const Color onPrimaryFixedVariant = Color(0xFF2B3AB8);
  static const Color secondaryFixed = Color(0xFFE3E6F7);
  static const Color secondaryFixedDim = Color(0xFFC8CEF0);
  static const Color onSecondaryFixed = Color(0xFF131A4E);
  static const Color onSecondaryFixedVariant = Color(0xFF4453A8);
  static const Color tertiaryFixed = Color(0xFFEBE3FE);
  static const Color tertiaryFixedDim = Color(0xFFD7C8FD);
  static const Color onTertiaryFixed = Color(0xFF1D0A57);
  static const Color onTertiaryFixedVariant = Color(0xFF6A4AD4);
}
