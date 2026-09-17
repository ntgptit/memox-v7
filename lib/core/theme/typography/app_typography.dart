import 'package:flutter/material.dart';

/// Typography tokens — the v3 foundations' seven type roles, in one face.
///
/// **One family, Plus Jakarta Sans.** The v3 palette gives every role — stat
/// figures, titles, body and captions — the same face. Inter, which used to
/// carry the IPA pronunciation glyphs, has left the bundle (Task 5b); IPA and
/// every script beyond Hangul now come from the platform fallback, proven on
/// a device by `IT-PLAT-009`.
///
/// The seven roles (`colors_and_type.css`'s `--memox-fs-*` / `-fw-*` / `-ls-*`
/// / `-lh-*` tokens; GC-4, 2026-09-17):
///
///     role        size  weight  leading  tracking
///     caption     12    600     1.4      +1.2
///     body        14    400     1.5      0
///     body large  16    500     1.5      0
///     title       20    700     1.2      -0.64
///     headline    24    700     1.2      -0.64
///     display     32    800     1.1      -0.64
///     stat        40    600     1.0      -0.64
///
/// Material 3 has fifteen `TextTheme` slots for those seven roles; which slot
/// wears which role is GC-4's own table, pinned by hand in
/// `app_typography_test.dart` so a retune has to come past it on purpose.
///
/// Bundled (see `pubspec.yaml`) rather than fetched at runtime: a study app
/// must render identically offline, and `google_fonts` would add a dependency
/// and a first-run download for something that never changes.
///
/// A **variable** font. `fontWeight` alone does not reliably move a variable
/// font's `wght` axis across renderers — CanvasKit and Skia disagree. Weight is
/// therefore set through `fontVariations` as well, and `fontWeight` is kept in
/// step so that anything reading the style (a11y tooling, `copyWith` callers)
/// still sees the right value.
abstract final class AppTypography {
  /// The one face.
  static const String family = 'PlusJakartaSans';

  /// The CJK fallback face, behind the primary family on every text style.
  ///
  /// Plus Jakarta Sans is Latin-only, so a card whose content is Korean would
  /// render as tofu boxes on any platform whose system font happens not to
  /// cover Hangul — the web build most of all. Naming the face as
  /// `fontFamilyFallback` on each style means Flutter reaches for it only for
  /// the glyphs the primary lacks, so Latin UI text is untouched and the
  /// fallback carries the vocabulary. It is a variable font with a `wght` axis,
  /// so the same [_wght] setting drives its weight too — which is why it is
  /// subset but *not* instanced to a static weight: a static fallback would
  /// report the right weight and paint another, the exact failure [withWeight]
  /// exists to prevent.
  ///
  /// **One face, and the two that left were measured out, not trimmed.** The
  /// chain used to be Korean, then Japanese, then Simplified Chinese, and those
  /// three files deflated to 14.4 MB — more of the download than the rest of
  /// the app. They were there to cover kana and Han. Android is the only
  /// release target and has shipped `NotoSansCJK-Regular.ttc` since Lollipop,
  /// so every phone was carrying those characters twice. `IT-PLAT-009` renders
  /// all four scripts on a real device behind an *empty* fallback and reads the
  /// raster back, against a private-use control so tofu cannot pass as a glyph.
  ///
  /// **Korean stays because it is what the app is for.** The card prompt is set
  /// at 30 and Hangul is the text it exists to show; leaving the app's largest
  /// type to whatever face a ROM installed would let it wrap differently from
  /// one device to the next, and the system's Noto Sans CJK KR is a different
  /// design from this file with different metrics.
  ///
  /// **The long tail reads better for having left.** Kana, Han, and the 8,229
  /// simplified characters no bundled face ever carried now come from the
  /// platform, in the reader's own regional form. The chain this replaces put
  /// Japanese in front of Simplified Chinese, which drew 12,747 Chinese
  /// characters in Japanese forms for every reader — not a bug, but the best a
  /// fixed list can do, because it cannot know which convention a card belongs
  /// to and the platform can.
  ///
  /// **The face is subset, and what was dropped is a decision, not a default.**
  /// It keeps the Hangul syllables, the compatibility jamo, CJK punctuation and
  /// the halfwidth/fullwidth forms, and carries no Han at all.
  ///
  /// **Every family named here MUST also be loaded by
  /// `test/flutter_test_config.dart`.** `flutter test` does not populate declared
  /// fonts from the bundle, and a fallback naming a family the test collection
  /// lacks is silently skipped — which is how Korean rendered as `NO GLYPH` in
  /// every golden for months while a test asserting this very list stayed green.
  static const String cjkFallbackFamily = 'NotoSansKR';

