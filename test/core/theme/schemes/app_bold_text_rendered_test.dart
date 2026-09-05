import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// A20.1 P1-11, corrective pass — rendered proof: the text a *component*
/// draws emboldens under `MediaQuery.boldText`, through the `wght` axis.
void main() {
  const FontVariation wght700 = FontVariation('wght', 700);

  bool isBold(TextStyle? style) =>
      style != null &&
      style.fontWeight == FontWeight.w700 &&
      (style.fontVariations ?? const <FontVariation>[]).contains(wght700);

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

    testWidgets('a disabled field keeps its disabled hint ink, emboldened', (
      tester,
    ) async {
      await pumpBold(
        tester,
        const Scaffold(
          body: TextField(
            enabled: false,
            decoration: InputDecoration(hintText: 'Faded hint'),
          ),
        ),
      );
      expectRenderedBold(tester, 'Faded hint');
      final context = tester.element(find.text('Faded hint'));
      final disabledInk = Theme.of(
        context,
      ).extension<AppSemanticColors>()!.onDisabled;
      expect(renderedStyle(tester, 'Faded hint').color, disabledInk);
    });

    testWidgets('Slider value indicator and time-picker dial', (tester) async {
      await pumpBold(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: <Widget>[
                Slider(
                  value: 40,
                  max: 100,
                  divisions: 10,
                  label: 'forty',
                  onChanged: (_) {},
                ),
                TextButton(
                  onPressed: () => showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 8, minute: 15),
                  ),
                  child: const Text('time'),
                ),
              ],
            ),
          ),
        ),
      );
      // The value indicator and the dial are painted, not laid out as text;
      // their styles are read off the theme each widget resolves in place.
      final sliderContext = tester.element(find.byType(Slider));
      expect(
        isBold(SliderTheme.of(sliderContext).valueIndicatorTextStyle),
        isTrue,
      );
      await tester.tap(find.text('time'));
      await tester.pumpAndSettle();
      final dialContext = tester.element(find.byType(TimePickerDialog));
      expect(isBold(TimePickerTheme.of(dialContext).dialTextStyle), isTrue);
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
