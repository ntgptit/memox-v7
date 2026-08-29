import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_semantic_colors.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../support/ink_probe.dart';

/// `MxCard` — surface, selection and semantics claims.
///
/// Split twice at the guard's 400-line mark: first out of
/// `mx_surface_components_test.dart` (M4.12), then the interaction-state group
/// moved to `mx_card_interaction_test.dart` when the closed-API pass (M99.83)
/// added the long-press and focus-mode claims.
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
      await pump(
        tester,
        const MxCard.raised(child: Text('Academic Word List')),
      );

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
        MxCard.raised(onTap: () => taps += 1, child: const Text(long)),
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
        MxCard.raised(onTap: () {}, child: const Text('Academic Word List')),
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
        MxCard.raised(onTap: () {}, child: const Text('Academic Word List')),
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
        MxCard.raised(
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
      await pump(
        tester,
        const MxCard.raised(child: Text('Academic Word List')),
      );
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
        MxCard.raised(onTap: () {}, child: const Text('Academic Word List')),
      );

      expect(find.bySemanticsLabel('Academic Word List'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MxCard selection', () {
    for (final isDark in <bool>[false, true]) {
      testWidgets('selected wears secondary, in ${isDark ? 'dark' : 'light'}', (
        tester,
      ) async {
        // The token is the contract: `primary` was tried at a call site and
        // measured 2.90:1 in dark — the widget owns the answer now so no
        // sheet can hold a second opinion.
        await pump(
          tester,
          MxCard.raised(
            isSelected: true,
            onTap: () {},
            child: const Text(long),
          ),
          isDark: isDark,
        );

        final semantic = (isDark ? buildDarkTheme() : buildLightTheme())
            .extension<AppSemanticColors>()!;
        // **`borderSelected`, not `secondary`** (M99.99). The slate edge sat at
        // chroma 0.0337 around a fill M99.98 had just made brand-tinted.
        expect(borderOf(tester).color, semantic.borderSelected);
      });
    }

    testWidgets('an option rests at the control edge until it is selected', (
      tester,
    ) async {
      // The resting `borderControl` used to be a caller-passed colour; the
      // option recipe owns it now, so an unpicked option still reads as a
      // control and a picked one still wins with `borderSelected`.
      final semantic = buildLightTheme().extension<AppSemanticColors>()!;
      await pump(
        tester,
        MxCard.option(isSelected: false, onTap: () {}, child: const Text(long)),
      );

      expect(borderOf(tester).color, semantic.borderControl);

      await pump(
        tester,
        MxCard.option(isSelected: true, onTap: () {}, child: const Text(long)),
      );
      expect(borderOf(tester).color, semantic.borderSelected);
    });

    testWidgets('tri-state semantics: null says nothing, false and true '
        'are both announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        Column(
          children: <Widget>[
            MxCard.raised(onTap: () {}, child: const Text('plain')),
            MxCard.raised(
              isSelected: false,
              onTap: () {},
              child: const Text('off'),
            ),
            MxCard.raised(
              isSelected: true,
              onTap: () {},
              child: const Text('on'),
            ),
          ],
        ),
      );

      final plain = tester.getSemantics(find.text('plain'));
      expect(plain.flagsCollection.isSelected, Tristate.none);
      final off = tester.getSemantics(find.text('off'));
      expect(off.flagsCollection.isSelected, Tristate.isFalse);
      final on = tester.getSemantics(find.text('on'));
      expect(on.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('a non-tappable selected card is still announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const MxCard.flat(isSelected: true, child: Text('picked')),
      );

      final node = tester.getSemantics(find.text('picked'));
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });
  });

  group('MxCard.flat', () {
    testWidgets('is the no-shadow card', (tester) async {
      // Seventeen call sites spelled `elevation: AppElevation.none`; the
      // constructor is that sentence said once. Same surface, same border,
      // no shadow list.
      await pump(tester, const MxCard.flat(child: Text(long)));

      final decorated = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxCard),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        (decorated.decoration as BoxDecoration).boxShadow,
        anyOf(isNull, isEmpty),
      );
    });
  });
}
