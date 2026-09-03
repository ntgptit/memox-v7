import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';

/// **What role does this component slot read?** — pinned as identity, for every
/// Material component the app themes.
///
/// This file replaced `app_selected_ink_test.dart` at M100.22, and the
/// replacement is the point. That file asserted that the pill, the navigation
/// glyph and the navigation label all resolve to *one* selected ink. They do
/// not, in Material 3: `_ChoiceChipDefaultsM3` inks a selected label with
/// `onSecondaryContainer`, `_NavigationBarDefaultsM3` inks the active glyph
/// with `onSecondaryContainer` and the active *label* with `onSurface`, because
/// the glyph sits inside the indicator and the label sits below it. Pinning
/// them equal was a house rule holding three components off their own defaults,
/// and the suite would have failed anyone who corrected them.
///
/// **What this file actually proves, and what it does not.** Every expectation
/// is `expect(slot, scheme.someRole)`, which compares the *resolved colour* —
/// `scheme.someRole` evaluates to a `Color` like any other. That is a real
/// check and it is not an identity guard, because two roles can carry one
/// value: until M100.25 `surfaceContainerHighest` and `secondaryContainer`
/// were the same `#332F58` in dark, so a switch re-pointed from one to the
/// other passed every assertion here. Demonstrated, not assumed — the fault
/// injection is recorded in the M100.23 WBS entry.
///
/// The identity half lives in `m3_role_binding_guard_test.dart`, which parses
/// the theme sources and asks which role the code *names*. The two are meant to
/// be read together: this one catches a value that drifted, that one catches a
/// role that drifted.
///
/// **And state combinations live in `m3_combined_state_test.dart`.** This file
/// asks `{}` and `{selected}` only, which is the answer a resolver gives last —
/// the failures were all in `{selected, focused}`, where a `focused` branch sat
/// above the `selected` one.
///
/// Contrast is asserted elsewhere again — `app_theme_test.dart`,
/// `app_palette_test.dart`, the visual audit — against the palette. That is the
/// division this project works to: **the role belongs to the component, the
/// number belongs to the palette.** A pairing that fails is fixed by moving a
/// tone, never by moving a component to a role that measures better.
///
/// The authority for every row below is the pinned SDK's `_XxxDefaultsM3`
/// class, read at 3.44.8 — not the Material website and not a blog. There is no
/// escape hatch in this file on purpose: a component that needs to depart has
/// to change this contract, in a diff that says so, rather than quietly
/// resolving to something else.
void main() {
  for (final (String mode, ThemeData Function() build)
      in <(String, ThemeData Function())>[
        ('light', buildLightTheme),
        ('dark', buildDarkTheme),
      ]) {
    group('$mode · component slot resolves its canonical M3 role', () {
      final ThemeData theme = build();
      final ColorScheme scheme = theme.colorScheme;

      const Set<WidgetState> selected = <WidgetState>{WidgetState.selected};
      const Set<WidgetState> resting = <WidgetState>{};

      void pin(String slot, Object? actual, Color role) =>
          expect(actual, role, reason: '$mode: $slot');

      test('NavigationBar', () {
        final t = theme.navigationBarTheme;

        pin('backgroundColor', t.backgroundColor, scheme.surfaceContainer);
        pin('indicatorColor', t.indicatorColor, scheme.secondaryContainer);
        pin(
          'selected icon',
          t.iconTheme!.resolve(selected)!.color,
          scheme.onSecondaryContainer,
        );
        pin(
          'unselected icon',
          t.iconTheme!.resolve(resting)!.color,
          scheme.onSurfaceVariant,
        );
        pin(
          'selected label',
          t.labelTextStyle!.resolve(selected)!.color,
          scheme.onSurface,
        );
        pin(
          'unselected label',
          t.labelTextStyle!.resolve(resting)!.color,
          scheme.onSurfaceVariant,
        );
      });

      test('ChoiceChip', () {
        final t = theme.chipTheme;
        final label = t.labelStyle!.color! as WidgetStateColor;

        pin(
          'selected fill',
          t.color!.resolve(selected),
          scheme.secondaryContainer,
        );
        pin(
          'unselected fill',
          t.color!.resolve(resting),
          scheme.surfaceContainerLow,
        );
        pin(
          'selected label',
          label.resolve(selected),
          scheme.onSecondaryContainer,
        );
        pin(
          'unselected label',
          label.resolve(resting),
          scheme.onSurfaceVariant,
        );
        pin(
          'unselected outline',
          (t.side! as WidgetStateBorderSide).resolve(resting)!.color,
          scheme.outlineVariant,
        );
        pin(
          'selected outline',
          (t.side! as WidgetStateBorderSide).resolve(selected)!.color,
          Colors.transparent,
        );
      });

      test('SegmentedButton', () {
        final s = theme.segmentedButtonTheme.style!;

        pin(
          'selected background',
          s.backgroundColor!.resolve(selected),
          scheme.secondaryContainer,
        );
        pin(
          'selected foreground',
          s.foregroundColor!.resolve(selected),
          scheme.onSecondaryContainer,
        );
        pin(
          'unselected foreground',
          s.foregroundColor!.resolve(resting),
          scheme.onSurface,
        );
        pin('side', s.side!.resolve(resting)!.color, scheme.outline);
      });

      test('OutlinedButton', () {
        final s = theme.outlinedButtonTheme.style!;

        pin('foreground', s.foregroundColor!.resolve(resting), scheme.primary);
        pin('side', s.side!.resolve(resting)!.color, scheme.outline);
      });

      test('Switch', () {
        final t = theme.switchTheme;

        pin('off thumb', t.thumbColor!.resolve(resting), scheme.outline);
        pin('on thumb', t.thumbColor!.resolve(selected), scheme.onPrimary);
        pin(
          'off track',
          t.trackColor!.resolve(resting),
          scheme.surfaceContainerHighest,
        );
        pin('on track', t.trackColor!.resolve(selected), scheme.primary);
        pin(
          'off track outline',
          t.trackOutlineColor!.resolve(resting),
          scheme.outline,
        );
        pin(
          'on track outline',
          t.trackOutlineColor!.resolve(selected),
          Colors.transparent,
        );
      });

      test('Checkbox', () {
        final t = theme.checkboxTheme;

        pin('ticked fill', t.fillColor!.resolve(selected), scheme.primary);
        pin('tick', t.checkColor!.resolve(resting), scheme.onPrimary);
        pin(
          'unticked edge',
          (t.side! as WidgetStateBorderSide).resolve(resting)!.color,
          scheme.onSurfaceVariant,
        );
        // Width, not colour: `_CheckboxDefaultsM3.side` returns a zero-width
        // transparent side when selected and the app returns `BorderSide.none`,
        // which is zero-width opaque black. Both draw nothing; only the width
        // says so, and a colour pin here would fail a correct implementation.
        expect(
          (t.side! as WidgetStateBorderSide).resolve(selected)!.width,
          0,
          reason: '$mode: a ticked box draws no edge',
        );
      });

      test('Radio', () {
        final t = theme.radioTheme;

        pin('selected', t.fillColor!.resolve(selected), scheme.primary);
        pin(
          'unselected',
          t.fillColor!.resolve(resting),
          scheme.onSurfaceVariant,
        );
      });

      test('Slider', () {
        final t = theme.sliderTheme;

        pin('active track', t.activeTrackColor, scheme.primary);
        pin('inactive track', t.inactiveTrackColor, scheme.secondaryContainer);
        pin('thumb', t.thumbColor, scheme.primary);
        pin('active tick', t.activeTickMarkColor, scheme.onPrimary);
        pin(
          'inactive tick',
          t.inactiveTickMarkColor,
          scheme.onSecondaryContainer,
        );
        pin('value indicator', t.valueIndicatorColor, scheme.inverseSurface);
      });

      test('ProgressIndicator', () {
        final t = theme.progressIndicatorTheme;

        pin('color', t.color, scheme.primary);
        pin('linear track', t.linearTrackColor, scheme.secondaryContainer);
      });

      test('TextField', () {
        final t = theme.inputDecorationTheme;

        pin(
          'enabled border',
          t.enabledBorder!.borderSide.color,
          scheme.outline,
        );
        pin(
          'focused border',
          t.focusedBorder!.borderSide.color,
          scheme.primary,
        );
        pin('error border', t.errorBorder!.borderSide.color, scheme.error);
      });

      test('Dialog', () {
        pin(
          'backgroundColor',
          theme.dialogTheme.backgroundColor,
          scheme.surfaceContainerHigh,
        );
      });

      test('BottomSheet', () {
        final t = theme.bottomSheetTheme;

        pin('backgroundColor', t.backgroundColor, scheme.surfaceContainerLow);
        pin(
          'drag handle',
          (t.dragHandleColor! as WidgetStateProperty<Color?>).resolve(resting),
          scheme.onSurfaceVariant,
        );
      });

      test('TimePicker', () {
        final t = theme.timePickerTheme;

        pin('backgroundColor', t.backgroundColor, scheme.surfaceContainerHigh);
        pin(
          'dial background',
          t.dialBackgroundColor,
          scheme.surfaceContainerHighest,
        );
        pin('dial hand', t.dialHandColor, scheme.primary);
        pin(
          'selected hour/minute',
          (t.hourMinuteColor! as WidgetStateColor).resolve(selected),
          scheme.primaryContainer,
        );
        pin(
          'resting hour/minute',
          (t.hourMinuteColor! as WidgetStateColor).resolve(resting),
          scheme.surfaceContainerHighest,
        );
      });

      test('DatePicker', () {
        final t = theme.datePickerTheme;

        pin('backgroundColor', t.backgroundColor, scheme.surfaceContainerHigh);
        pin(
          'selected day fill',
          t.dayBackgroundColor!.resolve(selected),
          scheme.primary,
        );
        pin(
          'selected day ink',
          t.dayForegroundColor!.resolve(selected),
          scheme.onPrimary,
        );
        pin(
          'selected year fill',
          t.yearBackgroundColor!.resolve(selected),
          scheme.primary,
        );
        pin(
          'selected year ink',
          t.yearForegroundColor!.resolve(selected),
          scheme.onPrimary,
        );
        pin(
          'range selection',
          t.rangeSelectionBackgroundColor,
          scheme.secondaryContainer,
        );
      });

      test('PopupMenu', () {
        pin('color', theme.popupMenuTheme.color, scheme.surfaceContainer);
      });

      test('Divider', () {
        pin('color', theme.dividerTheme.color, scheme.outlineVariant);
      });

      test('TextButton', () {
        final s = theme.textButtonTheme.style!;

        pin('foreground', s.foregroundColor!.resolve(resting), scheme.primary);
        pin('icon', s.iconColor!.resolve(resting), scheme.primary);
      });

      test('TabBar', () {
        final t = theme.tabBarTheme;

        pin('label', t.labelColor, scheme.primary);
        pin(
          'unselected label',
          t.unselectedLabelColor,
          scheme.onSurfaceVariant,
        );
        pin('indicator', t.indicatorColor, scheme.primary);
        pin('divider', t.dividerColor, scheme.outlineVariant);
      });
    });
  }

  group('the selected state is not one ink', () {
    test('the three selected slots resolve three different roles', () {
      // The inverse of what `app_selected_ink_test.dart` pinned, and the reason
      // this file exists. If a future change collapses these back onto one
      // token "for consistency", this fails and says which M3 default it broke.
      final theme = buildLightTheme();
      final scheme = theme.colorScheme;
      const selected = <WidgetState>{WidgetState.selected};

      final chipLabel = (theme.chipTheme.labelStyle!.color! as WidgetStateColor)
          .resolve(selected);
      final navGlyph = theme.navigationBarTheme.iconTheme!
          .resolve(selected)!
          .color;
      final navLabel = theme.navigationBarTheme.labelTextStyle!
          .resolve(selected)!
          .color;

      expect(chipLabel, scheme.onSecondaryContainer);
      expect(navGlyph, scheme.onSecondaryContainer);
      expect(
        navLabel,
        isNot(navGlyph),
        reason:
            'the active tab label sits on the bar, not in the indicator — M3 '
            'inks it `onSurface` and the glyph `onSecondaryContainer`',
      );
      expect(navLabel, scheme.onSurface);
    });
  });
}
