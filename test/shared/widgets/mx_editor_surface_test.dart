import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/extensions/theme_context_extension.dart';
import 'package:memox/shared/widgets/mx_content_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The four shared axes the card editor's concept parity needed.
///
/// **They are here rather than in the editor's tests because they are shared
/// surface**: the next caller inherits whatever these assert, and the editor is
/// only the first. Each one has a default, and the default is the whole
/// backwards-compatibility claim — so each is asserted, not argued.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: buildLightTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );

  group('MxContentShell.footer', () {
    Future<void> pumpShell(WidgetTester tester, {Widget? footer}) =>
        tester.pumpWidget(
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

    const Widget footer = SizedBox(
      height: 64,
      child: Center(child: Text('Save changes')),
    );

    testWidgets('a screen that passes none renders no band at all', (
      tester,
    ) async {
      await pumpShell(tester);

      // The default is the compatibility claim: every screen that existed
      // before this slot passes nothing, so nothing about their layout may
      // depend on it.
      expect(find.text('Save changes'), findsNothing);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).bottomNavigationBar,
        isNull,
      );
    });

    testWidgets('a footer is outside the scrolling body', (tester) async {
      await pumpShell(tester, footer: footer);

      expect(
        find.ancestor(
          of: find.text('Save changes'),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
    });

    testWidgets('a footer does not move when the body scrolls', (tester) async {
      await pumpShell(tester, footer: footer);

      final Rect before = tester.getRect(find.text('Save changes'));
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      expect(tester.getRect(find.text('Save changes')), before);
    });

    testWidgets('a footer stays above the keyboard', (tester) async {
      // **The measurement that decided the implementation.** `Scaffold`
      // subtracts the keyboard from the *body* and pins `bottomNavigationBar`
      // at `size.height − barHeight` regardless — on this viewport the body
      // ended at 508 and the bar sat at 738…844, entirely behind the keyboard.
      // Being the body's last row is what fixes it.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.reset);

      await pumpShell(tester, footer: footer);

      expect(
        tester.getRect(find.text('Save changes')).bottom,
        lessThanOrEqualTo(844 - 336),
      );
    });

    testWidgets('a hairline separates the footer from the body', (
      tester,
    ) async {
      await pumpShell(tester, footer: footer);

      // Without it the scrolling body is guillotined flush against the action:
      // at 320dp and text scale 2.0 the last line of a helper was cut in half
      // and left touching the button.
      final BoxDecoration decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text('Save changes'),
                          matching: find.byType(DecoratedBox),
                        )
                        .last,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.border, isNotNull);
    });
  });

  group('MxIconButtonTone', () {
    testWidgets('standard leaves the theme to decide', (tester) async {
      await pump(
        tester,
        MxIconButton(
          icon: Icons.flag_outlined,
          semanticLabel: 'Flag card',
          onPressed: () {},
        ),
      );

      expect(tester.widget<IconButton>(find.byType(IconButton)).color, isNull);
    });

    testWidgets('warning resolves to the semantic role, not a literal', (
      tester,
    ) async {
      await pump(
        tester,
        MxIconButton(
          icon: Icons.flag,
          semanticLabel: 'Remove flag',
          tone: MxIconButtonTone.warning,
          onPressed: () {},
        ),
      );

      final BuildContext context = tester.element(find.byType(IconButton));
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).color,
        context.semanticColors.warning,
      );
    });

    testWidgets('a toned button still greys out when disabled', (tester) async {
      await pump(
        tester,
        const MxIconButton(
          icon: Icons.flag,
          semanticLabel: 'Remove flag',
          tone: MxIconButtonTone.warning,
          onPressed: null,
        ),
      );

      // The tone speaks about the state the icon reports, not about whether the
      // control can be pressed — `IconButton` still resolves disabled through
      // `disabledColor`.
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });
  });

  group('MxTextField additions', () {
    testWidgets('the default keeps Material\'s floating label', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(tester, MxTextField(controller: controller, label: 'Deck'));

      final InputDecoration decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(decoration.labelText, 'Deck');
      expect(decoration.suffixIcon, isNull);
      expect(decoration.suffixIconConstraints, isNull);
    });

    testWidgets('external stops it painting the label, and only that', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'FRONT',
          labelPlacement: MxTextFieldLabelPlacement.external,
        ),
      );

      // The caller draws it and merges it into the field's node; the widget
      // stops painting a second copy. `label` stays required either way,
      // because a field with no name is unlabelled to a screen reader whichever
      // way it is drawn.
      expect(
        tester.widget<TextField>(find.byType(TextField)).decoration!.labelText,
        isNull,
      );
      expect(find.text('FRONT'), findsNothing);
    });

    testWidgets('the trailing action meets the touch floor', (tester) async {
      final controller = TextEditingController(text: 'noun');
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Add tag',
          trailingAction: MxTextFieldAction(
            icon: Icons.add,
            semanticLabel: 'Add this tag',
            onPressed: () {},
          ),
        ),
      );

      final Rect rect = tester.getRect(find.byType(IconButton));
      expect(rect.width, greaterThanOrEqualTo(48));
      expect(rect.height, greaterThanOrEqualTo(48));
    });

    testWidgets('a null callback leaves the action visible and inert', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Add tag',
          trailingAction: const MxTextFieldAction(
            icon: Icons.add,
            semanticLabel: 'Add this tag',
            onPressed: null,
          ),
        ),
      );

      // Visible, so it does not appear under the finger as the first character
      // lands; inert, so it cannot submit nothing.
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });

    testWidgets('helper and error both get three lines, app-wide', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'a field',
          helperText:
              'a sentence long enough to need more than one line on a '
              'narrow phone, which Material would otherwise cut mid-word',
        ),
      );

      // **Not a parameter, and this is the assertion that says so.** Material's
      // default is one line; the card editor's BR-10 sentence painted
      // `…change this card'…` and said nothing. A per-caller option would have
      // left every other field on the truncating default.
      final InputDecoration decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(decoration.helperMaxLines, 3);
      expect(decoration.errorMaxLines, 3);
    });
  });
}
