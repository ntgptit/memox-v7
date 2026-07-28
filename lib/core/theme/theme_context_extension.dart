import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';

/// The only accessors widgets use to reach theme values.
///
/// Three names instead of `Theme.of(context).colorScheme` spelled out at every
/// call site. That matters less for brevity than for grep: a hardcoded colour
/// is easy to spot when every legitimate one reads `context.colors.*`.
extension ThemeContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  /// Meanings `ColorScheme` has no slot for — success, danger, and friends.
  ///
  /// Throws if the extension is missing rather than returning a default. A
  /// silent fallback would render the wrong colour on a screen nobody
  /// re-checks; a missing extension is a wiring bug, and it should say so at
  /// the first build.
  AppSemanticColors get semanticColors {
    final semantic = Theme.of(this).extension<AppSemanticColors>();
    if (semantic != null) return semantic;

    throw FlutterError(
      'AppSemanticColors is not registered on this Theme.\n'
      'Build themes with buildLightTheme() / buildDarkTheme(), which register '
      'it in ThemeData.extensions.',
    );
  }
}
