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

  /// The CJK fallback face, behind both primary families on every text style.
  ///
  /// Inter and Plus Jakarta Sans are Latin-only, so a card whose content is
  /// Korean (or Japanese/Chinese) would render as tofu boxes on any platform
  /// whose system font happens not to cover the script — the web build most of
  /// all. Naming this as `fontFamilyFallback` on each style means Flutter reaches
  /// for it only for the glyphs the primary lacks, so Latin UI text is untouched
  /// and the fallback carries the vocabulary. It is a variable font with a `wght`
  /// axis, so the same [_wght] setting drives its weight too.
  static const String cjkFallbackFamily = 'NotoSansKR';
  static const List<String> _cjkFallback = <String>[cjkFallbackFamily];

  /// The front of a review card — the one place the app deliberately gets
  /// large, because that text is the task.
  static const double cardPromptSize = 30;

  /// The same prompt on a screen narrower than `AppBreakpoints.compact`. 30
  /// forces a two-word prompt onto three lines at 320 wide, which pushes the
  /// answer below the fold — the one thing the review screen must not do.
  static const double compactCardPromptSize = 26;

  /// Extra tracking on the uppercase label above a group of rows.
  ///
  /// Uppercase set at 11px closes up; the design tracks it 1.1px for that, and
  /// it is the one place in the app where a text style is adjusted per use.
  static const double sectionLabelTracking = 1.1;

  /// Pairs a [FontWeight] with the matching variable-axis setting.
  static List<FontVariation> _wght(FontWeight weight) => <FontVariation>[
    FontVariation('wght', weight.value.toDouble()),
  ];

  /// The same rung of the scale, set in a different weight.
  ///
  /// **`copyWith(fontWeight:)` alone is a silent no-op here.** Both faces are
  /// variable fonts and every rung carries a `wght` axis, which the renderer
  /// consults *instead of* [TextStyle.fontWeight] once it is present — so a
  /// style re-weighted by `fontWeight` alone reports the new weight to every
  /// test and paints the old one on the device. That is the same class of bug
  /// `component_theme_typography_test.dart` was opened for, arriving from the
  /// opposite direction.
  ///
  /// Deliberately not a general "restyle" helper: size, leading and tracking
  /// belong to the rung, and a component that needs different ones needs a
  /// different rung rather than a local edit.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(fontWeight: weight, fontVariations: _wght(weight));

  /// One rung of the scale, in the display face.
  ///
  /// **[size], [height] and [tracking] are stated, never inherited.** Every
  /// value here also exists in `design_system/tokens/typography.css`, which is
  /// authoritative for token values since M4.10p — and until now this file
  /// declared none of them. The two agreed because Material 3's own defaults
  /// happen to equal the design's, which is a coincidence with a maintenance
  /// bill: an SDK bump would have moved the whole app's type scale with no line
  /// of code changing and no test noticing. `app_typography_test.dart` is what
  /// notices now.
  ///
  /// [height] is the multiplier Flutter wants; the call sites write it as
  /// `leading / size` so the leading the design states stays readable.
  static TextStyle _display(
    TextStyle? base,
    FontWeight weight, {
    required double size,
    required double height,
    double tracking = 0,
  }) => (base ?? const TextStyle()).copyWith(
    fontFamily: displayFamily,
    fontFamilyFallback: _cjkFallback,
    fontWeight: weight,
    fontVariations: _wght(weight),
    fontSize: size,
    height: height,
    letterSpacing: tracking,
  );

  /// One rung of the scale, in the body face. See [_display].
  static TextStyle _body(
    TextStyle? base,
    FontWeight weight, {
    required double size,
    required double height,
    double tracking = 0,
  }) => (base ?? const TextStyle()).copyWith(
    fontFamily: bodyFamily,
    fontFamilyFallback: _cjkFallback,
    fontWeight: weight,
    fontVariations: _wght(weight),
    fontSize: size,
    height: height,
    letterSpacing: tracking,
  );

  static TextTheme buildTextTheme(TextTheme base) {
    return base.copyWith(
      // --- Display: Plus Jakarta Sans ---
      displayLarge: _display(
        base.displayLarge,
        FontWeight.w700,
        size: 57,
        height: 64 / 57,
      ),
      displayMedium: _display(
        base.displayMedium,
        FontWeight.w700,
        size: 45,
        height: 52 / 45,
      ),
      displaySmall: _display(
        base.displaySmall,
        FontWeight.w600,
        size: 36,
        height: 44 / 36,
      ),
      headlineLarge: _display(
        base.headlineLarge,
        FontWeight.w600,
        size: 32,
        height: 40 / 32,
      ),
      // The card prompt. Tighter leading than Material's default: a long-ish
      // prompt otherwise wraps in a way that pushes the answer below the fold
      // inside the phone frame.
      headlineMedium: _display(
        base.headlineMedium,
        FontWeight.w600,
        size: cardPromptSize,
        height: 1.22,
        tracking: -0.5,
      ),
      headlineSmall: _display(
        base.headlineSmall,
        FontWeight.w600,
        size: 24,
        height: 32 / 24,
      ),
      titleLarge: _display(
        base.titleLarge,
        FontWeight.w600,
        size: 22,
        height: 28 / 22,
      ),

      // --- UI and body: Inter ---
      titleMedium: _body(
        base.titleMedium,
        FontWeight.w600,
        size: 16,
        height: 24 / 16,
        tracking: 0.15,
      ),
      titleSmall: _body(
        base.titleSmall,
        FontWeight.w600,
        size: 14,
        height: 20 / 14,
        tracking: 0.1,
      ),
      bodyLarge: _body(
        base.bodyLarge,
        FontWeight.w400,
        size: 16,
        height: 24 / 16,
        tracking: 0.5,
      ),
      // 1.45 keeps a two-line empty-state message readable without looking airy.
      bodyMedium: _body(
        base.bodyMedium,
        FontWeight.w400,
        size: 14,
        height: 1.45,
        tracking: 0.25,
      ),
      bodySmall: _body(
        base.bodySmall,
        FontWeight.w400,
        size: 12,
        height: 16 / 12,
        tracking: 0.4,
      ),
      labelLarge: _body(
        base.labelLarge,
        FontWeight.w600,
        size: 14,
        height: 20 / 14,
        tracking: 0.1,
      ),
      labelMedium: _body(
        base.labelMedium,
        FontWeight.w500,
        size: 12,
        height: 16 / 12,
        tracking: 0.5,
      ),
      labelSmall: _body(
        base.labelSmall,
        FontWeight.w500,
        size: 11,
        height: 16 / 11,
        tracking: 0.5,
      ),
    );
  }
}
