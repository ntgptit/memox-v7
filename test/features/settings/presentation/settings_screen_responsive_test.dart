import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import '../domain/support/fake_app_settings_repository.dart';
import 'support/settings_widget_harness.dart';

/// The seven states of the Settings screen (UC-16, wireframe W3).
/// The Settings screen across **locales, themes and screen sizes**.
///
/// Split from `settings_screen_states_test.dart` at the guard's 400-line
/// ceiling. The seam is the subject: that file drives the screen's *states*
/// — loaded, loading, writing, failing, submitting — while this one pumps one
/// state through the shapes W6 requires it to survive.
void main() {
  final vietnamese = AppLocalizationsVi();

  group('locales', () {
    testWidgets('Vietnamese renders the Vietnamese headings', (tester) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
      );

      expect(
        find.text(vietnamese.settingsStudyDefaultsSection.toUpperCase()),
        findsOneWidget,
      );
      expect(
        find.text(vietnamese.settingsAppearanceSection.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('the two language names stay endonyms in both locales', (
      tester,
    ) async {
      // Somebody stuck in a language they cannot read has to be able to find
      // the name of their own (W2).
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
      );

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Tiếng Việt'), findsOneWidget);
    });
  });

  group('dark and small screens', () {
    testWidgets('renders in dark without overflowing', (tester) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        brightness: Brightness.dark,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('320dp at textScaler 2.0 in Vietnamese does not overflow', (
      tester,
    ) async {
      // The tightest combination the wireframe names (W6): the longest
      // Vietnamese label, doubled, on the narrowest supported surface.
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        locale: const Locale('vi'),
        surface: const Size(320, 568),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('412dp renders without overflowing', (tester) async {
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        surface: const Size(412, 892),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('keyboard open', () {
    testWidgets('the card-limit field stays reachable and Save is still '
        'in reach with the keyboard covering the bottom of the screen', (
      tester,
    ) async {
      // A number field on a scrolling screen is exactly where an unhandled
      // keyboard inset clips the one control it opened for — the field itself
      // stays on screen because it is what has focus, but a fixed-height
      // layout can still push Save behind the keyboard.
      await pumpSettings(
        tester,
        FakeAppSettingsRepository(),
        keyboardInset: 300,
      );

      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.byType(TextField).first);
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);

      await tester.ensureVisible(find.byType(MxActionButton));
      await tester.pumpAndSettle();

      final saveRect = tester.getRect(find.byType(MxActionButton));
      final viewport = tester.getRect(find.byType(MaterialApp));
      expect(saveRect.bottom, lessThanOrEqualTo(viewport.bottom));
      expect(saveRect.top, greaterThanOrEqualTo(viewport.top));
    });
  });
}
