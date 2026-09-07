import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/startup/font_licenses.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import '../domain/support/fake_app_settings_repository.dart';
import 'support/settings_widget_harness.dart';

/// The licence obligation, and the row that discharges it.
///
/// **Three fonts shipped without their licence.** All three faces are SIL Open
/// Font License 1.1, which requires the licence to travel with the software.
/// `pubspec.yaml` declared the `.ttf` under `fonts:` — which bundles outlines
/// and nothing else — so the text files sat in the repository and never reached
/// a build. Nothing failed; the app was simply out of compliance, quietly.
void main() {
  final english = AppLocalizationsEn();

  testWidgets('the row is on Settings and opens the licence page', (
    tester,
  ) async {
    await pumpSettings(tester, FakeAppSettingsRepository());

    final row = find.text(english.settingsLicensesTitle);
    expect(row, findsOneWidget);

    // Scrolled to first: the row sits near the foot of a long screen, and
    // `tap` on an off-screen widget presses coordinates outside the viewport
    // and quietly does nothing — which reads as "the row is dead".
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    // Flutter's own page, so the assertion is that we reached *it* rather than
    // that some screen appeared: a hand-built copy would satisfy a text match.
    expect(find.byType(LicensePage), findsOneWidget);
  });

  testWidgets('and the fonts are registered, with their text', (tester) async {
    // A fresh registry per test binding, so this measures what
    // `registerFontLicenses` adds rather than what a previous test left.
    registerFontLicenses();

    final entries = <LicenseEntry>[];
    await tester.runAsync(() async {
      await for (final entry in LicenseRegistry.licenses) {
        entries.add(entry);
      }
    });

    final packages = entries.expand((e) => e.packages).toSet();
    for (final face in <String>['Inter', 'Plus Jakarta Sans', 'Noto Sans KR']) {
      expect(
        packages,
        contains(face),
        reason: '$face ships in the bundle, so its licence must ship with it',
      );
    }

    // The text, not just the name: a registered entry with an empty body would
    // list the face on the page and show nothing under it.
    final ours = entries.where((e) => e.packages.contains('Noto Sans KR'));
    expect(ours, isNotEmpty);
    // The whole entry, not its first paragraph: an OFL file opens with the
    // copyright line, and the licence it grants is further down.
    final text = ours.first.paragraphs.map((p) => p.text).join(' ');
    expect(
      text,
      contains('SIL Open Font License'),
      reason: 'the entry must carry the licence, not an empty section',
    );
  });
}
