import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_elevation.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import 'card_specimens.dart';

/// `MxCard` at the widths a phone actually has.
///
/// **Why these four and not a golden.** The failure this file guards is
/// structural — a card that overflows, or whose box moves when it takes a
/// state — and a picture at one width cannot see it. Committing four widths of
/// PNG could, at the cost of four more pictures per change and a page that
/// claims one surface; `CLAUDE.md` is explicit that a render at another width
/// belongs to the test that measures it. This is that test.
///
/// 320 is the narrowest Android phone still shipping, 360 the median, 375 the
/// small-iPhone width the web channel is checked at, 393 the surface every
/// committed golden is shot on.
void main() {
  const List<double> widths = <double>[320, 360, 375, 393];

  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required double width,
    required bool isDark,
  }) async {
    tester.view.physicalSize = Size(width, 900) * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: child,
      ),
    );
    await tester.pumpAndSettle();
  }

  group('the card holds every phone width', () {
    for (final width in widths) {
      for (final isDark in <bool>[false, true]) {
        final mode = isDark ? 'dark' : 'light';

        testWidgets('${width.toInt()}dp $mode — the depth ladder and a '
            'three-card stack lay out', (tester) async {
          await pumpAt(
            tester,
            const CardDepthSpecimen(),
            width: width,
            isDark: isDark,
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(MxCard), findsNWidgets(6));
        });

        testWidgets('${width.toInt()}dp $mode — every state lays out', (
          tester,
        ) async {
          await pumpAt(
            tester,
            const CardStatesSpecimen(),
            width: width,
            isDark: isDark,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('a twelve-card list scrolls without overflowing', (
      tester,
    ) async {
      // The shape the glow was worst in, and the one no other test builds.
      await pumpAt(
        tester,
        Scaffold(
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, int i) => MxCard.raised(child: Text('Deck $i')),
          ),
        ),
        width: 320,
        isDark: true,
      );

      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('depth is paint, so the box never moves', () {
    /// The property M100.33 established and M100.35 must not undo: a card's
    /// bounds are the same whatever it is doing. The depth cue is a shadow or
    /// a ring painted outside the box, the state edges are foreground layers
    /// painted inside it, and none of the four participates in layout.
    Future<Rect> boxOf(WidgetTester tester, Widget card, bool isDark) async {
      await pumpAt(
        tester,
        Scaffold(
          body: Center(child: SizedBox(width: 200, child: card)),
        ),
        width: 360,
        isDark: isDark,
      );

      return tester.getRect(find.byType(MxCard));
    }

    for (final isDark in <bool>[false, true]) {
      final mode = isDark ? 'dark' : 'light';

      testWidgets('$mode: a state never changes the box it is painted on', (
        tester,
      ) async {
        // **Same recipe, different state — the comparison has to be that.**
        // Comparing `flat` against `option` measures the padding scale
        // (`standard` 16 against `compact` 12) and reports it as a state
        // defect. A fixed-height child rather than text for the same reason:
        // outside a `Material` a bare `Text` picks up `DefaultTextStyle`'s
        // fallback metrics instead of `bodyMedium`, and the tappable branch
        // introduces a `Material` — so a text child makes the harness, not the
        // card, decide the height.
        void noop() {}
        const child = SizedBox(height: 40, width: 120);

        final resting = await boxOf(
          tester,
          MxCard.flat(onTap: noop, child: child),
          isDark,
        );
        final selected = await boxOf(
          tester,
          MxCard.flat(isSelected: true, onTap: noop, child: child),
          isDark,
        );
        final tinted = await boxOf(
          tester,
          MxCard.flat(
            isSelected: true,
            selectionTreatment: MxCardSelectionTreatment.tint,
            onTap: noop,
            child: child,
          ),
          isDark,
        );

        expect(selected, resting);
        expect(tinted, resting);

        final option = await boxOf(
          tester,
          MxCard.option(isSelected: false, onTap: noop, child: child),
          isDark,
        );
        final picked = await boxOf(
          tester,
          MxCard.option(isSelected: true, onTap: noop, child: child),
          isDark,
        );
        final disabled = await boxOf(
          tester,
          const MxCard.option(isSelected: false, onTap: null, child: child),
          isDark,
        );

        expect(picked, option);
        expect(
          disabled.size,
          option.size,
          reason: 'a withheld handler changes the paint, never the geometry',
        );
      });

      testWidgets('$mode: the depth ladder does not resize a card', (
        tester,
      ) async {
        void noop() {}
        const child = SizedBox(height: 40, width: 120);
        final flat = await boxOf(
          tester,
          MxCard.flat(onTap: noop, child: child),
          isDark,
        );
        final raised = await boxOf(
          tester,
          MxCard.raised(onTap: noop, child: child),
          isDark,
        );

        expect(raised, flat);
      });
    }
  });

  group('dark depth is quiet enough to repeat', () {
    testWidgets('a list card paints one hairline and nothing else', (
      tester,
    ) async {
      // The regression in one line: `card` is the level a scrolling list uses,
      // and it may carry the rim alone. Anything more — a second layer, a
      // spread above one hairline — is the glow coming back.
      final dark = buildDarkTheme().colorScheme;
      final shadows = shadowsFor(AppElevation.card, dark);

      expect(shadows, hasLength(1));
      expect(shadows.single.color, dark.outlineVariant);
      expect(shadows.single.blurRadius, 0);
    });
  });
}
