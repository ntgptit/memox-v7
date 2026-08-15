import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/domain/models/app_settings_model.dart';
import 'package:memox/features/settings/domain/models/app_theme_mode_model.dart';
import 'package:memox/features/settings/presentation/widgets/items/settings_error_band_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_confirm_dialog.dart';

import '../domain/support/fake_app_settings_repository.dart';
import 'support/settings_widget_harness.dart';

/// `Reset to defaults` and its confirmation (BR-217, UC-16 A3, wireframe W4).
void main() {
  final english = AppLocalizationsEn();

  Future<void> openReset(WidgetTester tester) async {
    await tester.ensureVisible(find.text(english.settingsResetAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.settingsResetAction));
    await tester.pumpAndSettle();
  }

  testWidgets('the confirmation names what it does not touch', (tester) async {
    // The whole point of the sentence: this app has a second action whose name
    // begins with "Reset" and it clears every card's schedule (BR-42).
    await pumpSettings(tester, FakeAppSettingsRepository());

    await openReset(tester);

    expect(find.byType(MxConfirmDialog), findsOneWidget);
    expect(find.text(english.settingsResetConfirmTitle), findsOneWidget);
    expect(find.text(english.settingsResetDescription), findsWidgets);
  });

  testWidgets('cancelling writes nothing', (tester) async {
    final repository = FakeAppSettingsRepository(
      initial: AppSettingsModel.defaults.copyWith(themeMode: AppThemeMode.dark),
    );
    await pumpSettings(tester, repository);

    await openReset(tester);
    await tester.tap(find.text(english.commonCancelAction));
    await tester.pumpAndSettle();

    expect(find.byType(MxConfirmDialog), findsNothing);
    expect(repository.resetCount, 0);
    expect(repository.current.themeMode, AppThemeMode.dark);
  });

  testWidgets('confirming resets and closes the dialog', (tester) async {
    final repository = FakeAppSettingsRepository(
      initial: AppSettingsModel.defaults.copyWith(themeMode: AppThemeMode.dark),
    );
    await pumpSettings(tester, repository);

    await openReset(tester);
    await tester.tap(find.text(english.settingsResetConfirmAction));
    await tester.pumpAndSettle();

    expect(find.byType(MxConfirmDialog), findsNothing);
    expect(repository.current, AppSettingsModel.defaults);
  });

  testWidgets('the dialog opens again after a successful reset', (
    tester,
  ) async {
    // The latched outcome from the previous attempt would otherwise close the
    // second dialog on its own first frame — a control that stops working
    // after one use, with nothing on screen to explain it.
    final repository = FakeAppSettingsRepository();
    await pumpSettings(tester, repository);

    await openReset(tester);
    await tester.tap(find.text(english.settingsResetConfirmAction));
    await tester.pumpAndSettle();
    await openReset(tester);

    expect(find.byType(MxConfirmDialog), findsOneWidget);
  });

  testWidgets('a failed reset closes the dialog and shows a band with a '
      'retry', (tester) async {
    // W4: the dialog does not stay open to carry the failure — the decision
    // has already been made, and the band is where a retry belongs.
    await pumpSettings(tester, FailingAppSettingsRepository());

    await openReset(tester);
    await tester.tap(find.text(english.settingsResetConfirmAction));
    await tester.pumpAndSettle();

    // **The dialog is gone, asserted first.** `DialogRoute` is not opaque, so
    // the route beneath it stays on stage — the band and its retry are findable
    // whether or not the dialog closed, and this test passed against a build
    // where it never did. That is exactly the failure its name describes.
    expect(find.byType(MxConfirmDialog), findsNothing);
    expect(find.byType(SettingsErrorBandWidget), findsOneWidget);
    expect(find.text(english.retryAction), findsOneWidget);

    // **The Retry takes the band's ink, read off the widget.** `MxTextButton`
    // defaults to `primaryAccent`, which is right on a page and measures
    // 3.72:1 on `errorContainer` in dark. Asserting the token pair instead
    // would stay green if the accent were dropped, because the band's *text*
    // uses that pair either way.
    final BuildContext bandContext = tester.element(
      find.byType(SettingsErrorBandWidget),
    );
    final ButtonStyle? style = tester
        .widget<TextButton>(
          find.descendant(
            of: find.byType(SettingsErrorBandWidget),
            matching: find.byType(TextButton),
          ),
        )
        .style;
    expect(
      style?.foregroundColor?.resolve(<WidgetState>{}),
      Theme.of(bandContext).colorScheme.onErrorContainer,
    );
  });
}
