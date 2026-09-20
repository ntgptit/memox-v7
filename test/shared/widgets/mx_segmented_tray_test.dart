import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_tap_target.dart';

import '../../visual_audit/audit_raster.dart';

enum _Choice { first, second, third }

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TextDirection textDirection = TextDirection.ltr,
    double textScale = 1,
    ThemeData? theme,
    Size viewport = const Size(393, 852),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme ?? buildLightTheme(),
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(
              size: viewport,
              textScaler: TextScaler.linear(textScale),
            ),
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  MxSegmentedTray<_Choice> tray({
    _Choice selected = _Choice.first,
    ValueChanged<_Choice>? onChanged,
    MxSegmentedTrayVariant variant = MxSegmentedTrayVariant.settings,
    List<MxSegmentedTrayOption<_Choice>>? options,
  }) => MxSegmentedTray<_Choice>(
    options:
        options ??
        const <MxSegmentedTrayOption<_Choice>>[
          MxSegmentedTrayOption<_Choice>(value: _Choice.first, label: 'First'),
          MxSegmentedTrayOption<_Choice>(
            value: _Choice.second,
            label: 'Second',
          ),
        ],
    selected: selected,
    variant: variant,
    onChanged: onChanged ?? (_) {},
  );

  final Finder trayFinder = find.byKey(MxSegmentedTray.surfaceKey);

  group('MxSegmentedTray', () {
    testWidgets('reports the tapped typed choice', (tester) async {
      _Choice? changed;
      await pump(tester, tray(onChanged: (value) => changed = value));

      await tester.tap(find.text('Second'));

      expect(changed, _Choice.second);
    });

    testWidgets('announces the selected mutually-exclusive option', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, tray());

      expect(
        tester.getSemantics(find.text('First')),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasSelectedState: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          label: 'First',
        ),
      );
      final unselected = tester
          .getSemantics(find.text('Second'))
          .getSemanticsData();
      expect(unselected.flagsCollection.isSelected, Tristate.isFalse);
      expect(unselected.hasAction(SemanticsAction.tap), isTrue);
      expect(unselected.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets('keeps a 32dp thumb inside the 48dp target', (tester) async {
      await pump(tester, tray());

      expect(tester.getSize(trayFinder).height, AppSizing.touchTarget);
      expect(tester.getSize(find.byKey(MxSegmentedTray.thumbKey)).height, 32);
      expect(tester.getRect(find.byKey(MxSegmentedTray.thumbKey)).height, 32);
    });

    testWidgets('uses the 4, 2, 12 and 8 geometry contract', (tester) async {
      await pump(tester, tray());

      final trayRect = tester.getRect(find.byKey(MxSegmentedTray.surfaceKey));
      final first = tester.getRect(find.text('First'));
      final second = tester.getRect(find.text('Second'));
      final thumb = tester.getRect(find.byKey(MxSegmentedTray.thumbKey));

      expect(first.left - trayRect.left, 16);
      expect(second.left - first.right, 26);
      expect(thumb.left - trayRect.left, 4);
      expect(thumb.height, 32);
      expect(
        tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byKey(MxSegmentedTray.thumbKey),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration,
        isA<BoxDecoration>().having(
          (decoration) => decoration.borderRadius,
          'thumb radius',
          BorderRadius.circular(8),
        ),
      );
    });

    testWidgets('is intrinsic-width rather than stretching to its parent', (
      tester,
    ) async {
      await pump(tester, SizedBox(width: 300, child: tray()));

      expect(tester.getSize(trayFinder).width, lessThan(300));
    });

    testWidgets(
      'keeps compact labels content-driven at a real viewport width',
      (tester) async {
        await pump(tester, tray());

        expect(tester.getSize(trayFinder).width, lessThan(200));
      },
    );

    testWidgets(
      'does not expand to fill a narrow parent that fits its labels',
      (tester) async {
        await pump(tester, SizedBox(width: 180, child: tray()));

        expect(tester.getSize(trayFinder).width, lessThan(180));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('each option activates from its own vertical target padding', (
      tester,
    ) async {
      _Choice? changed;
      await pump(tester, tray(onChanged: (value) => changed = value));

      for (var index = 0; index < 2; index++) {
        final target = tester.getRect(find.byType(MxTapTarget).at(index));
        await tester.tapAt(Offset(target.center.dx, target.bottom - 1));
        await tester.pumpAndSettle();

        expect(changed, _Choice.values[index]);
      }
    });

    testWidgets('each option keeps a 48dp semantic hit rectangle', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester, tray());

      for (final label in <String>['First', 'Second']) {
        final rect = tester.getSemantics(find.text(label)).rect;
        expect(rect.width, greaterThanOrEqualTo(AppSizing.touchTarget));
        expect(rect.height, AppSizing.touchTarget);
      }
      semantics.dispose();
    });

    testWidgets('shows the canonical focus geometry on keyboard focus', (
      tester,
    ) async {
      final captureKey = UniqueKey();
      await pump(tester, RepaintBoundary(key: captureKey, child: tray()));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final thumbRect = tester.getRect(find.byKey(MxSegmentedTray.thumbKey));
      final capture = await RasterCapture.capture(
        tester,
        boundaryFinder: find.byKey(captureKey),
      );
      final color = Theme.of(tester.element(trayFinder)).colorScheme.primary;

      expect(
        capture.farthestFrom(
          Theme.of(tester.element(trayFinder)).colorScheme.surfaceContainer,
          Rect.fromLTWH(thumbRect.left - 4, thumbRect.center.dy - 2, 2, 4),
        ),
        color,
      );
      expect(
        capture.farthestFrom(
          Theme.of(tester.element(trayFinder)).colorScheme.surfaceContainer,
          Rect.fromLTWH(thumbRect.right + 2, thumbRect.center.dy - 2, 2, 4),
        ),
        color,
      );
    });

    testWidgets(
      'keeps an earlier focused ring visible over a later selected sibling',
      (tester) async {
        final captureKey = UniqueKey();
        await pump(
          tester,
          RepaintBoundary(
            key: captureKey,
            child: tray(selected: _Choice.second),
          ),
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();

        final firstTarget = tester.getRect(find.byType(MxTapTarget).first);
        final secondTarget = tester.getRect(find.byType(MxTapTarget).at(1));
        final capture = await RasterCapture.capture(
          tester,
          boundaryFinder: find.byKey(captureKey),
        );

        expect(
          capture.farthestFrom(
            Theme.of(
              tester.element(trayFinder),
            ).colorScheme.surfaceContainerLowest,
            Rect.fromLTWH(secondTarget.left, firstTarget.center.dy - 2, 2, 4),
          ),
          Theme.of(tester.element(trayFinder)).colorScheme.primary,
          reason:
              'the earlier option\'s right focus stroke must paint above the '
              'later selected surface',
        );
      },
    );

    testWidgets('keeps labels on one intrinsic line without ellipsizing', (
      tester,
    ) async {
      const longLabel = 'A deliberately long unabridged choice label';
      await pump(
        tester,
        UnconstrainedBox(
          child: tray(
            options: const <MxSegmentedTrayOption<_Choice>>[
              MxSegmentedTrayOption<_Choice>(
                value: _Choice.first,
                label: longLabel,
              ),
              MxSegmentedTrayOption<_Choice>(
                value: _Choice.second,
                label: longLabel,
              ),
            ],
          ),
        ),
      );

      final label = tester.widget<Text>(find.text(longLabel).first);
      expect(label.maxLines, 1);
      expect(label.softWrap, isFalse);
      expect(label.overflow, isNull);
      expect(tester.getSize(trayFinder).width, greaterThan(393));
    });

    testWidgets(
      'uses surface roles in both variants, dark, and high contrast',
      (tester) async {
        final themes = <ThemeData>[
          buildDarkTheme(),
          buildHighContrastDarkTheme(),
        ];

        for (final theme in themes) {
          for (final variant in MxSegmentedTrayVariant.values) {
            await pump(tester, tray(variant: variant), theme: theme);

            final surface = tester.widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byKey(MxSegmentedTray.surfaceKey),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            final selected = tester.widget<Material>(
              find.descendant(
                of: find.byKey(MxSegmentedTray.thumbKey),
                matching: find.byType(Material),
              ),
            );

            expect(
              (surface.decoration as BoxDecoration).color,
              theme.colorScheme.surfaceContainer,
            );
            expect(selected.color, theme.colorScheme.surfaceContainerLowest);
            expect(
              tester.widget<Text>(find.text('First')).style!.color,
              theme.colorScheme.onSurface,
            );
            expect(
              tester.widget<Text>(find.text('Second')).style!.color,
              theme.colorScheme.onSurfaceVariant,
            );
          }
        }
      },
    );

    testWidgets('preserves its width while submitting is disabled', (
      tester,
    ) async {
      await pump(tester, tray());
      final enabledWidth = tester.getSize(trayFinder).width;

      await pump(
        tester,
        MxSegmentedTray<_Choice>(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.second,
              label: 'Second',
            ),
          ],
          selected: _Choice.first,
          variant: MxSegmentedTrayVariant.settings,
          onChanged: null,
        ),
      );

      expect(tester.getSize(trayFinder).width, enabledWidth);
    });

    testWidgets('announces the supplied fuller option semantic label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(
        tester,
        tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: '7 days',
              semanticLabel: 'Last 7 days ending today',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.second,
              label: '30 days',
            ),
          ],
        ),
      );

      expect(find.bySemanticsLabel('Last 7 days ending today'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('does not overflow in RTL at text scale 2', (tester) async {
      await pump(
        tester,
        tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.second,
              label: 'Second',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.third,
              label: 'Third',
            ),
          ],
        ),
        textDirection: TextDirection.rtl,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    test('requires two or three options', () {
      expect(
        () => tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => tray(
          options: const <MxSegmentedTrayOption<_Choice>>[
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'First',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.second,
              label: 'Second',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.third,
              label: 'Third',
            ),
            MxSegmentedTrayOption<_Choice>(
              value: _Choice.first,
              label: 'Fourth',
            ),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
