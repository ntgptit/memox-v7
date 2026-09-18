import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/typography/app_typography.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';

/// `MxAppBar` in isolation — the row leading/title/actions build, the two
/// densities' padding and typography, and the fixed 56dp height.
/// `MxContentShell`'s own tests (`mx_content_shell_*_test.dart`) are the
/// regression proof that wiring it in did not move the hairline, the back
/// affordance or `automaticallyImplyLeading` — this file does not repeat them.
void main() {
  Widget host(Widget child, {double width = 400}) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );

  testWidgets('preferredSize is the fixed 56dp toolbar height', (tester) async {
    const bar = MxAppBar(title: Text('Library'));
    expect(bar.preferredSize, const Size.fromHeight(kToolbarHeight));
    expect(bar.preferredSize.height, 56);
  });

  testWidgets('leading, title and actions render in that left-to-right order', (
    tester,
  ) async {
    const leadingKey = Key('leading');
    const titleKey = Key('title');
    const action1Key = Key('action1');
    const action2Key = Key('action2');

    await tester.pumpWidget(
      host(
        const MxAppBar(
          leading: Icon(Icons.arrow_back, key: leadingKey),
          title: Text('Library', key: titleKey),
          actions: <Widget>[
            Icon(Icons.search, key: action1Key),
            Icon(Icons.more_vert, key: action2Key),
          ],
        ),
      ),
    );

    final leadingX = tester.getCenter(find.byKey(leadingKey)).dx;
    final titleX = tester.getCenter(find.byKey(titleKey)).dx;
    final action1X = tester.getCenter(find.byKey(action1Key)).dx;
    final action2X = tester.getCenter(find.byKey(action2Key)).dx;

    expect(leadingX, lessThan(titleX));
    expect(titleX, lessThan(action1X));
    expect(action1X, lessThan(action2X));
  });

  testWidgets('no leading and no actions still renders the title alone', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MxAppBar(title: Text('Library'))));

    expect(find.text('Library'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('a null title renders no title widget', (tester) async {
    await tester.pumpWidget(
      host(const MxAppBar(title: null, leading: Icon(Icons.arrow_back))),
    );

    expect(find.byType(Text), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets(
    'no actions leaves the title the full remaining width (falls out of Expanded)',
    (tester) async {
      double? widthWithoutActions;
      double? widthWithActions;

      Widget probe(void Function(double) onWidth) => LayoutBuilder(
        builder: (context, constraints) {
          onWidth(constraints.maxWidth);
          return const SizedBox.shrink();
        },
      );

      await tester.pumpWidget(
        host(MxAppBar(title: probe((w) => widthWithoutActions = w))),
      );
      await tester.pumpWidget(
        host(
          MxAppBar(
            title: probe((w) => widthWithActions = w),
            actions: const <Widget>[Icon(Icons.search)],
          ),
        ),
      );

      expect(widthWithoutActions, isNotNull);
      expect(widthWithActions, isNotNull);
      expect(widthWithoutActions, greaterThan(widthWithActions!));
    },
  );

  testWidgets('title ellipsizes rather than wraps under a narrow width', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MxAppBar(
          title: Text(
            'A title with enough words to overflow a narrow compact bar',
          ),
        ),
        width: 120,
      ),
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('A title with enough words to overflow a narrow compact bar'),
    );
    expect(paragraph.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isTrue);
  });

  testWidgets('narrow bar keeps leading and both actions, ellipsizes title', (
    tester,
  ) async {
    const leadingKey = Key('leading');
    const action1Key = Key('action1');
    const action2Key = Key('action2');
    const title = 'A very long title that cannot possibly fit in two hundred';

    await tester.pumpWidget(
      host(
        const MxAppBar(
          leading: Icon(Icons.arrow_back, key: leadingKey),
          title: Text(title),
          actions: <Widget>[
            Icon(Icons.search, key: action1Key),
            Icon(Icons.more_vert, key: action2Key),
          ],
        ),
        width: 200,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(leadingKey), findsOneWidget);
    expect(find.byKey(action1Key), findsOneWidget);
    expect(find.byKey(action2Key), findsOneWidget);
    expect(
      tester.getRect(find.byKey(action2Key)).right,
      lessThanOrEqualTo(200),
    );
    expect(
      tester.renderObject<RenderParagraph>(find.text(title)).didExceedMaxLines,
      isTrue,
    );
  });

  group('density', () {
    testWidgets('compact pads AppSpacing.sm and titles at the content rung', (
      tester,
    ) async {
      TextStyle? style;
      await tester.pumpWidget(
        host(
          MxAppBar(
            title: Builder(
              builder: (context) {
                style = DefaultTextStyle.of(context).style;
                return const Text('Library');
              },
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(MxAppBar),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      );

      expect(style!.fontSize, AppTypography.appBarContentTitleSize);
      expect(style!.letterSpacing, AppTypography.appBarContentTitleTracking);
      expect(style!.fontWeight, FontWeight.w700);
    });

    testWidgets('large pads AppSpacing.lg and titles at the screen rung', (
      tester,
    ) async {
      TextStyle? style;
      await tester.pumpWidget(
        host(
          MxAppBar(
            density: MxAppBarDensity.large,
            title: Builder(
              builder: (context) {
                style = DefaultTextStyle.of(context).style;
                return const Text('Library');
              },
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(MxAppBar),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      );

      expect(style!.fontSize, AppTypography.appBarScreenTitleSize);
      expect(style!.letterSpacing, AppTypography.appBarScreenTitleTracking);
      expect(style!.fontWeight, FontWeight.w700);
    });
  });
}
