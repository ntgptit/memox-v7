import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../support/ink_probe.dart';

/// `MxCard`'s interaction states — hover, press, keyboard focus, long-press,
/// and the 48dp floor.
///
/// Split from `mx_card_test.dart` at the guard's 400-line mark when the
/// closed-API pass added the long-press and focus-mode claims; the fixture is
/// the same and the seam is by concern, not by accident.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  const long =
      'A deck name long enough that it has to wrap or be cut off, twice over';

  /// The card's own border, which is where its focus indicator lives — the
  /// ring replaces the hairline rather than being added beside it, so reading
  /// this one value answers both "is the ring drawn" and "did the geometry
  /// move".
  /// The topmost edge the card paints, or `null` when it paints none.
  ///
  /// **Foreground layers since M100.33.** The card used to carry its edge in
  /// the background decoration — and an invisible `Border.all(color: fill)`
  /// when it had no edge to show — so "the first `DecoratedBox`" always had a
  /// border and the resting width was a hairline. The fill sits behind the
  /// child now and every edge in front of it, so a card with nothing to say
  /// paints no border at all.
  BorderSide? borderOf(WidgetTester tester) {
    final borders = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(MxCard),
            matching: find.byType(DecoratedBox),
          ),
        )
        .where(
          (DecoratedBox box) => box.position == DecorationPosition.foreground,
        )
        .map((DecoratedBox box) => (box.decoration as BoxDecoration).border)
        .whereType<Border>()
        .toList();

    return borders.isEmpty ? null : borders.first.top;
  }

  /// Tab, from a real keyboard. Focus that is only ever set programmatically
  /// proves the indicator renders and not that anybody can reach it.
  Future<void> tabTo(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
  }

  group('MxCard interaction states', () {
    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      final label = mode.$1;
      final isDark = mode.$2;

      testWidgets('$label · hover paints the card wash, exit clears it', (
        tester,
      ) async {
        // A real mouse, and both directions. Before this the card declared no
        // interaction colours at all, so hover came from
        // `ThemeData.hoverColor` — a hardcoded black wash with no seed in it
        // and the same value in both modes.
        await pump(
          tester,
          MxCard.raised(onTap: () {}, child: const Text(long)),
          isDark: isDark,
        );
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        final wash = AppInteractionStates.cardOverlay(
          theme.colorScheme,
        ).resolve(const <WidgetState>{WidgetState.hovered})!;

        final gesture = await hover(tester, find.byType(MxCard));
        expectInkColor(tester, wash, reason: '$label: hover paints nothing');

        // Below the card, not to the origin: the card is flush with the top
        // of the body, so (0, 0) is still inside it and the "pointer left"
        // half of this test would never run.
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
          MxCard.raised(onTap: () {}, child: const Text(long)),
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
          MxCard.raised(onTap: () {}, child: const Text(long)),
          isDark: isDark,
        );
        final atRest = tester.getRect(find.byType(MxCard));
        // Nothing at rest: an ordinary card is a surface, not a frame.
        expect(borderOf(tester), isNull);

        await tabTo(tester);

        expect(
          borderOf(tester)?.width,
          AppStroke.focus,
          reason: '$label: focus is invisible on a card',
        );
        // Read through the helper rather than naming a role. Pinning
        // `colorScheme.primary` here is what let the ring ship at 2.90:1 on a
        // card in dark — a test written from the value it found agrees with
        // the bug. `focus_ring_contrast_test.dart` measures it per ground.
        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        expect(
          borderOf(tester)!.color,
          AppInteractionStates.focusIndicator(theme.colorScheme).color,
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
        MxCard.raised(onTap: () => taps += 1, child: const Text(long)),
      );

      await tabTo(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(taps, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(taps, 2);
    });

    testWidgets('a long-press-only card still reaches its callback', (
      tester,
    ) async {
      // The defect this pins: the first closed-API pass built the ink layer
      // from `onTap` alone, so `onLongPress` without a tap fell into the
      // inert branch — the callback existed and could never fire.
      var longPresses = 0;
      await pump(
        tester,
        MxCard.flat(
          onLongPress: () => longPresses += 1,
          child: const Text(long),
        ),
      );

      await tester.longPress(find.byType(MxCard));
      await tester.pumpAndSettle();
      expect(longPresses, 1);
    });

    testWidgets('a long-press-only card does not announce as a button', (
      tester,
    ) async {
      // Deliberate: `button: true` promises an activation, and this surface
      // has none — a screen reader told "button" would tap and get nothing.
      // The long-press action still reaches assistive tech through the
      // InkWell's own node.
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        MxCard.flat(onLongPress: () {}, child: const Text(long)),
      );

      // `matchesSemantics` is exact: leaving `isButton` unstated asserts the
      // flag is absent, which is the claim.
      expect(
        tester.getSemantics(find.byType(InkWell)),
        matchesSemantics(
          isFocusable: true,
          hasFocusAction: true,
          hasLongPressAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('tap and long-press coexist on one surface', (tester) async {
      var taps = 0;
      var longPresses = 0;
      await pump(
        tester,
        MxCard.flat(
          onTap: () => taps += 1,
          onLongPress: () => longPresses += 1,
          child: const Text(long),
        ),
      );

      await tester.tap(find.byType(MxCard));
      await tester.pump();
      await tester.longPress(find.byType(MxCard));
      await tester.pumpAndSettle();

      expect(taps, 1);
      expect(longPresses, 1);
    });

    testWidgets('focus without a keyboard draws no ring', (tester) async {
      // The gate `MxActionButton._takesFocus` applies, on the card's own
      // ring: focus that arrives in touch mode — programmatic, or a platform
      // quirk — must not paint a keyboard affordance (M99.75's autofocus bug,
      // one component over).
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTouch;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      await pump(tester, MxCard.raised(onTap: () {}, child: const Text(long)));

      // From the child's context, so `Focus.of` finds the InkWell's own node
      // above it rather than asking the InkWell for an ancestor it lacks.
      final focusNode = Focus.of(tester.element(find.text(long)));
      focusNode.requestFocus();
      await tester.pumpAndSettle();

      expect(focusNode.hasFocus, isTrue);
      expect(
        borderOf(tester),
        isNull,
        reason: 'touch-mode focus painted the keyboard ring',
      );

      // The same focus, once a keyboard exists: the listener repaints the
      // ring without the focus having to move again.
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      await tester.pumpAndSettle();
      expect(borderOf(tester)!.width, AppStroke.focus);
    });

    testWidgets('an interactive card keeps the 48dp floor structurally', (
      tester,
    ) async {
      // Not an accident of the padding: `none` plus a tiny child is the
      // arrangement that used to fall under the target a finger needs.
      await pump(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: MxCard.flat(
            padding: MxCardPadding.none,
            onTap: () {},
            child: const SizedBox(width: 10, height: 10),
          ),
        ),
      );

      final card = tester.getSize(find.byType(MxCard));
      expect(card.width, greaterThanOrEqualTo(AppSizing.touchTarget));
      expect(card.height, greaterThanOrEqualTo(AppSizing.touchTarget));
    });
  });

  group('the edge layers (M100.33)', () {
    /// Tab onto the only focusable thing on screen.
    Future<void> tab(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }

    testWidgets('focus changes no bound, on the card or on its content', (
      tester,
    ) async {
      // **The claim the old fake border existed to protect, now measured.**
      // `MxCard` drew `Border.all(color: fill)` at rest so the box would not
      // "breathe" when the ring arrived — an argument that holds for
      // `Container`, which adds `decoration.padding` to its child, and not for
      // `DecoratedBox`, which paints and nothing else. The border reserved no
      // geometry, so removing it can move nothing; this is the proof rather
      // than the comment.
      await pump(
        tester,
        MxCard.raised(onTap: () {}, child: const Text('body')),
      );

      final Size before = tester.getSize(find.byType(MxCard));
      final Rect contentBefore = tester.getRect(find.text('body'));

      await tab(tester);

      expect(tester.getSize(find.byType(MxCard)), before);
      expect(tester.getRect(find.text('body')), contentBefore);
    });

    testWidgets('an edge-to-edge child cannot cover the selected edge', (
      tester,
    ) async {
      // A card whose content reaches every corner used to paint over its own
      // state edge, because the edge lived in the decoration *behind* the
      // child. A selected row with a full-bleed child then showed no selection
      // at all. The edge is a foreground layer now, so the child owns the whole
      // content area and the state still reads.
      await pump(
        tester,
        MxCard.flat(
          isSelected: true,
          padding: MxCardPadding.none,
          child: Container(
            width: 200,
            height: 80,
            color: const Color(0xFF123456),
          ),
        ),
      );

      final edges = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (DecoratedBox box) =>
                box.position == DecorationPosition.foreground &&
                (box.decoration as BoxDecoration).border != null,
          );

      expect(
        edges,
        isNotEmpty,
        reason: 'the selected edge is not painted in front of the child',
      );
    });

    testWidgets('focus is additive: a selected card keeps its selection', (
      tester,
    ) async {
      // One channel used to carry two facts — the ring *replaced* the resting
      // edge — so tabbing onto a selected card removed the cue that said it was
      // picked. Both layers are present now, and both are asserted.
      await pump(
        tester,
        MxCard.flat(isSelected: true, onTap: () {}, child: const Text('body')),
      );
      await tab(tester);

      final borders = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .where(
            (DecoratedBox box) => box.position == DecorationPosition.foreground,
          )
          .map((DecoratedBox box) => (box.decoration as BoxDecoration).border)
          .whereType<Border>()
          .map((Border border) => border.top)
          .toList();

      final theme = buildLightTheme();
      final ring = AppInteractionStates.focusIndicator(theme.colorScheme);
      final selected = theme.extension<AppSemanticColors>()!.borderSelected;

      expect(
        borders.map((BorderSide side) => side.color),
        containsAll(<Color>[ring.color, selected]),
        reason: 'focus and selection are not both on screen',
      );
      expect(
        borders.map((BorderSide side) => side.width),
        contains(AppStroke.focus),
      );
    });
  });
}
