import 'package:flutter/material.dart';

/// Colour tokens.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// The palette is Professional Learning Minimalism: one restrained violet-indigo
/// carries identity, everything else is near-neutral, and the card content is
/// the only thing competing for attention. Adults reviewing vocabulary between
/// meetings need a quiet interface, not a colourful one.
///
/// **Where the values come from.** The accent hues follow the Tailwind palette,
/// which is tuned so each step holds its contrast against both a white and a
/// near-black surface — the property that matters here, since every one of
/// these has to work in light and dark. The light/dark pairs are picked one
/// scale step apart rather than by darkening a single value, for the reason
/// under "Dark" below. Every pair is verified by
/// `test/core/theme/app_theme_test.dart`, which computes WCAG contrast rather
/// than trusting the source.
///
/// Material 3 derives the bulk of the scheme from [seed]; only the meanings
/// `ColorScheme` has no slot for are declared here, per brightness.
abstract final class AppColors {
  /// Source colour for both `ColorScheme.fromSeed` calls.
  ///
  /// Violet-indigo: blue enough to read as calm and focused, violet enough not
  /// to look like every other blue productivity app.
  static const Color seed = Color(0xFF5B5BD6);

  // --- Light ---

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF047857);

  /// Card due soon, streak at risk — informative, not alarming.
  static const Color warningLight = Color(0xFFB45309);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFBE123C);

  /// Neutral emphasis: hints, counters, "3 of 20".
  static const Color infoLight = Color(0xFF1D4ED8);

  /// Behind a card, to separate it from the page without a border.
  static const Color surfaceMutedLight = Color(0xFFF5F5FA);

  /// Hairline between rows and around cards.
  static const Color borderSubtleLight = Color(0xFFDDDCE8);

  // --- Dark ---
  //
  // Not the light values darkened. On a dark surface a saturated colour reads
  // as brighter than the same colour on white, so each is lightened and
  // desaturated instead — that keeps contrast comparable without the glow that
  // makes dark mode tiring to read.

  static const Color successDark = Color(0xFF34D399);
  static const Color warningDark = Color(0xFFFBBF24);
  static const Color dangerDark = Color(0xFFFB7185);
  static const Color infoDark = Color(0xFF7DA8FF);
  static const Color surfaceMutedDark = Color(0xFF17161C);
  static const Color borderSubtleDark = Color(0xFF3A3844);
}
