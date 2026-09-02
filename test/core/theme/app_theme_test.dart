import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_elevation.dart';
import 'package:memox/core/theme/app_radius.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/theme_context_extension.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../support/color_math.dart';
import '../../support/theme_probe.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';

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
      // **4.5 in both modes, and the floor does not move for a hex.** M100.27
      // held light at 4.3 to keep Tokyo's `#5569FF` verbatim; M100.28 reversed
      // that as the invariant now says: when a canonical role fails a ratio
      // the palette is retuned (`#4454CC`, 6.20:1), never the floor.
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

    test('the text link is readable at rest on page AND on card', () {
      // The link's label is bare text with no fill behind it, so it must clear
      // the body-text bar rather than the 3:1 UI bar. The slot is `primary`
      // (`_TextButtonDefaultsM3`, pinned by the AST guard), so this is the
      // measurement that forces the palette when it fails — twice a substitute
      // token stood here instead, and twice it was removed (M100.18, M100.28).
      // Read from the theme slot, not from a token, so the test holds
      // whichever colour the slot resolves to.
      for (final entry in themes.entries) {
        final label = entry.value.textButtonTheme.style!.foregroundColor!
            .resolve(const <WidgetState>{})!;

        for (final ground in <(String, Color)>[
          ('card', entry.value.colorScheme.surface),
          ('page', entry.value.scaffoldBackgroundColor),
        ]) {
          expect(
            contrast(label, ground.$2),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}: text link on ${ground.$1}',
          );
        }
      }
    });

    test('the radio mark is visible in both of its states', () {
      // WCAG 1.4.11 asks 3:1 of a UI component's visual information. Both
      // states matter: an invisible resting ring makes the unchosen options
      // look like plain rows, and the picker stops reading as a choice.
      for (final entry in themes.entries) {
        final fill = entry.value.radioTheme.fillColor!;

        for (final state in <(String, Color)>[
          (
            'selected',
            fill.resolve(const <WidgetState>{WidgetState.selected})!,
          ),
          ('resting', fill.resolve(const <WidgetState>{})!),
        ]) {
          for (final ground in <(String, Color)>[
            ('card', entry.value.colorScheme.surface),
            ('page', entry.value.scaffoldBackgroundColor),
          ]) {
            expect(
              contrast(state.$2, ground.$2),
              greaterThanOrEqualTo(3.0),
              reason: '${entry.key}: ${state.$1} radio on ${ground.$1}',
            );
          }
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

    test('a card edge produces the same step in both modes', () {
      // **This replaced a rule that had become wrong.** Until M4.10h it asserted
      // that the *border contrast* matched across modes, which was right while
      // the border was the only depth cue either mode had. Light now has a
      // shadow and dark does not — measured, not chosen: at the bottom of the
      // lightness scale a dark shadow moves the page by ΔL* 0.26 where the
      // surface step already moves it 7.70 — so matching the borders would force
      // light to keep drawing a frame it no longer needs.
      //
      // What has to stay symmetric is what a reader perceives: how big a step
      // the edge of a card makes against the page it lies on. Each mode is
      // allowed to build that step out of whatever it has.
      // **How far a card is lifted off the page, in total.** Not the border
      // contrast: a border is a one-pixel line, and the first version of this
      // measurement took whichever cue was furthest from the page, which meant
      // dark's border always won and reported 26.8 L* for a card that moves 7.7.
      //
      // The surface step plus whatever the shadow darkens around it — the two
      // things that actually make a card sit on something.
      double liftOf(ThemeData theme) {
        final page = theme.scaffoldBackgroundColor;
        final surfaceStep =
            (lightnessStar(theme.colorScheme.surface) - lightnessStar(page))
                .abs();

        var shadowStep = 0.0;
        for (final shadow in shadowsFor(AppElevation.card, theme.colorScheme)) {
          final under = Color.alphaBlend(shadow.color, page);
          final depth = (lightnessStar(page) - lightnessStar(under)).abs();
          if (depth > shadowStep) shadowStep = depth;
        }

        return surfaceStep + shadowStep;
      }

      // **Two cues per mode, and since M100.27 they are not the same two.**
      // Light lifts a card with the surface step plus a shade; dark's page
      // sits at the bottom of the lightness scale where a shade moves nothing,
      // and with the card fixed at Tokyo's `#111633` (owner decision) its
      // surface step is 4.3 L* — so dark's second cue is Tokyo's own: the
      // 1 px rim `shadowsFor` paints. A rim is an edge, measured as contrast
      // against what it separates (WCAG 1.4.11's 3:1), not as a shift of the
      // page's lightness, which is why the two modes are no longer held to one
      // number and are instead each held to their own pair. The colour measured
      // here is painted solid by the rim's 1 px spread (`app_elevation_test`
      // pins it), so the ratio is the ring's, not a blurred approximation.
      final lightLift = liftOf(themes['light']!);
      expect(
        lightLift,
        greaterThanOrEqualTo(6.0),
        reason:
            'light: a card edge moves the page by only '
            '${lightLift.toStringAsFixed(2)} L*. Below this a card does not '
            'read as sitting on anything.',
      );

      final dark = themes['dark']!;
      final darkPage = dark.scaffoldBackgroundColor;
      final darkStep =
          lightnessStar(dark.colorScheme.surface) - lightnessStar(darkPage);
      expect(
        darkStep,
        greaterThanOrEqualTo(4.0),
        reason:
            'dark: the card sits only ${darkStep.toStringAsFixed(2)} L* above '
            'the page; even with a rim it needs a visible step of its own',
      );
      final rim = shadowsFor(AppElevation.card, dark.colorScheme).single.color;
      for (final ground in <String, Color>{
        'page': darkPage,
        'card': dark.colorScheme.surface,
      }.entries) {
        expect(
          contrast(rim, ground.value),
          greaterThanOrEqualTo(3.0),
          reason:
              'dark: the card rim reads '
              '${contrast(rim, ground.value).toStringAsFixed(2)}:1 against '
              'the ${ground.key} — under the 3:1 an edge needs to separate',
        );
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
            contrast(entry.value.colorScheme.primary, ground.$2),
            greaterThanOrEqualTo(3.0),
            reason: '${entry.key}: focus ring on ${ground.$1}',
          );
        }
      }
    });
  });

  group('state ownership follows the resting pair', () {
    // The rule the 2026-08 theme-composition review distilled: change a
    // component's resting fill/foreground away from Material's canonical pair,
    // and every state default that component owns is yours to restate — M3's
    // are hardcoded to the *old* pair (`onPrimaryContainer` for the FAB), not
    // derived from the override.
    for (final entry in themes.entries) {
      test('${entry.key}: the FAB state washes are its own foreground', () {
        final ColorScheme scheme = entry.value.colorScheme;
        final FloatingActionButtonThemeData fab =
            entry.value.floatingActionButtonTheme;

        expect(fab.backgroundColor, scheme.primary);
        expect(fab.foregroundColor, scheme.onPrimary);
        // The house corner, owned here since the deck list stopped stating it
        // per-site — M3's default is the 16dp squircle nothing else uses.
        expect(
          fab.shape,
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        );
        for (final (String state, Color? wash) in <(String, Color?)>[
          ('hover', fab.hoverColor),
          ('focus', fab.focusColor),
          ('splash', fab.splashColor),
        ]) {
          expect(
            wash,
            isNotNull,
            reason:
                '$state left null falls to M3\'s onPrimaryContainer wash — '
                'another pair\'s ink over this pair\'s fill',
          );
          expect(
            wash!.withValues(alpha: 1),
            scheme.onPrimary.withValues(alpha: 1),
            reason: '$state washes in a colour that is not the foreground',
          );
        }
      });

      test(
        '${entry.key}: the snackbar states its depth like every overlay',
        () {
          // Silence here resolved to the SDK's 6.0 — in dark too, where the app
          // has measurably opted out of shadows.
          expect(
            entry.value.snackBarTheme.elevation,
            entry.key == 'dark' ? AppElevation.none : AppElevation.overlay,
          );
          expect(
            entry.value.floatingActionButtonTheme.elevation,
            entry.value.snackBarTheme.elevation,
            reason: 'two overlays, two depth policies — there is one',
          );
        },
      );
    }
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
            appSettingsRepositoryProvider.overrideWithValue(
              FakeAppSettingsRepository(),
            ),
            deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          ],
          child: const MemoxApp(),
        ),
      );

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));

      expect(app.themeMode, ThemeMode.system);
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);

      // **And it hands `MaterialApp` the shared instances, not fresh ones.**
      // `same`, not `==`: a rebuilt theme is never `==` anyway, which is the
      // whole reason the builders memoise. `app_theme_identity_test.dart`
      // holds that argument; this is the half of it that only a mounted
      // `MemoxApp` can prove.
      expect(app.theme, same(buildLightTheme()));
      expect(app.darkTheme, same(buildDarkTheme()));
    });
  });
}
