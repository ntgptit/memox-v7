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

  /// The CJK fallback faces, behind both primary families on every text style.
  ///
  /// Inter and Plus Jakarta Sans are Latin-only, so a card whose content is
  /// Korean, Japanese or Chinese would render as tofu boxes on any platform
  /// whose system font happens not to cover the script — the web build most of
  /// all. Naming these as `fontFamilyFallback` on each style means Flutter
  /// reaches for them only for the glyphs the primary lacks, so Latin UI text is
  /// untouched and the fallback carries the vocabulary. All three are variable
  /// fonts with a `wght` axis, so the same [_wght] setting drives their weight
  /// too — which is why they are subset but *not* instanced to a static weight:
  /// a static fallback would report the right weight and paint one weight, the
  /// exact failure [withWeight] exists to prevent.
  ///
  /// **The order is the contract, and only one part of it is arbitrary.** Korean
  /// is first because it is what the app is for. Japanese before Simplified
  /// Chinese decides the glyph *form* of the thousands of Han characters both
  /// cover: the same codepoint is drawn differently in the two regional
  /// conventions, the fallback chain takes the first face that has it, and there
  /// is no way to satisfy both from one list. Japanese wins because its script
  /// cannot be read at all without kanji, while Chinese in Japanese forms stays
  /// legible. `NotoSansKR` is deliberately in front of both despite carrying no
  /// Han at all — it costs nothing and keeps "Korean first" true by inspection.
  ///
  /// **Each face is subset, and what was dropped is a decision, not a default.**
  /// All three keep everyday text — kana, Hangul, the main CJK Unified block,
  /// CJK punctuation, halfwidth/fullwidth forms — and drop Extension A, the
  /// compatibility ideographs and everything beyond the BMP. Those are historical
  /// and specialist characters; carrying them costs megabytes a vocabulary deck
  /// will not spend.
  ///
  /// **Every family named here MUST also be loaded by
  /// `test/flutter_test_config.dart`.** `flutter test` does not populate declared
  /// fonts from the bundle, and a fallback naming a family the test collection
  /// lacks is silently skipped — which is how Korean rendered as `NO GLYPH` in
  /// every golden for months while a test asserting this very list stayed green.
  static const String cjkFallbackFamily = 'NotoSansKR';
  static const String japaneseFallbackFamily = 'NotoSansJP';
  static const String simplifiedChineseFallbackFamily = 'NotoSansSC';

  /// The fallback chain, in the order the renderer walks it.
  static const List<String> cjkFallback = <String>[
    cjkFallbackFamily,
    japaneseFallbackFamily,
    simplifiedChineseFallbackFamily,
  ];

  /// The front of a review card — the one place the app deliberately gets
  /// large, because that text is the task. The three metrics live here as the
  /// kit's `--text-card-prompt` values; the complete style is
  /// `AppTextStyles.cardPrompt`, not a `TextTheme` rung.
  static const double cardPromptSize = 30;
  static const double cardPromptHeight = 1.22;
  static const double cardPromptTracking = -0.5;

  /// The same prompt on a screen narrower than `AppBreakpoints.compact`. 30
  /// forces a two-word prompt onto three lines at 320 wide, which pushes the
  /// answer below the fold — the one thing the study screen must not do.
  static const double compactCardPromptSize = 26;

  /// Extra tracking on the uppercase label above a group of rows.
  ///
  /// Uppercase set at 11px closes up; the design tracks it 1.1px for that, and
  /// it is the one place in the app where a text style is adjusted per use.
  static const double sectionLabelTracking = 1.1;

  /// The hero numeral's line box, as a multiple of its own size.
  ///
  /// **Not a leading adjustment — a cap-height trim, and the number is
  /// derived** (owner review, 2026-08-25). `height: 1` already gives the
  /// numeral a line box exactly its font size, so there is no leading left to
  /// cut. What still sits above the digits is the font's own **ascent above
  /// cap height**: measured off the rendered golden, the ink of `15` is 23.7px
  /// tall inside a 32px box, all of the 8.3px slack sitting above it. That is
  /// why a card padded 16 all round reads as 24 at the top and 16 at the
  /// bottom.
  ///
  /// Flutter splits a `height` change evenly around the baseline, so trimming
  /// the box by twice the slack moves the ink up by exactly the slack:
  ///
  ///     1 - 2 * 8.3 / 32 = 0.481
  ///
  /// Measured back: 16.3px above the ink against 16 below the button. **It is
  /// pinned to Plus Jakarta Sans**, and it is the one place in the app where a
  /// glyph is positioned by a font metric rather than by the grid —
  /// [sectionLabelTracking] is the other kind of the same admission. A font
  /// swap moves the six `deck_list_*` goldens, which is the signal to measure
  /// it again rather than to regenerate and move on.
  static const double heroNumeralCapTrim = 0.481;

  /// The deck list's heading, which is tracked tighter than the rest.
  ///
  /// **0.06em at `label-md`'s 12px, which is 0.72** (owner review, 2026-08-25).
  /// The heading shares its row with the sort control and nothing else, and at
  /// [sectionLabelTracking] the two words spread wide enough to read as the
  /// heavier half of the pair — the opposite of the balance that row is for.
  /// A second constant rather than a moved one: every other section label in
  /// the app sits above a group of rows with no control beside it, and 1.1 is
  /// still right there.
  static const double listHeadingTracking = 0.72;

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
    fontFamilyFallback: cjkFallback,
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
    fontFamilyFallback: cjkFallback,
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
      // The Material 3 metric, restored: this rung carried the card prompt's
      // 30/1.22/−0.5 until the prompt moved to `AppTextStyles.cardPrompt`,
      // which meant any future widget reaching for `headlineMedium` *as a
      // rung* would have inherited a component's private metrics.
      headlineMedium: _display(
        base.headlineMedium,
        FontWeight.w400,
        size: 28,
        height: 36 / 28,
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
