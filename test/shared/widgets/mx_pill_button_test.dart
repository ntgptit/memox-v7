import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_spacing.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

/// `MxPillButton` — the app's one-of-N control.
///
/// The selection semantics are the reason this wraps `ChoiceChip` instead of an
/// `InkWell`, so they are what most of this file asserts: a pill that looks
/// selected and does not *say* it is selected is the failure a hand-rolled
/// version ships with.
void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget pill, {
    double textScale = 1,
    bool isDark = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: isDark ? buildDarkTheme() : buildLightTheme(),
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: Center(child: pill),
          ),
        ),
      ),
    );
  }

  group('interaction', () {
    testWidgets('reports a press', (tester) async {
      var presses = 0;
      await pump(
        tester,
        MxPillButton(
          label: 'A-Z',
          isSelected: false,
          onPressed: () => presses += 1,
        ),
      );

      await tester.tap(find.byType(MxPillButton));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('reports a press even when already selected', (tester) async {
      // A toggle's selected pill is what switches back. A `ChoiceChip` that
      // swallowed the tap on the selected value would strand the user on the
      // filtered view with no way out.
      var presses = 0;
      await pump(
        tester,
        MxPillButton(
          label: 'A-Z',
          isSelected: true,
          onPressed: () => presses += 1,
        ),
      );

      await tester.tap(find.byType(MxPillButton));
      await tester.pump();

      expect(presses, 1);
    });

    testWidgets('a null callback disables it', (tester) async {
      await pump(
        tester,
        const MxPillButton(label: 'A-Z', isSelected: false, onPressed: null),
      );

      expect(
        tester.widget<ChoiceChip>(find.byType(ChoiceChip)).onSelected,
        isNull,
      );
    });
  });

  group('semantics', () {
    testWidgets('announces its selected state', (tester) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxPillButton(label: 'Due only', isSelected: true, onPressed: () {}),
      );

      expect(
        tester.getSemantics(find.byType(ChoiceChip)),
        matchesSemantics(
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Due only',
        ),
      );
      handle.dispose();
    });

    testWidgets('an abbreviation is replaced, not appended', (tester) async {
      // `A-Z` is two letters read aloud. The expansion has to *replace* it, or a
      // screen reader announces both and the control names itself twice.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxPillButton(
          label: 'A-Z',
          semanticLabel: 'Sorted by name. Activate to sort by newest first.',
          isSelected: true,
          onPressed: () {},
        ),
      );

      expect(
        find.bySemanticsLabel(
          'Sorted by name. Activate to sort by newest first.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('A-Z'), findsNothing);
      handle.dispose();
    });

    testWidgets('without an override the visible label is the name', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        MxPillButton(label: 'All decks', isSelected: false, onPressed: () {}),
      );

      expect(find.bySemanticsLabel('All decks'), findsOneWidget);
      handle.dispose();
    });
  });

  group('layout', () {
    testWidgets('meets the minimum touch target', (tester) async {
      await pump(
        tester,
        MxPillButton(label: 'A-Z', isSelected: false, onPressed: () {}),
      );

      // A chip is 32 high on its own. `materialTapTargetSize.padded` is what
      // takes it to the guideline minimum, and this is the assertion that stops
      // someone removing it for looking redundant.
      final size = tester.getSize(find.byType(MxPillButton));
      expect(size.height, greaterThanOrEqualTo(AppSpacing.minimumTouchTarget));
    });

    testWidgets('survives 2.0x text without overflowing', (tester) async {
      await pump(
        tester,
        MxPillButton(
          label: 'Tất cả bộ thẻ',
          icon: Icons.filter_list,
          isSelected: true,
          onPressed: () {},
        ),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('an icon does not replace the label', (tester) async {
      // The icon is decoration. A pill that dropped its text when given one
      // would be an icon button with a bigger hit area, which already exists.
      await pump(
        tester,
        MxPillButton(
          label: 'Due only',
          icon: Icons.filter_list,
          isSelected: false,
          onPressed: () {},
        ),
      );

      expect(find.text('Due only'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('selected and unselected differ in both themes', (
      tester,
    ) async {
      // The pill carries "which one is active" by fill alone, so the two fills
      // have to actually differ — in dark as well as light, where a scheme that
      // collapsed them would be invisible rather than merely subtle.
      for (final isDark in <bool>[false, true]) {
        await pump(
          tester,
          MxPillButton(label: 'A-Z', isSelected: false, onPressed: () {}),
          isDark: isDark,
        );
        final unselected = tester.widget<ChoiceChip>(find.byType(ChoiceChip));

        await pump(
          tester,
          MxPillButton(label: 'A-Z', isSelected: true, onPressed: () {}),
          isDark: isDark,
        );
        final selected = tester.widget<ChoiceChip>(find.byType(ChoiceChip));

        expect(unselected.selected, isFalse);
        expect(selected.selected, isTrue);

        final theme = isDark ? buildDarkTheme() : buildLightTheme();
        expect(
          theme.chipTheme.selectedColor,
          isNot(theme.chipTheme.backgroundColor),
          reason:
              'the two states are indistinguishable in '
              '${isDark ? 'dark' : 'light'}',
        );
      }
    });
  });
}
