import 'package:flutter/material.dart';

/// Colour tokens.
///
/// Every name says what the colour *means*, never what it looks like. `danger`
/// survives a redesign that turns it amber; `red` becomes a lie the moment
/// someone changes it, and nobody renames a constant used in forty files.
///
/// The palette is Professional Learning Minimalism: a single restrained indigo
/// carries identity, and everything else is near-neutral so the card content is
/// the only thing competing for attention. Adults reviewing vocabulary between
/// meetings do not need a colourful interface; they need a quiet one.
///
/// Material 3 derives the bulk of the scheme from [seed]. Only the meanings
/// `ColorScheme` has no slot for are declared here, per brightness.
abstract final class AppColors {
  /// Source colour for both `ColorScheme.fromSeed` calls.
  static const Color seed = Color(0xFF4C5BD4);

  // --- Light ---

  /// Answer remembered, session completed, saved.
  static const Color successLight = Color(0xFF2E7D52);

  /// Card is due soon, streak at risk — informative, not alarming.
  static const Color warningLight = Color(0xFFB26A00);

  /// Answer forgotten, destructive action, reset.
  static const Color dangerLight = Color(0xFFB3261E);

  /// Neutral emphasis: hints, counters, "3 of 20".
  static const Color infoLight = Color(0xFF33618E);

  /// Behind a card, to separate it from the page without a border.
  static const Color surfaceMutedLight = Color(0xFFF4F3F8);

  /// Hairline between rows and around cards.
  static const Color borderSubtleLight = Color(0xFFDCDAE3);

  // --- Dark ---
  //
  // Not the light values darkened: on a dark surface a saturated colour reads
  // as brighter than the same colour on white, so each is lightened and
  // desaturated to keep contrast comparable without glowing.

  static const Color successDark = Color(0xFF7ED4A4);
  static const Color warningDark = Color(0xFFF2B857);
  static const Color dangerDark = Color(0xFFF2B8B5);
  static const Color infoDark = Color(0xFF9CCAFF);
  static const Color surfaceMutedDark = Color(0xFF1E1C22);
  static const Color borderSubtleDark = Color(0xFF48454E);
}
