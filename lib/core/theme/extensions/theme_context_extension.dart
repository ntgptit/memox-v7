import 'package:flutter/material.dart';

import '../foundations/app_semantic_colors.dart';
import '../typography/app_text_styles.dart';

/// The only accessors widgets use to reach theme values.
///
/// Three names instead of `Theme.of(context).colorScheme` spelled out at every
/// call site. That matters less for brevity than for grep: a hardcoded colour
/// is easy to spot when every legitimate one reads `context.colors.*`.
extension ThemeContextX on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  /// The input hint at rest — what a placeholder composed *outside*
  /// `InputDecorator` wears (`InputDecoration.hint` with a `Text` child).
  ///
  /// `hintStyle` resolves per state since M100.36 (disabled dims it), so a
  /// caller handing its own widget to the decorator has to ask for one state.
  /// Published here rather than resolved in a feature: `WidgetStateProperty`
  /// is the design system's vocabulary, and the layering test refuses a
  /// feature that imports a component theme to reach it.
  TextStyle? get inputHintStyle => WidgetStateProperty.resolveAs(
    Theme.of(this).inputDecorationTheme.hintStyle,
    const <WidgetState>{},
  );

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

  /// The named styles `TextTheme` has no slot for — the card prompt and the
  /// section label. Throws when missing, for the same reason [semanticColors]
  /// does.
  AppTextStyles get textStyles {
    final styles = Theme.of(this).extension<AppTextStyles>();
    if (styles != null) return styles;

    throw FlutterError(
      'AppTextStyles is not registered on this Theme.\n'
      'Build themes with buildLightTheme() / buildDarkTheme(), which register '
      'it in ThemeData.extensions.',
    );
  }
}