  /// The fallback chain. One entry, and still a list because that is the shape
  /// a `TextStyle` takes — and because the platform supplies the rest of it.
  static const List<String> cjkFallback = <String>[cjkFallbackFamily];

  // --- GC-4's sizes and leadings, named once -------------------------------

  static const double captionSize = 12;
  static const double bodySize = 14;
  static const double bodyLargeSize = 16;
  static const double titleSize = 20;
  static const double headlineSize = 24;
  static const double displaySize = 32;
  static const double statSize = 40;

  static const double captionHeight = 1.4;
  static const double bodyHeight = 1.5;
  static const double headingHeight = 1.2;
  static const double displayHeight = 1.1;
  static const double statHeight = 1.0;

  // --- Tracking -------------------------------------------------------------

  /// `--memox-ls-heading` — title, headline, display and stat.
  static const double headingTracking = -0.64;

  /// `--memox-ls-label` — the tracking a 12px label carries.
  static const double labelTracking = 0.72;

  /// The front of a review card — the one place the app deliberately gets
  /// large, because that text is the task. The three metrics live here as the
  /// kit's `--text-card-prompt` values; the complete style is
  /// `AppTextStyles.cardPrompt`, not a `TextTheme` rung. Component metrics, so
  /// GC-4's roles do not move them (R6).
  static const double cardPromptSize = 30;
  static const double cardPromptHeight = 1.22;
  static const double cardPromptTracking = -0.5;

  /// The same prompt on a screen narrower than `AppBreakpoints.compact`. 30
  /// forces a two-word prompt onto three lines at 320 wide, which pushes the
  /// answer below the fold — the one thing the study screen must not do.
  static const double compactCardPromptSize = 26;

  /// `--memox-ls-section` — the uppercase overline above a group of rows.
  ///
  /// Uppercase set small closes up; the tokens track it 1.2px for that, and it
  /// is the one place in the app where a text style is opened up per use.
  static const double sectionLabelTracking = 1.2;

  /// The card tile's state chip: tighter than a section label because the word
  /// sits inside a pill, not over a list.
  static const double stateChipTracking = 0.6;

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
  /// **A ratio of the em, so it carries to the stat size unchanged**: the
  /// numeral now sits on the stat role (40, R6) rather than the 32 it was
  /// measured on, and ascent and cap height scale with the em together. It is
  /// pinned to Plus Jakarta Sans, and it is the one place in the app where a
  /// glyph is positioned by a font metric rather than by the grid — a font
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
  /// the app sits above a group of rows with no control beside it, and
  /// [labelTracking] is still right there.
  static const double listHeadingTracking = 0.72;

  /// Pairs a [FontWeight] with the matching variable-axis setting.
  static List<FontVariation> _wght(FontWeight weight) => <FontVariation>[
    FontVariation('wght', weight.value.toDouble()),
  ];

