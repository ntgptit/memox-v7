import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The contracts `MxTextField` gained at M100.36, each pinned at the level the
/// #433 audit found unguarded: a rect, a rendered colour, a semantics node, a
/// controller's text — never a `ThemeData` slot read back.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const <Locale>[Locale('en'), Locale('vi')],
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('supporting line', () {
    testWidgets('an arriving error moves nothing below a reserved field', (
      tester,
    ) async {
      // #433 F5: 20dp of growth the moment `errorText` landed on a field with
      // no `maxLength` — the two card-limit fields, whose controls sat
      // directly underneath.
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      Widget form(String? error) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MxTextField(controller: controller, label: 'Limit', errorText: error),
          MxActionButton(label: 'Save', onPressed: () {}),
        ],
      );

      await pump(tester, form(null));
      final buttonBefore = tester.getRect(find.byType(MxActionButton));
      final fieldBefore = tester.getRect(find.byType(MxTextField));

      await pump(tester, form('Enter 1–500'));

      expect(tester.getRect(find.byType(MxActionButton)), buttonBefore);
      expect(tester.getRect(find.byType(MxTextField)), fieldBefore);
      expect(find.text('Enter 1–500'), findsOneWidget);
    });

    testWidgets('`none` holds no line, and is the field-s own height', (
      tester,
    ) async {
      final a = TextEditingController();
      final b = TextEditingController();
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      await pump(
        tester,
        Column(
          children: <Widget>[
            MxTextField(
              controller: a,
              label: 'Paste',
              supportingLine: MxTextFieldSupportingLine.none,
            ),
            MxTextField(controller: b, label: 'Limit'),
          ],
        ),
      );

      final none = tester.getSize(find.byType(MxTextField).at(0)).height;
      final reserved = tester.getSize(find.byType(MxTextField).at(1)).height;
      expect(none, lessThan(reserved), reason: 'none still holds the line');
      expect(none, 48, reason: 'the box alone is the touch floor');
    });
  });

  group('content', () {
    testWidgets('digits rejects everything that is not 0–9, and asks for the '
        'numeric keyboard', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Limit',
          content: MxTextFieldContent.digits,
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc-12.5');
      await tester.pump();

      expect(controller.text, '125');
      expect(
        tester.widget<TextField>(find.byType(TextField)).keyboardType,
        TextInputType.number,
      );
    });

    testWidgets('text accepts what it is given', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(tester, MxTextField(controller: controller, label: 'Name'));

      await tester.enterText(find.byType(TextField), 'abc-12.5');
      expect(controller.text, 'abc-12.5');
    });
  });

  group('typography', () {
    testWidgets('the placeholder is the value-s own rung', (tester) async {
      // #433 F6: the hint was `body-md` under a `body-lg` value, so the text
      // grew and shifted its line box as the first character landed.
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Name',
          hintText: 'e.g. Academic Word List',
        ),
      );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final hint = tester.widget<Text>(find.text('e.g. Academic Word List'));
      final hintStyle = DefaultTextStyle.of(
        tester.element(find.text('e.g. Academic Word List')),
      ).style.merge(hint.style);
      final texts = buildLightTheme().textTheme;

      expect(hintStyle.fontSize, texts.bodyLarge!.fontSize);
      expect(hintStyle.height, texts.bodyLarge!.height);
      expect(hintStyle.color, buildLightTheme().colorScheme.onSurfaceVariant);
    });

    testWidgets('prominent sets the value in title-lg and nothing else', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'ubiquitous');
      addTearDown(controller.dispose);
      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Front',
          emphasis: MxTextFieldEmphasis.prominent,
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(
        editable.style.fontSize,
        buildLightTheme().textTheme.titleLarge!.fontSize,
      );
    });
  });

  group('suffix follows the field', () {
    Future<Color?> suffixColorOf(
      WidgetTester tester, {
      String? errorText,
      bool isEnabled = true,
      bool isDark = false,
    }) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Tag',
          errorText: errorText,
          isEnabled: isEnabled,
          trailingAction: MxTextFieldAction(
            icon: Icons.add,
            semanticLabel: 'Add tag',
            onPressed: isEnabled ? () {} : null,
          ),
        ),
        isDark: isDark,
      );
      final glyph = find.descendant(
        of: find.byType(MxIconButton),
        matching: find.byIcon(Icons.add),
      );

      return IconTheme.of(tester.element(glyph)).color;
    }

    for (final mode in <(String, bool)>[('light', false), ('dark', true)]) {
      testWidgets('${mode.$1} · rest, error and disabled each resolve their '
          'own role', (tester) async {
        final theme = mode.$2 ? buildDarkTheme() : buildLightTheme();
        final semantic = theme.extension<AppSemanticColors>()!;

        expect(
          await suffixColorOf(tester, isDark: mode.$2),
          theme.colorScheme.onSurfaceVariant,
        );
        // #433 F4: the border went red and the `+` beside it stayed grey,
        // because the themed `IconButtonTheme` answered before the M3 default
        // that carries the error branch.
        expect(
          await suffixColorOf(
            tester,
            errorText: 'Already tagged',
            isDark: mode.$2,
          ),
          theme.colorScheme.error,
        );
        expect(
          await suffixColorOf(tester, isEnabled: false, isDark: mode.$2),
          semantic.onDisabled,
        );
      });
    }
  });

  group('focused error', () {
    testWidgets('gains the focus stroke and keeps the error hue', (
      tester,
    ) async {
      // #433 F3: `focusedErrorBorder` was byte-identical to `errorBorder`, so
      // tapping an errored field acknowledged nothing. The canonical answer
      // is the stroke (M100.36 4C).
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pump(
        tester,
        MxTextField(
          controller: controller,
          label: 'Limit',
          errorText: 'Enter 1–500',
        ),
      );
      final scheme = buildLightTheme().colorScheme;
      final before = tester.getRect(find.byType(MxTextField));

      InputBorder? painted() {
        final decorator = tester.widget<InputDecorator>(
          find.byType(InputDecorator),
        );
        final d = decorator.decoration;
        return decorator.isFocused ? d.focusedErrorBorder : d.errorBorder;
      }

      final atRest = painted()! as OutlineInputBorder;
      expect(atRest.borderSide.color, scheme.error);
      expect(atRest.borderSide.width, AppStroke.control);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final focused = painted()! as OutlineInputBorder;
      expect(focused.borderSide.color, scheme.error, reason: 'the role moved');
      expect(focused.borderSide.width, AppStroke.focus, reason: 'no focus cue');
      expect(
        tester.getRect(find.byType(MxTextField)),
        before,
        reason: 'layout moved',
      );
    });
  });

  group('counter', () {
    testWidgets('speaks the characters remaining, not the fraction', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final controller = TextEditingController(text: 'a' * 26);
      addTearDown(controller.dispose);
      await pump(
        tester,
        MxTextField(controller: controller, label: 'Name', maxLength: 30),
      );

      expect(find.text('26/30'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          const DefaultMaterialLocalizations().remainingTextFieldCharacterCount(
            4,
          ),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
