import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
          'timePicker.dial': (
            base.timePickerTheme.dialTextStyle,
            bold.timePickerTheme.dialTextStyle,
          ),
          'slider.valueIndicator': (
            base.sliderTheme.valueIndicatorTextStyle,
            bold.sliderTheme.valueIndicatorTextStyle,
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

        // A state-resolved slot is read at rest here; its states are the
        // next group's business.
        TextStyle? atRest(TextStyle? style) => style is WidgetStateTextStyle
            ? style.resolve(const <WidgetState>{})
            : style;

        var seen = 0;
        for (final entry in slots.entries) {
          final before = atRest(entry.value.$1);
          final after = atRest(entry.value.$2);
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

  group('a state-resolved slot keeps its resolver', () {
    // `hintStyle` answers per state — `onSurfaceVariant` at rest,
    // `onDisabled` when the field is disabled. Re-weighting must wrap that
    // resolver, not flatten it (corrective pass 2).
    for (final (name, base) in <(String, ThemeData)>[
      ('light', buildLightTheme()),
      ('dark', buildDarkTheme()),
    ]) {
      test('the hint resolves disabled ink, emboldened, $name', () {
        final bold = applyBoldText(base);
        final before = base.inputDecorationTheme.hintStyle;
        final after = bold.inputDecorationTheme.hintStyle;
        expect(before, isA<WidgetStateTextStyle>(), reason: 'theme changed');
        expect(after, isA<WidgetStateTextStyle>(), reason: 'resolver lost');
        final beforeStates = before! as WidgetStateTextStyle;
        final afterStates = after! as WidgetStateTextStyle;
        for (final states in <Set<WidgetState>>[
          const <WidgetState>{},
          const <WidgetState>{WidgetState.disabled},
        ]) {
          final resolvedBefore = beforeStates.resolve(states);
          final resolvedAfter = afterStates.resolve(states);
          expect(isBold(resolvedAfter), isTrue, reason: '$states');
          expect(resolvedAfter.color, resolvedBefore.color, reason: '$states');
        }
        expect(
          afterStates.resolve(const <WidgetState>{}).color,
          isNot(
            afterStates.resolve(const <WidgetState>{
              WidgetState.disabled,
            }).color,
          ),
          reason: 'two states, two inks',
        );
      });
    }
  });

  group('every text slot a component theme sets is re-weighted', () {
    test('the slot list in app_bold_text.dart covers the theme sources', () {
      // A registry that reads the theme sources: any `xxxStyle:` /
      // `xxxTextStyle:` slot a component theme sets must be named in
      // `applyBoldText`. `dialTextStyle` and `valueIndicatorTextStyle` were
      // missed by hand once (corrective pass 2); this is what makes a third
      // omission impossible.
      final setSlots = <String>{};
      final slotPattern = RegExp(
        r'^\s+([a-zA-Z]+(?:Style|TextStyle))\s*:',
        multiLine: true,
      );
      for (final file
          in Directory('lib/core/theme/components')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        for (final m in slotPattern.allMatches(file.readAsStringSync())) {
          setSlots.add(m.group(1)!);
        }
      }
      expect(setSlots, isNotEmpty);
      final bolder = File(
        'lib/core/theme/schemes/app_bold_text.dart',
      ).readAsStringSync();
      for (final slot in setSlots) {
        expect(
          bolder,
          contains('$slot:'),
          reason: '`$slot` is set by a theme and not re-weighted',
        );
      }
    });
  });
}