  /// The same rung of the scale, set in a different weight.
  ///
  /// **`copyWith(fontWeight:)` alone is a silent no-op here.** The face and its
  /// CJK fallback are variable fonts and every rung carries a `wght` axis,
  /// which the renderer consults *instead of* [TextStyle.fontWeight] once it is
  /// present — so a style re-weighted by `fontWeight` alone reports the new
  /// weight to every test and paints the old one on the device. That is the
  /// same class of bug `component_theme_typography_test.dart` was opened for,
  /// arriving from the opposite direction.
  ///
  /// Deliberately not a general "restyle" helper: size, leading and tracking
  /// belong to the rung, and a component that needs different ones needs a
  /// different rung rather than a local edit.
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(fontWeight: weight, fontVariations: _wght(weight));

  /// One role of the scale, rendered in the app's one family.
  ///
  /// **[size], [height] and [tracking] are stated, never inherited.** Material
  /// 3's own scale is not GC-4's, and a slot left to it would move with an SDK
  /// bump with no line of code changing and no test noticing.
  /// `app_typography_test.dart` is what notices now.
  static TextStyle _role(
    TextStyle? base,
    FontWeight weight, {
    required double size,
    required double height,
    double tracking = 0,
  }) => (base ?? const TextStyle()).copyWith(
    fontFamily: family,
    fontFamilyFallback: cjkFallback,
    fontWeight: weight,
    fontVariations: _wght(weight),
    fontSize: size,
    height: height,
    letterSpacing: tracking,
  );

  static TextTheme buildTextTheme(TextTheme base) {
    TextStyle stat(TextStyle? slot) => _role(
      slot,
      FontWeight.w600,
      size: statSize,
      height: statHeight,
      tracking: headingTracking,
    );
    TextStyle display(TextStyle? slot) => _role(
      slot,
      FontWeight.w800,
      size: displaySize,
      height: displayHeight,
      tracking: headingTracking,
    );
    TextStyle headline(TextStyle? slot) => _role(
      slot,
      FontWeight.w700,
      size: headlineSize,
      height: headingHeight,
      tracking: headingTracking,
    );
    TextStyle bodyLarge(TextStyle? slot) =>
        _role(slot, FontWeight.w500, size: bodyLargeSize, height: bodyHeight);
    // The body size at semibold — a derived pairing (GC-4) for the slots
    // Material uses for short emphasised labels.
    TextStyle bodySemibold(TextStyle? slot) =>
        _role(slot, FontWeight.w600, size: bodySize, height: bodyHeight);

    return base.copyWith(
      displayLarge: stat(base.displayLarge),
      displayMedium: stat(base.displayMedium),
      displaySmall: display(base.displaySmall),
      headlineLarge: display(base.headlineLarge),
      headlineMedium: headline(base.headlineMedium),
      headlineSmall: headline(base.headlineSmall),
      titleLarge: _role(
        base.titleLarge,
        FontWeight.w700,
        size: titleSize,
        height: headingHeight,
        tracking: headingTracking,
      ),
      titleMedium: bodyLarge(base.titleMedium),
      titleSmall: bodySemibold(base.titleSmall),
      bodyLarge: bodyLarge(base.bodyLarge),
      bodyMedium: _role(
        base.bodyMedium,
        FontWeight.w400,
        size: bodySize,
        height: bodyHeight,
      ),
      // The caption size and leading at the body weight (GC-4) — metadata is
      // read as a sentence, so it takes neither the caption's 600 nor its
      // overline tracking.
      bodySmall: _role(
        base.bodySmall,
        FontWeight.w400,
        size: captionSize,
        height: captionHeight,
      ),
      labelLarge: bodySemibold(base.labelLarge),
      // The caption at the label tracking (GC-4).
      labelMedium: _role(
        base.labelMedium,
        FontWeight.w600,
        size: captionSize,
        height: captionHeight,
        tracking: labelTracking,
      ),
      labelSmall: _role(
        base.labelSmall,
        FontWeight.w600,
        size: captionSize,
        height: captionHeight,
        tracking: sectionLabelTracking,
      ),
    );
  }
}
