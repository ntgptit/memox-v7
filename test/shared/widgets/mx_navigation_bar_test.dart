import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

/// `MxNavigationBar` on its own, with no router and no feature behind it.
///
/// That isolation is the point of the widget: if any of these needed a
/// `GoRouter`, a `ProviderScope` or a deck, the component would have stopped
/// being shared. The wiring to real branches is asserted in
/// `test/app/router/app_router_test.dart` instead.
void main() {
  const decksLabel = 'Decks';
  const reviewLabel = 'Review';

  /// The two destinations the app ships, built the same way the shell builds
  /// them: an outlined icon when idle and a filled one when selected.
  List<NavigationDestination> destinations() => const <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: decksLabel,
    ),
    NavigationDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: reviewLabel,
    ),
  ];

  Future<List<int>> pumpBar(
    WidgetTester tester, {
    int selectedIndex = 0,
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
  }) async {
    final taps = <int>[];

    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Builder(
          // `copyWith`, never a fresh `MediaQueryData`: constructing one zeroes
          // `size`, `padding` and `viewInsets`, so the widget under test is
          // told the screen is 0x0 while `tester.view` says otherwise.
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: MxNavigationBar(
                selectedIndex: selectedIndex,
                onDestinationSelected: taps.add,
                destinations: destinations(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return taps;
  }

  group('rendering', () {
    testWidgets('shows every destination, label included', (tester) async {
      await pumpBar(tester);

      expect(find.text(decksLabel), findsOneWidget);
      expect(find.text(reviewLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('it is the Material 3 bar, not the legacy one', (tester) async {
      // The legacy `BottomNavigationBar` has its own colour and elevation model
      // that ignores the M3 `ColorScheme`, so a swap would silently need
      // hardcoded colours to look right again.
      await pumpBar(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsNothing);
    });

    testWidgets('labels stay visible on the unselected destination too', (
      tester,
    ) async {
      // The M3 default hides unselected labels, which leaves selection readable
      // as a colour difference and one floating word. The decision lives in
      // `navigationBarTheme` — one spelling — so the widget passes nothing and
      // the *effective* behaviour is what must hold, resolved the same way
      // `NavigationBar` resolves it.
      await pumpBar(tester);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      final context = tester.element(find.byType(NavigationBar));
      final effective =
          bar.labelBehavior ?? NavigationBarTheme.of(context).labelBehavior;

      expect(effective, NavigationDestinationLabelBehavior.alwaysShow);
    });
  });

  group('selection', () {
    testWidgets('index 0 marks Decks with the filled icon', (tester) async {
      await pumpBar(tester);

      // Asserting the icon, not the colour: the icon swap is the non-colour
      // signal that tells a colour-blind user which tab is current.
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsNothing);
      expect(find.byIcon(Icons.school_outlined), findsOneWidget);
      expect(find.byIcon(Icons.school), findsNothing);
    });

    testWidgets('index 1 marks Review with the filled icon', (tester) async {
      await pumpBar(tester, selectedIndex: 1);

      expect(find.byIcon(Icons.school), findsOneWidget);
      expect(find.byIcon(Icons.school_outlined), findsNothing);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsNothing);
    });
  });

  group('interaction', () {
    testWidgets('tapping a destination reports its index', (tester) async {
      final taps = await pumpBar(tester);

      await tester.tap(find.text(reviewLabel));
      await tester.pumpAndSettle();

      expect(taps, <int>[1]);
    });

    testWidgets('tapping the selected destination still reports it', (
      tester,
    ) async {
      // The bar must not swallow a re-selection. The shell turns it into
      // "pop this branch back to its root", and a bar that filtered it out
      // would make that behaviour unreachable.
      final taps = await pumpBar(tester);

      await tester.tap(find.text(decksLabel));
      await tester.pumpAndSettle();

      expect(taps, <int>[0]);
    });

    testWidgets('it never navigates by itself', (tester) async {
      // The whole contract of a render-only component: without a listener
      // acting on the callback, a tap changes nothing.
      final taps = await pumpBar(tester);

      await tester.tap(find.text(reviewLabel));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(taps, <int>[1]);
    });
  });

  group('accessibility', () {
    testWidgets('each destination is reachable by its label', (tester) async {
      await pumpBar(tester);

      expect(find.bySemanticsLabel(RegExp(decksLabel)), findsWidgets);
      expect(find.bySemanticsLabel(RegExp(reviewLabel)), findsWidgets);
    });

    testWidgets('every destination meets the tap-target guideline', (
      tester,
    ) async {
      // Disposed inline, not through `addTearDown`: the framework verifies that
      // no handle is outstanding *before* tear-downs run, so a deferred dispose
      // fails the test it was meant to clean up after.
      final handle = tester.ensureSemantics();

      await pumpBar(tester);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('labels stay legible against the bar', (tester) async {
      final handle = tester.ensureSemantics();

      await pumpBar(tester);

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });
  });

  group('light and dark', () {
    testWidgets('both themes build without an exception', (tester) async {
      for (final isDark in <bool>[false, true]) {
        await pumpBar(tester, isDark: isDark);

        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('responsive', () {
    const compact = Size(320, 568);

    testWidgets('fits the smallest supported screen', (tester) async {
      await pumpBar(tester, surface: compact);

      expect(find.text(decksLabel), findsOneWidget);
      expect(find.text(reviewLabel), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives textScaler 2.0 on that screen', (tester) async {
      // Material clamps the bar's own label scaling internally, so the bar does
      // not grow without bound. This asserts that it actually holds — if a
      // future Flutter drops the clamp, the bar overflows and this fails.
      await pumpBar(tester, surface: compact, textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps its height when the selection moves', (tester) async {
      // A bar that resizes on tab change shifts the content above it, so the
      // screen appears to jump at the exact moment the user is looking at it.
      await pumpBar(tester, surface: compact);
      final atDecks = tester.getSize(find.byType(NavigationBar));

      await pumpBar(tester, selectedIndex: 1, surface: compact);
      final atReview = tester.getSize(find.byType(NavigationBar));

      expect(atReview, atDecks);
    });
  });
}
