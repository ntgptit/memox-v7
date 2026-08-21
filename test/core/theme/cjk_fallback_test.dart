import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_text_styles.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/app_typography.dart';

/// The CJK fallback is wired onto every text style **and** the faces it names
/// are actually there, so a card whose content is Korean, Japanese or Chinese
/// renders the script instead of tofu boxes.
///
/// **Two halves, because either one alone passes while the app is broken.**
/// Wiring says the style names [AppTypography.cjkFallback] behind its Latin
/// primary. Rendering says the engine can reach those families and lay the
/// script out with them. A name pointing at a family the font collection does
/// not hold is not a fallback — it is skipped, and the glyph comes back as the
/// missing-glyph box.
///
/// This file used to be the wiring half only, on the stated grounds that
/// `flutter_test`'s renderer "does not exercise the fallback, so a PNG would
/// prove nothing". It does exercise it. What it could not do was reach a font
/// nobody had registered: `NotoSansKR` went into `pubspec.yaml` and into every
/// rung, and never into `test/flutter_test_config.dart`, so for months every
/// Korean glyph in every golden was a box — in an app for learning Korean. The
/// wiring test passed the whole time, because the thing it checks was never what
/// was wrong.
///
/// So the rendering half asserts the one fact the wiring half cannot: CJK text
/// in the app's own style does **not** measure like the missing-glyph box, and
/// does measure like the face that is supposed to carry it. It fails the moment
/// the harness stops loading a face, which is the failure that went unnoticed.
///
/// **What it does not prove.** All three faces set a full-width glyph to the
/// same advance, so a width cannot tell Japanese apart from Simplified Chinese
/// for the Han both cover. The order between those two is a documented decision
/// in [AppTypography.cjkFallback], not something measured here.
void main() {
  /// Every rung [AppTypography.buildTextTheme] sets — all fifteen.
  ///
  /// The old list held six, and `headlineMedium` was not one of them. The
  /// card prompt — the single largest piece of CJK the app ever draws — has
  /// since left the scale for `AppTextStyles.cardPrompt`, so it is checked
  /// alongside the rungs rather than as one of them.
  Map<String, TextStyle?> rungsOf(TextTheme t) => <String, TextStyle?>{
    'cardPrompt': buildLightTheme().extension<AppTextStyles>()!.cardPrompt,
    'displayLarge': t.displayLarge,
    'displayMedium': t.displayMedium,
    'displaySmall': t.displaySmall,
    'headlineLarge': t.headlineLarge,
    'headlineMedium': t.headlineMedium,
    'headlineSmall': t.headlineSmall,
    'titleLarge': t.titleLarge,
    'titleMedium': t.titleMedium,
    'titleSmall': t.titleSmall,
    'bodyLarge': t.bodyLarge,
    'bodyMedium': t.bodyMedium,
    'bodySmall': t.bodySmall,
    'labelLarge': t.labelLarge,
    'labelMedium': t.labelMedium,
    'labelSmall': t.labelSmall,
  };

  void expectFallback(TextTheme texts) {
    for (final entry in rungsOf(texts).entries) {
      final style = entry.value;
      expect(style, isNotNull, reason: '${entry.key} must be set by the theme');
      // The whole chain, in order — not `contains`. Order decides which face
      // draws the Han that Japanese and Simplified Chinese share, so a rung that
      // merely mentions the families is not the same rung.
      expect(
        style!.fontFamilyFallback,
        AppTypography.cjkFallback,
        reason: '${entry.key} must carry the CJK fallback chain, in order',
      );
    }
  }

  test('light theme text styles fall back to the CJK faces', () {
    expectFallback(buildLightTheme().textTheme);
  });

  test('dark theme text styles fall back to the CJK faces', () {
    expectFallback(buildDarkTheme().textTheme);
  });

  for (final script in _scripts) {
    test('${script.name} renders from its face, not the missing-glyph box', () {
      // The card prompt — the largest CJK the app draws. Its own style since
      // it left the scale, and it carries the same fallback chain.
      final prompt = buildLightTheme().extension<AppTextStyles>()!.cardPrompt;

      // The same rung with the chain removed. Plus Jakarta Sans is Latin-only,
      // so this is guaranteed to come back as `flutter_test`'s missing-glyph
      // box — the exact shape the app rendered before the harness loaded the
      // faces.
      final asBoxes = _widthOf(
        script.sample,
        prompt.copyWith(fontFamilyFallback: const <String>[]),
      );

      // The same rung with the expected face as the primary. Nothing to fall
      // back *to*, so this is the face itself, measured directly.
      final asFace = _widthOf(
        script.sample,
        prompt.copyWith(
          fontFamily: script.family,
          fontFamilyFallback: const <String>[],
        ),
      );

      final asShipped = _widthOf(script.sample, prompt);

      expect(
        asShipped,
        isNot(asBoxes),
        reason:
            '${script.name} laid out in the app style measures the same as the '
            'missing-glyph box, so the fallback resolved to nothing. Check that '
            '${script.family} is in `_appFonts` in '
            'test/flutter_test_config.dart.',
      );
      expect(
        asShipped,
        asFace,
        reason:
            '${script.name} in the app style does not measure like '
            '${script.family}, so some other face is carrying the script.',
      );
    });
  }
}

/// One script, the face that should carry it, and a sample from real content.
typedef _Script = ({String name, String family, String sample});

const List<_Script> _scripts = <_Script>[
  // 사과 — "apple", from the starter deck.
  (name: 'Hangul', family: AppTypography.cjkFallbackFamily, sample: '사과'),
  // ひらがな / カタカナ — kana, which no other loaded face carries in front of
  // the Japanese one.
  (name: 'Kana', family: AppTypography.japaneseFallbackFamily, sample: 'ひらがな'),
  // 学校 — Han. Japanese is ahead of Simplified Chinese in the chain, so it is
  // the face that answers for the codepoints both cover.
  (name: 'Han', family: AppTypography.japaneseFallbackFamily, sample: '学校'),
];

double _widthOf(String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final width = painter.width;
  painter.dispose();
  return width;
}
