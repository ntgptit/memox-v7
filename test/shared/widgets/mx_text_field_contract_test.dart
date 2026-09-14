import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/states/app_interaction_states.dart';
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
      // The box alone is the handoff field height since M100.92 (`size-input`
      // 52); it was the 48 touch floor.
      expect(
        none,
        AppSizing.input,
        reason: 'the box alone is the field height',
      );
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
        // that carries the error branch. The glyph takes the danger *ink*
        // since M100.87 — the handoff's `error` fill reads 4.21:1 on the
        // field — while the border below keeps `error`.
        expect(
          await suffixColorOf(
            tester,
            errorText: 'Already tagged',
            isDark: mode.$2,
          ),
          semantic.dangerInk,
        );
        // **Disabled keeps the resting ink** (M100.92): the handoff dims the
        // whole field to 0.38, so a second dim on the glyph would read it at
        // a fifth of its strength.
        expect(
          await suffixColorOf(tester, isEnabled: false, isDark: mode.$2),
          theme.colorScheme.onSurfaceVariant,
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
      expect(atRest.borderSide.width, AppStroke.hairline);

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

  group('handoff TextField (D)', () {
    Future<void> pumpField(WidgetTester tester, MxTextField field) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: Scaffold(body: Center(child: field)),
        ),
      );
      await tester.pumpAndSettle();
    }

    test('theme: filled lowest, hairline edges, 52 minimum', () {
      final theme = buildLightTheme();
      final input = theme.inputDecorationTheme;
      final scheme = theme.colorScheme;

      expect(input.filled, isTrue);
      expect(input.fillColor, scheme.surfaceContainerLowest);
      expect(input.constraints?.minHeight, AppSizing.input);
      for (final (InputBorder? border, Color color, double width)
          in <(InputBorder?, Color, double)>[
            (input.enabledBorder, scheme.outlineVariant, AppStroke.hairline),
            (input.focusedBorder, scheme.primary, AppStroke.hairline),
            (input.errorBorder, scheme.error, AppStroke.hairline),
            // D27: focused and in error keeps the 2 stroke.
            (input.focusedErrorBorder, scheme.error, AppStroke.focus),
          ]) {
        final side = (border! as OutlineInputBorder).borderSide;
        expect(side.color, color);
        expect(side.width, width);
      }
    });

    testWidgets('an error is a caption row led by an alert glyph', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(
        tester,
        MxTextField(
          controller: controller,
          label: 'Name',
          errorText: 'Required',
        ),
      );

      final row = find
          .ancestor(of: find.text('Required'), matching: find.byType(Row))
          .first;
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.error_outline)),
        findsOneWidget,
      );
      expect(tester.widget<Text>(find.text('Required')).style!.fontSize, 12);
    });

    testWidgets('a disabled field is dimmed as a whole', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(
        tester,
        MxTextField(controller: controller, label: 'Name', isEnabled: false),
      );

      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byType(TextField),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, AppStateOpacity.disabledContent);
    });

    testWidgets('a multi-line field drops to a 40 minimum', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpField(
        tester,
        MxTextField(
          controller: controller,
          label: 'Notes',
          minLines: 1,
          maxLines: 4,
        ),
      );

      final decoration = tester
          .widget<TextField>(find.byType(TextField))
          .decoration!;
      expect(decoration.constraints?.minHeight, AppSizing.inputMultilineMin);
      expect(
        decoration.contentPadding,
        const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
      );
    });
  });
}
