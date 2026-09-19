import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/typography/app_text_styles.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// `MxSettingsRow` typography, colour and semantics — split out of
/// `mx_settings_row_test.dart` at the repo's 400-line guard, the same split
/// `mx_list_tile_test.dart` / `mx_list_tile_contract_test.dart` already uses.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MxSettingsRow typography and colour', () {
    testWidgets('label is onSurface, sub is onSurfaceVariant', (tester) async {
      final theme = buildLightTheme();
      await pump(
        tester,
        const MxSettingsRow(label: 'Notifications', sub: 'Reminders'),
      );

      final label = tester.renderObject<RenderParagraph>(
        find.text('Notifications'),
      );
      final sub = tester.renderObject<RenderParagraph>(find.text('Reminders'));
      expect(label.text.style?.color, theme.colorScheme.onSurface);
      expect(sub.text.style?.color, theme.colorScheme.onSurfaceVariant);
    });

    testWidgets('label carries the settingsRowLabel role (16/600, -0.1px)', (
      tester,
    ) async {
      final theme = buildLightTheme();
      await pump(tester, const MxSettingsRow(label: 'Notifications'));

      final label = tester.renderObject<RenderParagraph>(
        find.text('Notifications'),
      );
      final expected = theme.extension<AppTextStyles>()!.settingsRowLabel;
      expect(label.text.style?.fontSize, expected.fontSize);
      expect(label.text.style?.letterSpacing, expected.letterSpacing);
    });

    testWidgets('chevron is onSurfaceVariant', (tester) async {
      final theme = buildLightTheme();
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));

      final chevron = tester.widget<Icon>(find.byIcon(Icons.chevron_right));
      expect(chevron.color, theme.colorScheme.onSurfaceVariant);
    });
  });

  group('MxSettingsRow semantics', () {
    testWidgets('a navigable row is exposed as a labelled button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, MxSettingsRow(label: 'Theme', onTap: () {}));

      expect(
        tester.getSemantics(find.byType(MxSettingsRow)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: 'Theme',
        ),
      );
      handle.dispose();
    });

    testWidgets('a static row (no onTap) is not exposed as a button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const MxSettingsRow(label: 'App version'));

      expect(
        tester
            .getSemantics(find.byType(MxSettingsRow))
            .flagsCollection
            .isButton,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets(
      'a disabled control-shaped row still reads as a (disabled) button — '
      'distinct from a genuinely static row',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          MxSettingsRow(label: 'Theme', isEnabled: false, onTap: () {}),
        );

        expect(
          tester.getSemantics(find.byType(MxSettingsRow)),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            // `isEnabled` defaults to `false` — left implicit here, unlike
            // the navigable test above, which must state it explicitly.
            label: 'Theme',
          ),
        );
        handle.dispose();
      },
    );
  });
}
