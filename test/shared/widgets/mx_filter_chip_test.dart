import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

/// `MxFilterChip` — v3's fixed-28dp one-of-N control, and the first caller of
/// `border-ghost`.
///
/// Unlike `MxPillButton` this does not wrap `ChoiceChip`, so nothing here is
/// free: the button/selected/enabled semantics, the tap target, the disabled
/// paint and the no-shrink content rule are all hand-rolled and each gets its
/// own assertion.
void main() {
  Future<void> pump(WidgetTester tester, Widget chip) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: Center(child: chip)),
      ),
    );
  }

  Finder paintedMaterial() => find
      .descendant(
        of: find.byType(MxFilterChip),
        matching: find.byType(Material),
      )
      .first;

  group('interaction', () {
    testWidgets('tapping calls onPressed when enabled', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxFilterChip(
          label: 'Cards',
          isSelected: false,
          onPressed: () => presses += 1,
        ),
      );

      await tester.tap(find.byType(MxFilterChip));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets(
      'a null onPressed does nothing on tap and dims the painted pill',
      (tester) async {
        await pump(
          tester,
          const MxFilterChip(
            label: 'Cards',
            isSelected: false,
            onPressed: null,
          ),
        );

        final Opacity opacity = tester.widget<Opacity>(
          find
              .ancestor(of: paintedMaterial(), matching: find.byType(Opacity))
              .first,
        );
        expect(opacity.opacity, AppStateOpacity.disabled);

        // No callback to observe, but the tap must not throw and must not be
        // forwarded to InkWell's onTap (which is null when disabled).
        await tester.tap(find.byType(MxFilterChip), warnIfMissed: false);
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('an enabled pill paints at full opacity', (tester) async {
      await pump(
        tester,
        MxFilterChip(label: 'Cards', isSelected: false, onPressed: () {}),
      );

      final Opacity opacity = tester.widget<Opacity>(
        find
            .ancestor(of: paintedMaterial(), matching: find.byType(Opacity))
            .first,
      );
      expect(opacity.opacity, 1.0);
    });
  });

  group('semantics', () {
    testWidgets('reports button/selected/enabled and the label once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxFilterChip(label: 'Due only', isSelected: true, onPressed: () {}),
      );

      expect(
        tester.getSemantics(find.byType(MxFilterChip)),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
          label: 'Due only',
        ),
      );
      // Excluded from the tree, so the inner Text never announces a second
      // node with the same words.
      expect(find.bySemanticsLabel('Due only'), findsOneWidget);
      handle.dispose();
    });

    // `isFocusable` is left at matchesSemantics' default (false) on purpose:
    // a disabled chip must not advertise focusability.
    testWidgets('a disabled pill reports enabled: false and no tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        const MxFilterChip(
          label: 'Due only',
          isSelected: false,
          onPressed: null,
        ),
      );

      expect(
        tester.getSemantics(find.byType(MxFilterChip)),
        matchesSemantics(
          isButton: true,
          hasSelectedState: true,
          hasEnabledState: true,
          label: 'Due only',
        ),
      );
      handle.dispose();
    });

    testWidgets('the count is the node value; the label stays announced once', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxFilterChip(
          label: 'Due',
          count: 3,
          isSelected: false,
          onPressed: () {},
        ),
      );
      SemanticsNode node = tester.getSemantics(find.byType(MxFilterChip));
      expect(node.value, '3');
      expect(node.label, 'Due');
      expect(find.bySemanticsLabel('Due'), findsOneWidget);

      await pump(
        tester,
        MxFilterChip(label: 'Due', isSelected: false, onPressed: () {}),
      );
      node = tester.getSemantics(find.byType(MxFilterChip));
      expect(node.value, isEmpty);
      expect(node.label, 'Due');
      handle.dispose();
    });

    testWidgets('semanticLabel replaces the visible label, not appends it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxFilterChip(
          label: 'A-Z',
          semanticLabel: 'Sorted by name',
          isSelected: true,
          onPressed: () {},
        ),
      );

      expect(find.bySemanticsLabel('Sorted by name'), findsOneWidget);
      expect(find.bySemanticsLabel('A-Z'), findsNothing);
      handle.dispose();
    });
  });

  group('selection shape', () {
    testWidgets('shows the caller icon when unselected', (tester) async {
      await pump(
        tester,
        MxFilterChip(
          label: 'Due',
          icon: Icons.schedule,
          isSelected: false,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows a tick, replacing the caller icon, when selected', (
      tester,
    ) async {
      await pump(
        tester,
        MxFilterChip(
          label: 'Due',
          icon: Icons.schedule,
          isSelected: true,
          onPressed: () {},
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNothing);
    });

    for (final IconData? icon in <IconData?>[null, Icons.schedule]) {
      testWidgets(
        'toggling ${icon == null ? 'a plain' : 'an iconed'} pill does not '
        'change its painted width',
        (tester) async {
          await pump(
            tester,
            MxFilterChip(
              label: 'Due',
              icon: icon,
              count: 3,
              isSelected: false,
              onPressed: () {},
            ),
          );
          final double off = tester.getSize(paintedMaterial()).width;

          await pump(
            tester,
            MxFilterChip(
              label: 'Due',
              icon: icon,
              count: 3,
              isSelected: true,
              onPressed: () {},
            ),
          );
          final double on = tester.getSize(paintedMaterial()).width;

          expect(on, off, reason: 'the row reflows on selection');
        },
      );
    }
  });

  group('count', () {
    testWidgets('renders after the label with a visible numeral', (
      tester,
    ) async {
      await pump(
        tester,
        MxFilterChip(
          label: 'Decks',
          count: 3,
          isSelected: false,
          onPressed: () {},
        ),
      );

      expect(find.text('Decks'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('a null count renders no numeral and no extra gap', (
      tester,
    ) async {
      await pump(
        tester,
        MxFilterChip(label: 'Decks', isSelected: false, onPressed: () {}),
      );

      expect(find.text('3'), findsNothing);

      final double withoutCount = tester.getSize(paintedMaterial()).width;

      await pump(
        tester,
        MxFilterChip(
          label: 'Decks',
          count: 0,
          isSelected: false,
          onPressed: () {},
        ),
      );
      final double withZeroCount = tester.getSize(paintedMaterial()).width;

      expect(
        withZeroCount,
        greaterThan(withoutCount),
        reason: 'count: 0 must still render (and gap), unlike count: null',
      );
    });
  });

  group('layout', () {
    testWidgets('the tap target meets AppSizing.touchTarget both axes', (
      tester,
    ) async {
      await pump(
        tester,
        MxFilterChip(label: 'A', isSelected: false, onPressed: () {}),
      );

      final Size size = tester.getSize(find.byType(MxFilterChip));
      expect(size.width, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSizing.touchTarget));

      final handle = tester.ensureSemantics();
      final Rect semanticsRect = tester
          .getSemantics(find.byType(MxFilterChip))
          .rect;
      expect(semanticsRect.width, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(semanticsRect.height, greaterThanOrEqualTo(AppSizing.touchTarget));
      handle.dispose();
    });

    testWidgets('the painted pill is fixed at AppSizing.chipHeight', (
      tester,
    ) async {
      await pump(
        tester,
        MxFilterChip(label: 'A', isSelected: false, onPressed: () {}),
      );

      expect(tester.getSize(paintedMaterial()).height, AppSizing.chipHeight);
    });

    testWidgets(
      'a long label and a large count neither wrap, ellipsize nor shrink',
      (tester) async {
        const String shortLabel = 'All';
        const String longLabel =
            'A very long filter label that would never fit in a chip';

        Future<void> pumpScrolling(String label, int count) =>
            tester.pumpWidget(
              MaterialApp(
                theme: buildLightTheme(),
                home: Scaffold(
                  body: SizedBox(
                    width: 100,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: MxFilterChip(
                        label: label,
                        count: count,
                        isSelected: true,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            );

        await pumpScrolling(shortLabel, 1);
        final double shortChipWidth = tester.getSize(paintedMaterial()).width;
        final double oneLineHeight = tester
            .getSize(find.text(shortLabel))
            .height;

        await pumpScrolling(longLabel, 999999);

        expect(tester.takeException(), isNull);
        expect(find.text(longLabel), findsOneWidget);
        expect(find.text('999999'), findsOneWidget);
        // Not shrunk or ellipsized: the chip grew past the 100dp viewport
        // instead of squeezing into it.
        final double longChipWidth = tester.getSize(paintedMaterial()).width;
        expect(longChipWidth, greaterThan(shortChipWidth));
        expect(longChipWidth, greaterThan(100));
        // Not wrapped: the label is still exactly one line tall.
        expect(tester.getSize(find.text(longLabel)).height, oneLineHeight);
      },
    );
  });
}
