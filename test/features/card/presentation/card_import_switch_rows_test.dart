import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_sizing.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_switch.dart';
import 'package:memox/shared/widgets/mx_switch_row.dart';

import 'support/card_import_wizard_harness.dart';

/// The import preview's two switch rows, pinned where they are built.
///
/// `MxSwitchRow` became an `InkWell` row painting `MxSwitch` in M100.92, and
/// only the reminder screen measured it at a call site. The preview's header
/// toggle and duplicate policy are the other two production rows, so they get
/// the same claims at a phone and at 320dp × 2.0, in English and Vietnamese:
/// the 48 target, the 44 × 26 switch inside the row and beside its label, one
/// toggled node, and a tap on the painted switch reaching the row.
void main() {
  final h = installCardImportWizardHarness();
  const double epsilon = 0.5;

  Future<void> preview(WidgetTester tester, AppLocalizations l10n) async {
    await tester.tap(find.text(l10n.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'front,back\n사과,apple\n');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.cardImportPreviewAction));
    await tester.pumpAndSettle();
  }

  Future<void> expectSwitchRow(WidgetTester tester, String label) async {
    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(MxSwitchRow),
    );
    expect(row, findsOneWidget, reason: '"$label" is not an MxSwitchRow');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();

    final paint = find.descendant(of: row, matching: find.byType(MxSwitch));
    final rowRect = tester.getRect(row);
    final switchRect = tester.getRect(paint);
    final labelRect = tester.getRect(find.text(label));

    expect(
      rowRect.height,
      greaterThanOrEqualTo(AppSizing.touchTarget - epsilon),
      reason: '"$label": the row is the target',
    );
    expect(
      switchRect.size,
      const Size(AppSizing.switchTrackWidth, AppSizing.switchTrackHeight),
    );
    expect(switchRect.right, lessThanOrEqualTo(rowRect.right + epsilon));
    expect(
      switchRect.center.dy,
      moreOrLessEquals(rowRect.center.dy, epsilon: epsilon),
      reason: '"$label": the switch centres on the row as the label wraps',
    );
    expect(
      labelRect.right,
      lessThanOrEqualTo(switchRect.left + epsilon),
      reason: '"$label": the label runs into the switch',
    );

    final node = tester.getSemantics(row);
    expect(node.label, label);
    expect(node.flagsCollection.isToggled, isNot(Tristate.none));
    expect(node.flagsCollection.isEnabled, Tristate.isTrue);

    final wasOn = tester.widget<MxSwitch>(paint).isOn;
    await tester.tap(paint);
    await tester.pumpAndSettle();
    final after = find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(MxSwitchRow),
      ),
      matching: find.byType(MxSwitch),
    );
    expect(
      tester.widget<MxSwitch>(after).isOn,
      !wasOn,
      reason: '"$label": a tap on the painted switch did not reach the row',
    );
  }

  for (final (String name, Locale locale, AppLocalizations l10n)
      in <(String, Locale, AppLocalizations)>[
        ('en', const Locale('en'), AppLocalizationsEn()),
        ('vi', const Locale('vi'), AppLocalizationsVi()),
      ]) {
    for (final (Size surface, double scale) in const <(Size, double)>[
      (Size(390, 844), 1),
      (Size(320, 852), 2),
    ]) {
      testWidgets('$name · ${surface.width.toInt()}dp × $scale: the header and '
          'duplicate rows keep their target, switch and one toggled node', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await h.pump(
          tester,
          surface: surface,
          textScale: scale,
          locale: locale,
        );
        await preview(tester, l10n);
        expect(tester.takeException(), isNull);

        await expectSwitchRow(tester, l10n.cardImportHeaderToggleLabel);
        await expectSwitchRow(tester, l10n.cardImportIncludeDuplicatesLabel);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  }
}
