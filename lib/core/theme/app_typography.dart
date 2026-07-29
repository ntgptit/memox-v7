import 'package:flutter/material.dart';

/// Typography tokens.
///
/// Two families, each doing the job it is good at:
///
/// * **Plus Jakarta Sans** for display and titles. Geometric with humanist
///   stroke endings, so a single vocabulary word set large reads as designed
///   rather than as default system text. This is the app's only visual
///   signature.
/// * **Inter** for body and UI. Drawn for screens — tall x-height, open
///   apertures, unambiguous `l`/`I`/`1` — which is what a definition read at
///   14sp on a phone actually needs.
///
/// Both are bundled (see `pubspec.yaml`) rather than fetched at runtime: a
/// study app must render identically offline, and `google_fonts` would add a
/// dependency and a first-run download for something that never changes.
///
/// Both are **variable** fonts. Google Fonts no longer ships static instances
/// for either family, and `fontWeight` alone does not reliably move a variable
/// font's `wght` axis across renderers — CanvasKit and Skia disagree. Weight is
/// therefore set through `fontVariations` as well, and `fontWeight` is kept in
/// step so that anything reading the style (a11y tooling, `copyWith` callers)
/// still sees the right value.
abstract final class AppTypography {
  static const String displayFamily = 'PlusJakartaSans';
  static const String bodyFamily = 'Inter';

  /// The front of a review card — the one place the app deliberately gets
  /// large, because that text is the task.
  static const double cardPromptSize = 30;

  /// The same prompt on a screen narrower than `AppBreakpoints.compact`. 30
  /// forces a two-word prompt onto three lines at 320 wide, which pushes the
  /// answer below the fold — the one thing the review screen must not do.
  static const double compactCardPromptSize = 26;

  /// Pairs a [FontWeight] with the matching variable-axis setting.
  static List<FontVariation> _wght(FontWeight weight) => <FontVariation>[
    FontVariation('wght', weight.value.toDouble()),
  ];

  static TextStyle _display(TextStyle? base, FontWeight weight) =>
      (base ?? const TextStyle()).copyWith(
        fontFamily: displayFamily,
        fontWeight: weight,
        fontVariations: _wght(weight),
      );

  static TextStyle _body(TextStyle? base, FontWeight weight) =>
      (base ?? const TextStyle()).copyWith(
        fontFamily: bodyFamily,
        fontWeight: weight,
        fontVariations: _wght(weight),
      );

  static TextTheme buildTextTheme(TextTheme base) {
    return base.copyWith(
      // --- Display: Plus Jakarta Sans ---
      displayLarge: _display(base.displayLarge, FontWeight.w700),
      displayMedium: _display(base.displayMedium, FontWeight.w700),
      displaySmall: _display(base.displaySmall, FontWeight.w600),
      headlineLarge: _display(base.headlineLarge, FontWeight.w600),
      // The card prompt. Tighter leading than Material's default: a long-ish
      // prompt otherwise wraps in a way that pushes the answer below the fold
      // inside the phone frame.
      headlineMedium: _display(
        base.headlineMedium,
        FontWeight.w600,
      ).copyWith(fontSize: cardPromptSize, height: 1.22, letterSpacing: -0.5),
      headlineSmall: _display(base.headlineSmall, FontWeight.w600),
      titleLarge: _display(base.titleLarge, FontWeight.w600),

      // --- UI and body: Inter ---
      titleMedium: _body(base.titleMedium, FontWeight.w600),
      titleSmall: _body(base.titleSmall, FontWeight.w600),
      bodyLarge: _body(base.bodyLarge, FontWeight.w400),
      // 1.45 keeps a two-line empty-state message readable without looking airy.
      bodyMedium: _body(
        base.bodyMedium,
        FontWeight.w400,
      ).copyWith(height: 1.45),
      bodySmall: _body(base.bodySmall, FontWeight.w400),
      labelLarge: _body(base.labelLarge, FontWeight.w600),
      labelMedium: _body(base.labelMedium, FontWeight.w500),
      labelSmall: _body(base.labelSmall, FontWeight.w500),
    );
  }
}
