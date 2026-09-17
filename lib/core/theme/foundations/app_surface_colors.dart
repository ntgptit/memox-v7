import 'package:flutter/material.dart';

import 'app_material_roles.dart';

/// Every surface the app paints, as one family.
///
/// **`page` is the v3 `surface` role's literal (`colors_and_type.css`,
/// 2026-09-17) — `ColorScheme.surface` reads it directly.** The other five
/// legacy names this file has kept since M100.32 (`paper`, `surfaceEmphasis`,
/// `surfaceSelected`, `surfaceMuted`, `surfaceElevated`) are call-site aliases
/// for a `ColorScheme` role: four derive from `AppMaterialRoles` below them,
/// and `surfaceEmphasis` is its own v3 formula because nothing in GC-1 names it.
abstract final class AppSurfaceColors {
  /// The page — the base ground `ColorScheme.surface` reads.
  static const Color pageLight = Color(0xFFF7F9FE);
  static const Color pageDark = Color(0xFF0A0E27);

  /// Card and sheet — `_CardDefaultsM3`/`_BottomSheetDefaultsM3` both bind
  /// `surfaceContainerLow`, so this is that role under the name every call site
  /// already uses.
  static const Color paperLight = AppMaterialRoles.surfaceContainerLowLight;
  static const Color paperDark = AppMaterialRoles.surfaceContainerLowDark;

  /// The callout surface `MxCard.tonal` fills with — v3 `surface-hero`:
  /// `primary` at 5% over `#FFFFFF` (light) / 12% over the page (dark). No
  /// `ColorScheme` role names this tint, so it stays a literal.
  static const Color surfaceEmphasisLight = Color(0xFFF6F7FE);
  static const Color surfaceEmphasisDark = Color(0xFF191F41);

  /// The fill a picked card wears under `MxCardSelectionTreatment.tint` — v3
  /// puts "selected, soft emphasis" on `primaryContainer`.
  static const Color surfaceSelectedLight =
      AppMaterialRoles.primaryContainerLight;
  static const Color surfaceSelectedDark =
      AppMaterialRoles.primaryContainerDark;

  /// Inset tile, chip, icon container — `surfaceContainer` under its call-site
  /// name.
  static const Color surfaceMutedLight = AppMaterialRoles.surfaceContainerLight;
  static const Color surfaceMutedDark = AppMaterialRoles.surfaceContainerDark;

  /// A raised or selected surface — `surfaceBright` under its call-site name.
  static const Color surfaceElevatedLight = AppMaterialRoles.surfaceBrightLight;
  static const Color surfaceElevatedDark = AppMaterialRoles.surfaceBrightDark;
}
