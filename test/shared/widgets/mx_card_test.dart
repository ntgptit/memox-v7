import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_card.dart';

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
}
