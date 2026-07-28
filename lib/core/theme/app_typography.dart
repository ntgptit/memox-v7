import 'package:flutter/material.dart';

/// Typography tokens.
///
/// Built from Material 3's `TextTheme` rather than a bespoke ramp, so the
/// framework's own components inherit the right styles instead of needing a
/// per-widget override. Only the roles UC-05 renders are tuned.
///
/// No font family is set: the platform default is what a user's accessibility
/// settings and language already work with, and bundling a face costs app size
/// for a study tool where the content, not the wordmark, is what people read.
///
/// Nothing here fixes a text height in logical pixels — every size must survive
/// a 2.0 text scale, which `test/core/theme/` asserts against the components.
abstract final class AppTypography {
  /// Screen titles and the front of a review card — the one place the app
  /// deliberately gets large, because that text is the task.
  static const double cardPromptSize = 28;

  static TextTheme buildTextTheme(TextTheme base) {
    return base.copyWith(
      // Slightly tighter than Material's default: long-ish prompts in a phone
      // frame otherwise wrap in a way that shifts the answer below the fold.
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: cardPromptSize,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      // Body is what empty and error states use; 1.45 keeps two-line messages
      // readable without looking airy.
      bodyMedium: base.bodyMedium?.copyWith(height: 1.45),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
