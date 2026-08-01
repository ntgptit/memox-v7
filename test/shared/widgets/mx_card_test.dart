import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_interaction_states.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../support/ink_probe.dart';

/// `MxCard` — the app's one raised surface, and the tap it grew in M4.12.
///
/// Its own file because `mx_surface_components_test.dart` crossed the 400-line
/// guard when these were added to it. The seam is clean: nothing here touches the
/// other surface components.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          // `copyWith`, never a fresh `MediaQueryData`: constructing one
          // zeroes `size`, `padding` and `viewInsets`, so the widget under
          // test is told the screen is 0x0 while `tester.view` says
          // otherwise. Anything that reads the width then branches on a
          // number no device reports.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.pump();
  }

  const long =
      'A deck name long enough that it has to wrap or be cut off, twice over';

  /// The card's own border, which is where its focus indicator lives — the ring
  /// replaces the hairline rather than being added beside it, so reading this
  /// one value answers both "is the ring drawn" and "did the geometry move".
  BorderSide borderOf(WidgetTester tester) {
    final decorated = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    return ((decorated.decoration as BoxDecoration).border! as Border).top;
  }

  /// Tab, from a real keyboard. Focus that is only ever set programmatically
  /// proves the indicator renders and not that anybody can reach it.
  Future<void> tabTo(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }

  group('MxCard', () {
    testWidgets('is a plain surface without onTap', (tester) async {
      // The default has to stay inert: most cards are panels, and one that
      // announced itself as a button would put a control in every screen reader's
      // path for every panel in the app.
      await pump(tester, const MxCard(child: Text('Academic Word List')));

      expect(find.byType(InkWell), findsNothing);
      expect(find.text('Academic Word List'), findsOneWidget);
    });

    testWidgets('the whole surface is the target when tappable', (
      tester,
    ) async {
      // Tapping the padding, not the text. A card that only responded on its
      // child would be a bigger target visually than it is in fact, which is the
      // hardest kind of miss to notice.
      var taps = 0;
      await pump(
        tester,
        MxCard(onTap: () => taps += 1, child: const Text(long)),
      );

      final card = tester.getRect(find.byType(MxCard));
      await tester.tapAt(Offset(card.left + 4, card.top + 4));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('a tappable card announces itself as a button', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxCard(onTap: () {}, child: const Text('Academic Word List')),
      );

      // No `hasEnabledState`. `MxCard` has no disabled variant — the card is
      // either tappable or it is a plain surface with no semantics at all — so
      // announcing an enabled state would describe a distinction that does not
      // exist. What has to be there is the button flag: an `InkWell` alone
      // contributes a tap action and focusability, and a screen reader would read
      // the card's text without ever saying it can be activated.
      expect(
        tester.getSemantics(find.byType(InkWell)),
        matchesSemantics(
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('its ink layer sits above the surface paint', (tester) async {
      // Paint order, asserted structurally because it cannot be seen any other
      // way in a widget test. `_RenderInkFeatures` draws splashes and the hover
      // highlight and *then* draws its child, so an `InkWell` wrapped around the
      // `DecoratedBox` puts every state underneath an opaque surface colour — a
      // tappable card with no feedback at all. The ink has to be inside the
      // decoration, with only the padding and the content below it.
      await pump(
        tester,
        MxCard(onTap: () {}, child: const Text('Academic Word List')),
      );

      final inCard = find.descendant(
        of: find.byType(MxCard),
        matching: find.byType(DecoratedBox),
      );
      expect(
        find.descendant(of: inCard, matching: find.byType(InkWell)),
        findsOneWidget,
        reason: 'the ink is painted over the surface, not under it',
      );
      expect(
        find.descendant(of: find.byType(InkWell), matching: inCard),
        findsNothing,
        reason: 'no opaque surface may sit between the ink and the eye',
      );
    });

    testWidgets('a control inside a tappable card keeps its own tap', (
      tester,
    ) async {
      // The reason the whole card can be the target at all. A deck card carries
      // an overflow menu, and a card that swallowed it would force the caller to
      // make a *region* of itself tappable instead — which leaves the rest of the
      // card looking tappable and inert. The nested button wins the gesture arena
      // over the card's ink; nothing else is needed to keep them apart.
      var cardTaps = 0;
      var buttonTaps = 0;
      await pump(
        tester,
        MxCard(
          onTap: () => cardTaps += 1,
          child: TextButton(
            onPressed: () => buttonTaps += 1,
            child: const Text('Actions'),
          ),
        ),
      );

      await tester.tap(find.text('Actions'));
      await tester.pump();

      expect(buttonTaps, 1);
      expect(cardTaps, 0, reason: 'the card must not fire as well');
    });

    testWidgets('a card with no onTap never becomes interactive', (
      tester,
    ) async {
      // The other half of the default. A plain panel must not enter the focus
      // order, and it must not paint a state layer when a pointer crosses it —
      // a surface that lights up under the mouse and does nothing when clicked
      // is worse than one that never reacts.
      await pump(tester, const MxCard(child: Text('Academic Word List')));
      final atRest = borderOf(tester);

      await hover(tester, find.byType(MxCard));
      await tabTo(tester);

      expect(find.byType(InkWell), findsNothing);
      expect(
        borderOf(tester),
        atRest,
        reason: 'a plain panel took a focus ring, or a hover state',
      );
    });

    testWidgets('its contents are what name it', (tester) async {
      // There is no `semanticLabel` parameter, deliberately: the card's children
      // already say what it is, and an override would replace them rather than
      // add to them. This asserts the name survives the ink layer.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxCard(onTap: () {}, child: const Text('Academic Word List')),
      );

      expect(find.bySemanticsLabel('Academic Word List'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MxCard interaction states', () {
    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      final label = mode.$1;
      final isDark = mode.$2;

      testWidgets('$label · hover paints the card wash, exit clears it', (
        tester,
      ) async {
        // A real mouse, and both directions. Before this the card declared no
        // interaction colours at all, so hover came from `ThemeData.hoverColor`
        // — a hardcoded black wash with no seed in it and the same value in
        // both modes.
        await pump(
          tester,
          MxCard(onTap: () {}, child: const Text(long)),
          isDark: isDark,
        );
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final wash = AppInteractionStates.cardOverlay(
          theme.colorScheme,
        ).resolve(const <WidgetState>{WidgetState.hovered})!;

        final gesture = await hover(tester, find.byType(MxCard));
        expectInkColor(tester, wash, reason: '$label: hover paints nothing');

        // Below the card, not to the origin: the card is flush with the top of
        // the body, so (0, 0) is still inside it and the "pointer left" half of
        // this test would never run.
        await gesture.moveTo(
          tester.getBottomRight(find.byType(MxCard)) + const Offset(0, 40),
        );
        await tester.pumpAndSettle();

        expectNoInkColor(
          tester,
          wash,
          reason: '$label: the card kept its hover after the pointer left',
        );
      });

      testWidgets('$label · pressing changes no geometry', (tester) async {
        // The design's own rule: "nothing scales, nothing shrinks". A press
        // that resizes the card moves every card under it in the list.
        await pump(
          tester,
          MxCard(onTap: () {}, child: const Text(long)),
          isDark: isDark,
        );
        final atRest = tester.getRect(find.byType(MxCard));
        final borderAtRest = borderOf(tester);

        final press = await tester.startGesture(
          tester.getCenter(find.byType(MxCard)),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(tester.getRect(find.byType(MxCard)), atRest);
        expect(borderOf(tester), borderAtRest);

        await press.up();
        await tester.pumpAndSettle();
      });

      testWidgets('$label · keyboard focus draws the ring, and costs nothing', (
        tester,
      ) async {
        await pump(
          tester,
          MxCard(onTap: () {}, child: const Text(long)),
          isDark: isDark,
        );
        final atRest = tester.getRect(find.byType(MxCard));
        expect(borderOf(tester).width, AppStroke.hairline);

        await tabTo(tester);

        expect(
          borderOf(tester).width,
          AppStroke.focus,
          reason: '$label: focus is invisible on a card',
        );
        // Read through the helper rather than naming a role. Pinning
        // `colorScheme.primary` here is what let the ring ship at 2.90:1 on a
        // card in dark — a test written from the value it found agrees with the
        // bug. `focus_ring_contrast_test.dart` measures it per ground.
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        expect(
          borderOf(tester).color,
          AppInteractionStates.focusRing(
            theme.extension<AppSemanticColors>()!,
          ).color,
        );
        expect(
          tester.getRect(find.byType(MxCard)),
          atRest,
          reason: '$label: the ring pushed the card around',
        );
      });
    }

    testWidgets('the keyboard activates it, not just the pointer', (
      tester,
    ) async {
      // An `InkWell` maps Enter and Space onto its own tap, and that is the
      // only path a keyboard user has to a card. Asserting it here means the
      // card cannot lose it to a future wrapper that eats key events.
      var taps = 0;
      await pump(
        tester,
        MxCard(onTap: () => taps += 1, child: const Text(long)),
      );

      await tabTo(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 2);
    });
  });
}
