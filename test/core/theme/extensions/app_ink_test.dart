import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/extensions/app_ink.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';

import '../../../support/color_math.dart';

/// The contract behind the closed ink set: every ink a feature can name is
/// legible on the ground it is *for*, in both themes. A feature cannot check
/// this per call site any more — that is the point of the enum — so the enum's
/// own test has to.
void main() {
  final themes = <String, ThemeData>{
    'light': buildLightTheme(),
    'dark': buildDarkTheme(),
  };

  group('every ink resolves', () {
    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        final resolved = <AppInk, Color>{};
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                for (final ink in AppInk.values) {
                  resolved[ink] = ink.resolve(context);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        expect(resolved.length, AppInk.values.length);
      });
    }
  });

  group('page-ground inks clear the text bar on surface and page', () {
    // The inks meant for plain grounds. `disabled` is exempt by WCAG's own
    // inactive-control carve-out; the on*Container inks are measured on their
    // containers below; `onPrimary` on its fill.
    // `warning` is deliberately absent: it measures 4.33:1 on the light page
    // — a fact the card tile's state label already documents and designs
    // around by keeping its own label neutral there. Warning text belongs on
    // a surface; the pin below holds it to the surface bar and the UI bar on
    // the page, so the constraint is recorded instead of silently waived.
    const pageInks = <AppInk>[
      AppInk.stated,
      AppInk.quiet,
      AppInk.accent,
      AppInk.success,
      AppInk.danger,
      AppInk.info,
      AppInk.error,
      AppInk.overdue,
    ];

    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        late ColorScheme scheme;
        final resolved = <AppInk, Color>{};
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                scheme = Theme.of(context).colorScheme;
                for (final ink in pageInks) {
                  resolved[ink] = ink.resolve(context);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final grounds = <String, Color>{
          'surface': scheme.surface,
          'page': entry.value.scaffoldBackgroundColor,
        };
        for (final ink in pageInks) {
          for (final ground in grounds.entries) {
            expect(
              contrast(resolved[ink]!, ground.value),
              greaterThanOrEqualTo(4.5),
              reason:
                  '${entry.key}: AppInk.${ink.name} on ${ground.key} — an ink '
                  'in the closed set must hold the bar everywhere features '
                  'are allowed to spend it',
            );
          }
        }
      });
    }

    // `secondary` and `tertiary` are support inks: they pass 4.5 in light and
    // sit at the large-text/UI bar in dark, which is where their two callers
    // (the import preview's status glyphs and counts) use them beside a
    // spelled-out reason line. Pinned at 3:1 so they cannot quietly sink
    // below even that.
    for (final entry in themes.entries) {
      testWidgets('${entry.key}: support inks hold at least 3:1', (
        tester,
      ) async {
        late ColorScheme scheme;
        final resolved = <AppInk, Color>{};
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                scheme = Theme.of(context).colorScheme;
                for (final ink in <AppInk>[
                  AppInk.secondary,
                  AppInk.tertiary,
                  AppInk.warning,
                ]) {
                  resolved[ink] = ink.resolve(context);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
        for (final ink in resolved.entries) {
          expect(
            contrast(ink.value, scheme.surface),
            greaterThanOrEqualTo(ink.key == AppInk.warning ? 4.5 : 3.0),
            reason: '${entry.key}: AppInk.${ink.key.name} on surface',
          );
        }
      });
    }
  });

  group('container inks are measured on their containers', () {
    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        late ColorScheme scheme;
        late AppSemanticColors semantic;
        final resolved = <AppInk, Color>{};
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                scheme = Theme.of(context).colorScheme;
                semantic = entry.value.extension<AppSemanticColors>()!;
                for (final ink in AppInk.values) {
                  resolved[ink] = ink.resolve(context);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        final pairs = <AppInk, Color>{
          AppInk.onPrimary: scheme.primary,
          AppInk.onPrimaryContainer: scheme.primaryContainer,
          AppInk.onSecondaryContainer: scheme.secondaryContainer,
          AppInk.onErrorContainer: scheme.errorContainer,
          AppInk.onTertiaryContainer: scheme.tertiaryContainer,
          AppInk.onDueContainer: semantic.dueContainer,
        };
        for (final pair in pairs.entries) {
          expect(
            contrast(resolved[pair.key]!, pair.value),
            greaterThanOrEqualTo(4.5),
            reason: '${entry.key}: AppInk.${pair.key.name} on its container',
          );
        }
      });
    }
  });

  group('text inks clear 4.5:1 on every text ground (GC-3)', () {
    // The five grounds text lands on in each mode, read off the real
    // ColorScheme rather than restated as literals — a ground that drifts
    // should fail this test, not agree with it.
    for (final entry in themes.entries) {
      test(entry.key, () {
        final scheme = entry.value.colorScheme;
        final semantic = entry.value.extension<AppSemanticColors>()!;

        final grounds = <String, Color>{
          'surface': scheme.surface,
          'surfaceContainerLowest': scheme.surfaceContainerLowest,
          'surfaceContainerLow': scheme.surfaceContainerLow,
          'surfaceContainer': scheme.surfaceContainer,
          'surfaceContainerHigh': scheme.surfaceContainerHigh,
        };
        final inks = <String, Color>{
          'accentInk': semantic.accentInk,
          'dangerInk': semantic.dangerInk,
          'successInk': semantic.successInk,
          'warningInk': semantic.warningInk,
          'secondaryInk': semantic.secondaryInk,
          'tertiaryInk': semantic.tertiaryInk,
        };

        for (final ink in inks.entries) {
          for (final ground in grounds.entries) {
            expect(
              contrast(ink.value, ground.value),
              greaterThanOrEqualTo(4.5),
              reason:
                  '${entry.key}: AppSemanticColors.${ink.key} on '
                  '${ground.key}',
            );
          }
        }

        // Invariant: one value, measured against the one ground it is for.
        expect(
          contrast(semantic.inversePrimaryInk, scheme.inverseSurface),
          greaterThanOrEqualTo(4.5),
          reason:
              '${entry.key}: AppSemanticColors.inversePrimaryInk on '
              'inverseSurface',
        );
      });
    }
  });

  group('AppInk.resolve routes text through the same-hue ink (GC-3)', () {
    const routed = <AppInk>[
      AppInk.accent,
      AppInk.success,
      AppInk.warning,
      AppInk.danger,
      AppInk.error,
      AppInk.errorDirect,
      AppInk.overdue,
      AppInk.secondary,
      AppInk.tertiary,
    ];

    for (final entry in themes.entries) {
      testWidgets(entry.key, (tester) async {
        final semantic = entry.value.extension<AppSemanticColors>()!;
        final resolved = <AppInk, Color>{};
        await tester.pumpWidget(
          MaterialApp(
            theme: entry.value,
            home: Builder(
              builder: (context) {
                for (final ink in routed) {
                  resolved[ink] = ink.resolve(context);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(resolved[AppInk.accent], semantic.accentInk);
        expect(resolved[AppInk.success], semantic.successInk);
        expect(resolved[AppInk.warning], semantic.warningInk);
        expect(resolved[AppInk.danger], semantic.dangerInk);
        expect(resolved[AppInk.error], semantic.dangerInk);
        expect(resolved[AppInk.errorDirect], entry.value.colorScheme.error);
        expect(resolved[AppInk.overdue], semantic.dangerInk);
        expect(resolved[AppInk.secondary], semantic.secondaryInk);
        expect(resolved[AppInk.tertiary], semantic.tertiaryInk);
      });
    }
  });

  group('inked()', () {
    testWidgets('emphasis moves the variable-font axis, not just the number', (
      tester,
    ) async {
      late TextStyle plain;
      late TextStyle emphasized;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (context) {
              final rung = Theme.of(context).textTheme.bodySmall!;
              plain = rung.inked(context, AppInk.quiet);
              emphasized = rung.inked(
                context,
                AppInk.quiet,
                isEmphasized: true,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // Which weight "emphasized" lands on used to be pinned at w600 on both
      // sides. It went when Design System V1 was unlocked; the claim that
      // matters is that emphasized differs from plain and that the axis agrees
      // with it, and neither needs the number.
      expect(emphasized.fontWeight, isNotNull);
      expect(emphasized.fontWeight, isNot(plain.fontWeight));
      // The load-bearing half: on a variable font the renderer reads the axis
      // over fontWeight, so an API that set only the number would repeat the
      // bug it exists to end.
      expect(
        emphasized.fontVariations,
        contains(
          FontVariation('wght', emphasized.fontWeight!.value.toDouble()),
        ),
      );
    });

    testWidgets('tabular is a flag; metrics stay the rung\'s', (tester) async {
      late TextStyle styled;
      late TextStyle rung;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Builder(
            builder: (context) {
              rung = Theme.of(context).textTheme.labelMedium!;
              styled = rung.inked(context, AppInk.stated, isTabular: true);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(styled.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(
        styled.fontSize,
        rung.fontSize,
        reason: 'size belongs to the rung',
      );
      expect(styled.height, rung.height, reason: 'leading belongs to the rung');
      expect(
        styled.letterSpacing,
        rung.letterSpacing,
        reason: 'tracking belongs to the rung',
      );
    });
  });
}
