import 'package:flutter/material.dart';

import 'app_material_roles.dart';

/// Every surface the app paints, under the names its call sites mean.
///
/// **Only the page is declared here** (M100.86). Every other surface is a role
/// of the Tokyo handoff's ladder in `AppMaterialRoles`, spelled under the
/// meaning a widget reaches for — so a retune moves one hex, and every meaning
/// that shares it follows rather than drifting into a second value.
///
/// The ladder is the handoff's: Tokyo Pure Light is a cool blue-tinted white
/// with the card pure white above the page, and Tokyo Nebula is a deep navy
/// whose surfaces climb in lightness from the page. `app_palette_test.dart`
/// holds the steps in L\*.
abstract final class AppSurfaceColors {
  /// The page — `ColorScheme.surface` and the scaffold behind every screen.
  static const Color pageLight = Color(0xFFF7F9FE);
  static const Color pageDark = Color(0xFF0A0E27);

  /// The paper: `MxCard`, a bare `Card`, the dropdown menu. The handoff's card
  /// is `surfaceContainerLowest` — see the ladder note in `AppMaterialRoles`.
  static const Color paperLight = AppMaterialRoles.surfaceContainerLowestLight;
  static const Color paperDark = AppMaterialRoles.surfaceContainerLowestDark;

  /// A callout panel (`MxCard.tonal`): the secondary container, tinted indigo,
  /// so an aside reads as an aside rather than as one more card.
  static const Color surfaceEmphasisLight =
      AppMaterialRoles.secondaryContainerLight;
  static const Color surfaceEmphasisDark =
      AppMaterialRoles.secondaryContainerDark;

  /// The fill a picked row or card wears. The handoff paints a selected chip
  /// and a selected row on `primaryContainer`.
  static const Color surfaceSelectedLight =
      AppMaterialRoles.primaryContainerLight;
  static const Color surfaceSelectedDark =
      AppMaterialRoles.primaryContainerDark;

  /// An inset tile, a resting chip, a segmented track — `surfaceContainer`.
  static const Color surfaceMutedLight = AppMaterialRoles.surfaceContainerLight;
  static const Color surfaceMutedDark = AppMaterialRoles.surfaceContainerDark;

  /// The top of the ladder — `surfaceBright`.
  static const Color surfaceElevatedLight = AppMaterialRoles.surfaceBrightLight;
  static const Color surfaceElevatedDark = AppMaterialRoles.surfaceBrightDark;
}
