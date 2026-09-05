import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/schemes/app_bold_text.dart';

/// A20.1 P1-11, corrective pass — the OS Bold-text setting reaches the text a
/// *component* draws, not only the text theme, and it reaches it through the
/// `wght` axis (a variable font ignores `fontWeight` alone).
void main() {
  const FontVariation wght700 = FontVariation('wght', 700);

  bool isBold(TextStyle? style) =>
      style != null &&
      style.fontWeight == FontWeight.w700 &&
      (style.fontVariations ?? const <FontVariation>[]).contains(wght700);

  group('every component slot the theme sets resolves wght 700', () {
    for (final (name, base) in <(String, ThemeData)>[
      ('light', buildLightTheme()),
      ('dark', buildDarkTheme()),
      ('high contrast light', buildHighContrastLightTheme()),
      ('high contrast dark', buildHighContrastDarkTheme()),
    ]) {
      test(name, () {
        final bold = applyBoldText(base);
        const states = <WidgetState>{};
        const selected = <WidgetState>{WidgetState.selected};
        TextStyle? state(
          WidgetStateProperty<TextStyle?>? p,
          Set<WidgetState> s,
        ) => p?.resolve(s);

        final slots = <String, (TextStyle?, TextStyle?)>{
          'listTile.title': (
            base.listTileTheme.titleTextStyle,
            bold.listTileTheme.titleTextStyle,
          ),
          'listTile.subtitle': (
            base.listTileTheme.subtitleTextStyle,
            bold.listTileTheme.subtitleTextStyle,
          ),
          'navigationBar.label': (
            state(base.navigationBarTheme.labelTextStyle, states),
            state(bold.navigationBarTheme.labelTextStyle, states),
          ),
          'navigationBar.label.selected': (
            state(base.navigationBarTheme.labelTextStyle, selected),
            state(bold.navigationBarTheme.labelTextStyle, selected),
          ),
          'input.label': (
            base.inputDecorationTheme.labelStyle,
            bold.inputDecorationTheme.labelStyle,
          ),
          'input.hint': (
            base.inputDecorationTheme.hintStyle,
            bold.inputDecorationTheme.hintStyle,
          ),
          'input.helper': (
            base.inputDecorationTheme.helperStyle,
            bold.inputDecorationTheme.helperStyle,
          ),
          'input.error': (
            base.inputDecorationTheme.errorStyle,
            bold.inputDecorationTheme.errorStyle,
          ),
          'popupMenu.label': (
            state(base.popupMenuTheme.labelTextStyle, states),
            state(bold.popupMenuTheme.labelTextStyle, states),
          ),
          'dialog.title': (
            base.dialogTheme.titleTextStyle,
            bold.dialogTheme.titleTextStyle,
          ),
          'dialog.content': (
            base.dialogTheme.contentTextStyle,
            bold.dialogTheme.contentTextStyle,
          ),
          'datePicker.day': (
            base.datePickerTheme.dayStyle,
            bold.datePickerTheme.dayStyle,
          ),
          'datePicker.headerHeadline': (
            base.datePickerTheme.headerHeadlineStyle,
            bold.datePickerTheme.headerHeadlineStyle,
          ),
          'timePicker.hourMinute': (
            base.timePickerTheme.hourMinuteTextStyle,
            bold.timePickerTheme.hourMinuteTextStyle,
          ),
          'timePicker.dayPeriod': (
            base.timePickerTheme.dayPeriodTextStyle,
            bold.timePickerTheme.dayPeriodTextStyle,
          ),
          'snackBar.content': (
            base.snackBarTheme.contentTextStyle,
            bold.snackBarTheme.contentTextStyle,
          ),
          'appBar.title': (
            base.appBarTheme.titleTextStyle,
            bold.appBarTheme.titleTextStyle,
          ),
          'chip.label': (base.chipTheme.labelStyle, bold.chipTheme.labelStyle),
          'tooltip.text': (
            base.tooltipTheme.textStyle,
            bold.tooltipTheme.textStyle,
          ),
          'filledButton.text': (
            state(base.filledButtonTheme.style?.textStyle, states),
            state(bold.filledButtonTheme.style?.textStyle, states),
          ),
          'outlinedButton.text': (
            state(base.outlinedButtonTheme.style?.textStyle, states),
            state(bold.outlinedButtonTheme.style?.textStyle, states),
          ),
          'textButton.text': (
            state(base.textButtonTheme.style?.textStyle, states),
            state(bold.textButtonTheme.style?.textStyle, states),
          ),
        };

        var seen = 0;
        for (final entry in slots.entries) {
          final (before, after) = entry.value;
          if (before == null) {
            expect(after, isNull, reason: '${entry.key}: invented a style');
            continue;
          }
          seen++;
          expect(
            isBold(after),
            isTrue,
            reason: '${entry.key} did not embolden',
          );
          expect(after!.fontSize, before.fontSize, reason: entry.key);
        }
        // The list is a registry of what the theme sets; if it sets fewer than
        // this many, a slot silently left the theme.
        expect(
          seen,
          greaterThanOrEqualTo(14),
          reason: 'slots set by the theme',
        );
      });
    }
  });

  group('rendered component text emboldens under MediaQuery.boldText', () {
    Future<void> pumpBold(WidgetTester tester, Widget home) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(boldText: true),
            child: BoldTextWidget(child: child!),
          ),
          home: home,
        ),
      );
      await tester.pumpAndSettle();
    }

    /// The style the engine will actually shape, read off the `RichText`
    /// that paints [text].
    TextStyle renderedStyle(WidgetTester tester, String text) {
      final rich = tester.widget<RichText>(
        find
            .descendant(of: find.text(text), matching: find.byType(RichText))
            .first,
      );
      return rich.text.style!;
    }

    void expectRenderedBold(WidgetTester tester, String text) {
      final style = renderedStyle(tester, text);
      expect(
        isBold(style),
        isTrue,
        reason:
            '"$text" rendered at ${style.fontWeight} ${style.fontVariations}',
      );
    }

    testWidgets('ListTile title and subtitle', (tester) async {
      await pumpBold(
        tester,
        const Scaffold(
          body: ListTile(title: Text('Tile title'), subtitle: Text('Tile sub')),
        ),
      );
      expectRenderedBold(tester, 'Tile title');
      expectRenderedBold(tester, 'Tile sub');
    });

    testWidgets('NavigationBar label', (tester) async {
      await pumpBold(
        tester,
        Scaffold(
          bottomNavigationBar: NavigationBar(
            destinations: const <NavigationDestination>[
              NavigationDestination(icon: Icon(Icons.home), label: 'Home nav'),
              NavigationDestination(icon: Icon(Icons.star), label: 'Star nav'),
            ],
          ),
        ),
      );
      expectRenderedBold(tester, 'Home nav');
      expectRenderedBold(tester, 'Star nav');
    });

    testWidgets('InputDecoration hint and label', (tester) async {
      await pumpBold(
        tester,
        const Scaffold(
          body: Column(
            children: <Widget>[
              TextField(decoration: InputDecoration(hintText: 'Hint here')),
              TextField(decoration: InputDecoration(labelText: 'Label here')),
            ],
          ),
        ),
      );
      expectRenderedBold(tester, 'Hint here');
      expectRenderedBold(tester, 'Label here');
    });

    testWidgets('PopupMenu row', (tester) async {
      await pumpBold(
        tester,
        Scaffold(
          body: PopupMenuButton<int>(
            itemBuilder: (_) => const <PopupMenuEntry<int>>[
              PopupMenuItem<int>(value: 1, child: Text('Menu row')),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(PopupMenuButton<int>));
      await tester.pumpAndSettle();
      expectRenderedBold(tester, 'Menu row');
    });

    testWidgets('Dialog title and content', (tester) async {
      await pumpBold(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('Dialog title'),
                  content: Text('Dialog content'),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expectRenderedBold(tester, 'Dialog title');
      expectRenderedBold(tester, 'Dialog content');
    });

    testWidgets('Date picker day and time picker hour', (tester) async {
      await pumpBold(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: <Widget>[
                TextButton(
                  onPressed: () => showDatePicker(
                    context: context,
                    initialDate: DateTime(2026, 9, 4),
                    firstDate: DateTime(2026),
                    lastDate: DateTime(2027),
                  ),
                  child: const Text('date'),
                ),
                TextButton(
                  onPressed: () => showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 20, minute: 15),
                  ),
                  child: const Text('time'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('date'));
      await tester.pumpAndSettle();
      // A day cell in the grid — the picker's own dayStyle.
      expectRenderedBold(tester, '15');
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('time'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      // The minute field: the hour reads `8` under the test locale's 12-hour
      // clock, the minute is `15` under either.
      expectRenderedBold(tester, '15');
    });

    testWidgets('SnackBar content', (tester) async {
      await pumpBold(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Snack text'))),
              child: const Text('snack'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('snack'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 750));
      expectRenderedBold(tester, 'Snack text');
    });
  });
}
