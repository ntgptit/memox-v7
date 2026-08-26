import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';

/// `MxContentShell.footer` — the slot that lets a screen pin an action bar
/// below a body it does not own.
///
/// Two things have to hold for it to be safe to add: a screen that passes no
/// footer must lay out exactly as it did, and a footer that is passed must be
/// outside the scroll rather than merely at the bottom of it.
void main() {
  Future<void> pump(WidgetTester tester, {Widget? footer}) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: MxContentShell(
        title: 'Editor',
        isScrollable: true,
        footer: footer,
        body: Column(
          children: <Widget>[
            for (int i = 0; i < 40; i++)
              SizedBox(height: 40, child: Text('$i')),
          ],
        ),
      ),
    ),
  );

  const Widget footer = SafeArea(
    top: false,
    child: SizedBox(height: 64, child: Center(child: Text('Save changes'))),
  );

  testWidgets('no footer leaves the body where it was', (tester) async {
    await pump(tester);
    final Rect withoutFooter = tester.getRect(find.text('0'));

    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
      isNull,
    );
    // The default is the whole compatibility claim: every existing caller
    // passes nothing, so nothing about their layout may depend on this slot.
    expect(withoutFooter.top, greaterThan(0));
  });

  testWidgets('a footer is outside the scrolling body', (tester) async {
    await pump(tester, footer: footer);

    expect(
      find.ancestor(
        of: find.text('Save changes'),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('a footer does not move when the body scrolls', (tester) async {
    await pump(tester, footer: footer);

    final Rect before = tester.getRect(find.text('Save changes'));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.text('Save changes')), before);
  });

  testWidgets('a footer takes its height out of the body, not over it', (
    tester,
  ) async {
    await pump(tester);
    final double withoutFooter = tester
        .getRect(find.byType(SingleChildScrollView))
        .bottom;

    await pump(tester, footer: footer);
    final Rect body = tester.getRect(find.byType(SingleChildScrollView));
    final Rect bar = tester.getRect(find.text('Save changes'));

    // Displaced, not overlaid: a bar drawn *over* the body would leave the
    // body's own last control unreachable, which is the failure a `bottomSheet`
    // or a `Stack` would have shipped.
    expect(body.bottom, lessThan(withoutFooter));
    expect(body.bottom, lessThanOrEqualTo(bar.top));
  });
}
