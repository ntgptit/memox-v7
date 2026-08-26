import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

/// `MxBreadcrumb` — the app's "where am I, and how do I get back up" control.
///
/// Three properties carry the whole design and each is asserted below rather than
/// argued for in prose: the last step is not a control, a deep path cannot
/// overflow, and every step that *is* a control announces itself as one.
void main() {
  Future<void> pump(
    WidgetTester tester,
    List<MxBreadcrumbItem> items, {
    String? semanticLabel,
    Size surface = const Size(400, 200),
    double textScale = 1,
    bool isDark = false,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: MxBreadcrumb(items: items, semanticLabel: semanticLabel),
          ),
        ),
      ),
    );
  }

  List<MxBreadcrumbItem> path(int depth, {void Function(int)? onTap}) =>
      <MxBreadcrumbItem>[
        for (var i = 0; i < depth; i++)
          MxBreadcrumbItem(
            label: 'Level $i',
            // The last step is where the user already is.
            onTap: i == depth - 1 ? null : () => onTap?.call(i),
          ),
      ];

  group('what it renders', () {
    testWidgets('every step is shown, in order', (tester) async {
      await pump(tester, path(3));

      expect(find.text('Level 0'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
    });

    testWidgets('a separator sits between steps and not at the ends', (
      tester,
    ) async {
      await pump(tester, path(3));

      // A slash, not a chevron (owner review, 2026-08-21): the header's back
      // affordance owns the only arrow on the line.
      expect(find.text('/'), findsNWidgets(2));
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('an empty path renders nothing at all', (tester) async {
      // Not an empty bar. A caller with nothing to show must cost no vertical
      // space, because the alternative is a blank strip above every root list.
      await pump(tester, const <MxBreadcrumbItem>[]);

      expect(find.text('/'), findsNothing);
      expect(
        tester.getSize(find.byType(MxBreadcrumb)),
        const Size(0, 0),
        reason: 'an empty breadcrumb must occupy no space',
      );
    });
  });

  group('interaction', () {
    testWidgets('tapping an ancestor reports that step', (tester) async {
      final tapped = <int>[];
      await pump(tester, path(3, onTap: tapped.add));

      await tester.tap(find.text('Level 0'));
      await tester.pump();

      expect(tapped, <int>[0]);
    });

    testWidgets('the current step is not tappable', (tester) async {
      // The property the whole widget turns on: a path terminates, and its last
      // element is a statement rather than a control that would navigate to the
      // screen you are already looking at.
      final tapped = <int>[];
      await pump(tester, path(3, onTap: tapped.add));

      await tester.tap(find.text('Level 2'), warnIfMissed: false);
      await tester.pump();

      expect(tapped, isEmpty);
    });
  });

  group('a step is a link, not a button', () {
    /// Puts a mouse pointer on [label] and leaves it there.
    Future<void> hover(WidgetTester tester, String label) async {
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text(label)));
      await tester.pumpAndSettle();
    }

    TextStyle styleOf(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!;

    testWidgets('rests quiet, with nothing under it', (tester) async {
      await pump(tester, path(3));

      final style = styleOf(tester, 'Level 0');
      expect(style.decoration, isNot(TextDecoration.underline));
      expect(
        style.color,
        buildLightTheme().colorScheme.onSurfaceVariant,
        reason: 'a path is chrome, not a heading',
      );
    });

    testWidgets('hovering moves the label, not a surface behind it', (
      tester,
    ) async {
      // The whole point of the change. An `InkWell` highlight drew a filled
      // rounded chip behind each word, and four of those in a row read as a
      // toolbar of buttons rather than as a path. Asserted on the label because
      // that is where the state now lives — if a surface ever comes back, this
      // test keeps passing, so `overlayColor` is suppressed in the widget and
      // the ink layer has nothing to paint.
      await pump(tester, path(3));
      await hover(tester, 'Level 0');

      final style = styleOf(tester, 'Level 0');
      expect(style.decoration, TextDecoration.underline);
      expect(style.color, buildLightTheme().colorScheme.onSurface);
      expect(
        style.decorationColor,
        style.color,
        reason: 'the rule must not disagree with the word it belongs to',
      );
    });

    testWidgets('the step the user is on never reacts', (tester) async {
      await pump(tester, path(3));
      await hover(tester, 'Level 2');

      final style = styleOf(tester, 'Level 2');
      expect(style.decoration, isNot(TextDecoration.underline));
      expect(style.color, buildLightTheme().colorScheme.onSurfaceVariant);
    });
  });

  group('semantics', () {
    testWidgets('an ancestor announces itself as a button', (tester) async {
      // An `InkWell` contributes a tap action and focusability but **not** the
      // button flag, so without the explicit annotation a reader names the step
      // and never says it can be activated.
      final handle = tester.ensureSemantics();
      await pump(tester, path(2));

      expect(
        tester.getSemantics(find.text('Level 0')),
        matchesSemantics(
          label: 'Level 0',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the current step is not announced as a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, path(2));

      expect(
        tester.getSemantics(find.text('Level 1')),
        matchesSemantics(label: 'Level 1'),
      );

      handle.dispose();
    });

    testWidgets('the strip carries its group label without swallowing steps', (
      tester,
    ) async {
      // `explicitChildNodes` is what makes this work. Without it the container
      // label replaces the children and a reader hears "Deck path" with no way
      // to reach the steps inside it.
      final handle = tester.ensureSemantics();
      await pump(tester, path(2), semanticLabel: 'Deck path');

      expect(find.bySemanticsLabel('Deck path'), findsOneWidget);
      expect(find.bySemanticsLabel('Level 0'), findsOneWidget);

      handle.dispose();
    });

    testWidgets('the separators are not announced', (tester) async {
      // Punctuation. A reader saying "chevron right" nine times on a deep path
      // is noise the user has to sit through.
      final handle = tester.ensureSemantics();
      await pump(tester, path(3));

      expect(find.bySemanticsLabel(RegExp('chevron')), findsNothing);

      handle.dispose();
    });
  });

  group('a path as deep as the tree allows', () {
    // BR-55 caps the deck tree at 10 levels, so 10 is the worst real case.
    testWidgets('does not overflow at 320 wide', (tester) async {
      await pump(tester, path(10), surface: const Size(320, 568));

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at 320 wide with textScaler 2.0', (
      tester,
    ) async {
      await pump(tester, path(10), surface: const Size(320, 568), textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('opens at its left end, not its deep one', (tester) async {
      // It used to jump to the deep end on arrival. The fold made that
      // unnecessary — first · fold · last two already puts the deep end on
      // screen — and the jump cost the thing a path is read for: where it
      // begins. Measured on the scroll position, because "it looks left-aligned"
      // and "it is scrolled to 0" are the same claim only if nobody scrolls it.
      await pump(tester, path(10), surface: const Size(320, 568));

      expect(
        tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
        0,
      );
      expect(find.text('Level 0'), findsOneWidget);
    });

    testWidgets('scrolls rather than truncating', (tester) async {
      // The claim the design rests on: nothing is hidden, it is just off to the
      // right. A collapsing implementation would drop the middle steps, which
      // are exactly what a user opens a breadcrumb to find.
      final tapped = <int>[];
      await pump(
        tester,
        path(10, onTap: tapped.add),
        surface: const Size(320, 568),
      );

      await tester.drag(find.byType(MxBreadcrumb), const Offset(-600, 0));
      await tester.pump();
      await tester.tap(find.text('Level 8'));
      await tester.pump();

      expect(tapped, <int>[8]);
    });

    testWidgets('builds under the dark theme', (tester) async {
      await pump(tester, path(10), isDark: true);

      expect(tester.takeException(), isNull);
    });
  });

  group('touch targets', () {
    testWidgets('every tappable step clears the minimum', (tester) async {
      // A row of names with hot spots in it is not a control. Each step is its
      // own target, and the guideline minimum is the floor.
      await pump(tester, path(3));

      for (final String label in <String>['Level 0', 'Level 1']) {
        expect(
          tester.getSize(find.byType(InkWell).at(0)).height,
          greaterThanOrEqualTo(AppSpacing.minimumTouchTarget),
          reason: '$label must be at least a minimum target tall',
        );
      }
    });
  });

  group('the header form folds instead of clipping', () {
    /// The header variant: one target, a back chevron, a home glyph.
    Future<void> pumpHeader(
      WidgetTester tester,
      List<String> labels, {
      required double width,
      double textScale = 1,
    }) async {
      tester.view.physicalSize = Size(width, 200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(
            // `copyWith`, never a fresh `MediaQueryData` — the same trap
            // `mx_button_pair_test` records: constructing one zeroes `size`,
            // and this widget measures its own line.
            body: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(textScale)),
                child: MxBreadcrumb(
                  lineHeight: MxBreadcrumb.compactLineHeight,
                  upIcon: Icons.chevron_left,
                  rootIcon: Icons.home_outlined,
                  onUp: () {},
                  items: <MxBreadcrumbItem>[
                    for (final label in labels) MxBreadcrumbItem(label: label),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    /// Labels the renderer had to cut off.
    List<String> clipped(WidgetTester tester) {
      final paragraphs = find.byType(RichText);

      return <String>[
        for (var index = 0; index < paragraphs.evaluate().length; index++)
          if (tester
              .renderObject<RenderParagraph>(paragraphs.at(index))
              .didExceedMaxLines)
            tester
                .renderObject<RenderParagraph>(paragraphs.at(index))
                .text
                .toPlainText(),
      ];
    }

    testWidgets('the deepest step stays whole and the rest fold', (
      tester,
    ) async {
      // The deck header at 360: `All decks / Academic Word List` does not fit,
      // and both steps used to ellipsize together — `Tất cả… / Academic W…`.
      // Only one of them is worth keeping, and it is the one nearest the user.
      await pumpHeader(tester, <String>[
        'All decks',
        'Academic Word List',
      ], width: 190);

      expect(clipped(tester), isEmpty);
      expect(find.text('Academic Word List'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);
      expect(find.text('All decks'), findsNothing);
    });

    testWidgets('a line with room for both keeps both', (tester) async {
      await pumpHeader(tester, <String>[
        'All decks',
        'Academic Word List',
      ], width: 500);

      expect(clipped(tester), isEmpty);
      expect(find.text('All decks'), findsOneWidget);
      expect(find.text('Academic Word List'), findsOneWidget);
      expect(find.text('…'), findsNothing);
    });

    testWidgets('a deep path keeps as many of the nearest steps as fit', (
      tester,
    ) async {
      // BR-55 allows ten levels. The fold is one marker however many it hides:
      // the sheet behind a long press is where the whole path lives.
      await pumpHeader(tester, <String>[
        'All decks',
        'A',
        'B',
        'C',
        'D',
        'Sublist 1',
      ], width: 190);

      expect(clipped(tester), isEmpty);
      expect(find.text('Sublist 1'), findsOneWidget);
      expect(find.text('…'), findsOneWidget);
      expect(find.text('All decks'), findsNothing);
    });

    testWidgets('at a large text scale it folds rather than cutting', (
      tester,
    ) async {
      await pumpHeader(
        tester,
        <String>['All decks', 'Academic Word List'],
        width: 360,
        textScale: 1.5,
      );

      expect(clipped(tester), isEmpty);
      expect(find.text('Academic Word List'), findsOneWidget);
    });

    testWidgets('one step longer than the bar is the one case that clips', (
      tester,
    ) async {
      // Nothing left to fold: a single name wider than the whole header has to
      // give, and clipping one label beats overflowing the row.
      await pumpHeader(tester, <String>[
        'A deck name far too long for any header to hold',
      ], width: 200);

      expect(clipped(tester), hasLength(1));
    });
  });
}
