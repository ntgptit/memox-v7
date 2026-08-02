import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// `MxTextField` and `MxIconButton` — the two input primitives Deck/Card needs.
void main() {
  /// Pumps [child] in the real theme, at a phone size, with a text scale.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
    Size surface = const Size(360, 640),
    double textScale = 1,
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
            child: Scaffold(body: Center(child: child)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MxTextField', () {
    testWidgets('renders its label and hint at rest', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Deck name',
          hintText: 'Academic Word List',
        ),
      );

      expect(find.text('Deck name'), findsOneWidget);
      expect(find.text('Academic Word List'), findsOneWidget);
    });

    testWidgets('typing reports the value unchanged', (tester) async {
      // Unchanged on purpose: trimming here would hand the caller a different
      // string than the one it validated.
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final seen = <String>[];

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Deck name',
          onChanged: seen.add,
        ),
      );
      await tester.enterText(find.byType(TextField), '  spaced  ');

      expect(seen, <String>['  spaced  ']);
      expect(controller.text, '  spaced  ');
    });

    testWidgets('error text is shown as text, not only as colour', (
      tester,
    ) async {
      // A red outline with no message tells a colour-blind user that something
      // is different and not what.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Deck name',
          errorText: 'Name is required',
        ),
      );

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('focus is reflected in the field state', (tester) async {
      final controller = TextEditingController();
      final node = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(node.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Deck name',
          focusNode: node,
        ),
      );

      expect(node.hasFocus, isFalse);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(node.hasFocus, isTrue);
    });

    testWidgets('disabled refuses input', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Deck name',
          isEnabled: false,
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('multiline grows for a front/back editor', (tester) async {
      final controller = TextEditingController(
        text: List<String>.filled(6, 'a line of card content').join('\n'),
      );
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Front',
          minLines: 3,
          maxLines: null,
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('the caller supplies the limit; the field knows no rule', (
      tester,
    ) async {
      // BR-01's 200 and BR-08's 60/240 live with the feature. The field is
      // handed a number.
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(controller: controller, label: 'Deck name', maxLength: 200),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).maxLength, 200);
    });
  });

  group('MxIconButton', () {
    testWidgets('always carries a semantic label', (tester) async {
      await pump(
        tester,
        MxIconButton(
          icon: Icons.delete_outline,
          semanticLabel: 'Delete deck',
          onPressed: () {},
        ),
      );

      expect(find.bySemanticsLabel('Delete deck'), findsWidgets);
    });

    testWidgets('meets the 48x48 minimum touch target', (tester) async {
      // From `IconButtonThemeData`, not from a parameter — no screen can shrink
      // it below what a thumb can hit.
      await pump(
        tester,
        MxIconButton(
          icon: Icons.edit_outlined,
          semanticLabel: 'Rename',
          onPressed: () {},
        ),
      );

      final size = tester.getSize(find.byType(IconButton));

      expect(size.width, greaterThanOrEqualTo(AppSpacing.minimumTouchTarget));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minimumTouchTarget));
    });

    testWidgets('enabled fires exactly once per tap', (tester) async {
      var taps = 0;

      await pump(
        tester,
        MxIconButton(
          icon: Icons.add,
          semanticLabel: 'Add',
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('disabled fires nothing', (tester) async {
      await pump(
        tester,
        const MxIconButton(
          icon: Icons.add,
          semanticLabel: 'Add',
          onPressed: null,
        ),
      );
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).onPressed,
        isNull,
      );
    });

    testWidgets('the tooltip defaults to the semantic label', (tester) async {
      // One string for both, so the spoken name and the visible name cannot
      // drift apart.
      await pump(
        tester,
        MxIconButton(
          icon: Icons.add,
          semanticLabel: 'Add card',
          onPressed: () {},
        ),
      );

      expect(
        tester.widget<IconButton>(find.byType(IconButton)).tooltip,
        'Add card',
      );
    });
  });

  group('small screen and large text', () {
    const small = Size(320, 568);

    testWidgets('MxTextField survives 320x568 at textScaler 2.0', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'A fairly long deck name');
      addTearDown(controller.dispose);

      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'A long enough label to wrap on a narrow screen',
          helperText: 'Helper text that also has to fit somewhere',
          errorText: 'And an error message underneath it',
          maxLength: 200,
        ),
        surface: small,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('MxIconButton survives 320x568 at textScaler 2.0', (
      tester,
    ) async {
      await pump(
        tester,
        MxIconButton(
          icon: Icons.delete_outline,
          semanticLabel: 'Delete',
          onPressed: () {},
        ),
        surface: small,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('both render in dark', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await pump(
        tester,
        Column(
          children: <Widget>[
            MxTextField(controller: controller, label: 'Deck name'),
            MxIconButton(
              icon: Icons.add,
              semanticLabel: 'Add',
              onPressed: () {},
            ),
          ],
        ),
        isDark: true,
      );

      expect(tester.takeException(), isNull);
    });
  });
}
