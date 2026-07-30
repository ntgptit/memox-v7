import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context_extension.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../support/color_math.dart';
import '../../support/theme_probe.dart';

/// Readability and wiring. What the palette *is* — the ladder, the saturation
/// discipline, the chroma budget — is asserted in `app_palette_test.dart`.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  group('contrast', () {
    test('the helper matches known WCAG values', () {
      // Calibrates the helper before it is trusted to judge the palette: black
      // on white is exactly 21:1, and a colour against itself is 1:1.
      expect(
        contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
      expect(
        contrast(const Color(0xFF4C5BD4), const Color(0xFF4C5BD4)),
        closeTo(1, 0.001),
      );
    });

    test('text clears 4.5:1 on the card AND on the page', () {
      // Both grounds, because the same text style lands on either one. The page
      // is the harsher of the two in dark: it is the deepest colour in the app.
      for (final entry in themes.entries) {
        final scheme = entry.value.colorScheme;
        final grounds = <(String, Color)>[
          ('card', scheme.surface),
          ('page', entry.value.scaffoldBackgroundColor),
        ];

        for (final ground in grounds) {
          for (final text in <(String, Color)>[
            ('onSurface', scheme.onSurface),
            ('onSurfaceVariant', scheme.onSurfaceVariant),
          ]) {
            expect(
              contrast(text.$2, ground.$2),
              greaterThanOrEqualTo(4.5),
              reason: '${entry.key}: ${text.$1} on ${ground.$1}',
            );
          }
        }
      }
    });

    test('a label on a filled action is readable', () {
      // The failure this catches is specific: M3's light-on-light pairing gives
      // white text 1.71:1 on the tone-80 lavender, which passes no standard.
      // Read from the theme, not from a token — the gap that once shipped a
      // 3.09:1 label was a test that checked a token the button did not use.
      for (final entry in themes.entries) {
        expect(
          contrast(
            entry.value.colorScheme.onPrimary,
            filledButtonFill(entry.value),
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: onPrimary on the action fill',
        );
        expect(
          contrast(
            entry.value.colorScheme.onError,
            entry.value.colorScheme.error,
          ),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key}: onError on error',
        );
      }
    });

    test('the outlined label is readable on page AND on card', () {
      for (final entry in themes.entries) {
        final label = outlinedButtonLabel(entry.value);

        for (final ground in <(String, Color)>[
          ('page', entry.value.scaffoldBackgroundColor),
          ('card', entry.value.colorScheme.surface),
        ]) {
          expect(
            contrast(label, ground.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}: outlined label on ${ground.$1}',
          );
        }
      }
    });

    test('semantic colours stay legible on card and page', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;

        for (final ground in <(String, Color)>[
          ('card', entry.value.colorScheme.surface),
          ('page', entry.value.scaffoldBackgroundColor),
        ]) {
          for (final pair in <(String, Color)>[
            ('success', semantic.success),
            ('warning', semantic.warning),
            ('danger', semantic.danger),
            ('info', semantic.info),
          ]) {
            expect(
              contrast(pair.$2, ground.$2),
              greaterThanOrEqualTo(3.0),
              reason: '${entry.key}: ${pair.$1} on ${ground.$1}',
            );
          }
        }
      }
    });
  });

  group('input focus', () {
    test('focus changes the border colour, never its weight', () {
      // Material's default goes 1px -> 2px on focus. That makes the field jump
      // and nudges whatever is laid out beside it.
      for (final entry in themes.entries) {
        final input = entry.value.inputDecorationTheme;
        final enabled = input.enabledBorder! as OutlineInputBorder;
        final focused = input.focusedBorder! as OutlineInputBorder;

        expect(
          focused.borderSide.width,
          enabled.borderSide.width,
          reason: '${entry.key}: focus changed the stroke width',
        );
        expect(
          focused.borderSide.color,
          isNot(enabled.borderSide.color),
          reason: '${entry.key}: focus is not visible at all',
        );
        expect(
          focused.borderRadius,
          enabled.borderRadius,
          reason: '${entry.key}: focus changed the shape',
        );
      }
    });

    test('the focus ring is visible on every surface a field can sit on', () {
      for (final entry in themes.entries) {
        final semantic = entry.value.extension<AppSemanticColors>()!;

        for (final ground in <(String, Color)>[
          ('tile', semantic.surfaceMuted),
          ('card', entry.value.colorScheme.surface),
          ('page', entry.value.scaffoldBackgroundColor),
        ]) {
          expect(
            contrast(semantic.focusRing, ground.$2),
            greaterThanOrEqualTo(3.0),
            reason: '${entry.key}: focus ring on ${ground.$1}',
          );
        }
      }
    });
  });

  group('theme wiring', () {
    testWidgets('the same widget builds in light and dark without throwing', (
      tester,
    ) async {
      for (final entry in themes.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: <Widget>[
                    Text('probe', style: context.texts.bodyMedium),
                    ColoredBox(
                      color: context.semanticColors.success,
                      child: const SizedBox.square(dimension: 8),
                    ),
                    FilledButton(onPressed: () {}, child: const Text('a')),
                    OutlinedButton(onPressed: () {}, child: const Text('b')),
                    const Card(child: SizedBox.square(dimension: 8)),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });

    testWidgets('context.semanticColors explains a missing extension', (
      tester,
    ) async {
      // A silent default would render the wrong colour on a screen nobody
      // re-checks; this must fail loudly at the first build instead.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Builder(
            builder: (context) {
              context.semanticColors;

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('MemoxApp follows the system theme mode', (tester) async {
      // `themeMode` is not passed explicitly — it would be a redundant argument
      // and this project promotes that lint to error. Pin the behaviour here so
      // the omission stays deliberate rather than becoming an accident.
      //
      // The scope is not scenery: the home route reads decks, so a bare
      // `MemoxApp` would fail to find a container and — with a real repository
      // behind it — would open the on-device database from a theme test.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          ],
          child: const MemoxApp(),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.themeMode, ThemeMode.system);
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
    });
  });
}
