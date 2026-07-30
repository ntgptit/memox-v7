import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';

void main() {
  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();

  /// Builds the real app under a forced locale.
  ///
  /// `MemoxApp` owns the delegates and the resolution callback, so driving the
  /// locale through `tester.platformDispatcher` exercises the same path a real
  /// device takes rather than a test-only shortcut.
  ///
  /// The home route reads decks, so the repository is faked with an empty tree:
  /// the empty state is the one that renders localized prose without depending
  /// on any fixture content.
  Future<void> pumpAppInLocale(WidgetTester tester, Locale locale) async {
    tester.platformDispatcher.localesTestValue = <Locale>[locale];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
        ],
        child: const MemoxApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('locale resolution', () {
    testWidgets('en renders the English string', (tester) async {
      await pumpAppInLocale(tester, const Locale('en'));

      expect(find.text(en.decksEmptyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('vi renders the Vietnamese string', (tester) async {
      await pumpAppInLocale(tester, const Locale('vi'));

      expect(find.text(vi.decksEmptyTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an unsupported locale falls back to en, not to a blank', (
      tester,
    ) async {
      await pumpAppInLocale(tester, const Locale('ja'));

      // The failure this guards against is a silently empty screen: an
      // unresolved locale renders nothing rather than announcing itself.
      expect(find.text(en.decksEmptyTitle), findsOneWidget);
      expect(find.text(''), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a supported language with an unknown country still resolves', (
      tester,
    ) async {
      await pumpAppInLocale(tester, const Locale('vi', 'US'));

      expect(find.text(vi.decksEmptyTitle), findsOneWidget);
    });
  });

  group('generated bindings', () {
    test('both locales are advertised as supported', () {
      final languages = AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet();

      expect(languages, containsAll(<String>['en', 'vi']));
    });

    test('every string differs between en and vi except the product name', () {
      // appTitle is deliberately identical — it is a product name, not prose.
      expect(en.appTitle, vi.appTitle);

      expect(en.decksTitle, isNot(vi.decksTitle));
      expect(en.decksLoadingLabel, isNot(vi.decksLoadingLabel));
      expect(en.decksEmptyTitle, isNot(vi.decksEmptyTitle));
      expect(en.decksEmptyMessage, isNot(vi.decksEmptyMessage));
      expect(en.decksLoadErrorTitle, isNot(vi.decksLoadErrorTitle));
      expect(en.decksLoadErrorMessage, isNot(vi.decksLoadErrorMessage));
      expect(en.retryAction, isNot(vi.retryAction));
      expect(en.startupErrorTitle, isNot(vi.startupErrorTitle));
      expect(en.startupErrorMessage, isNot(vi.startupErrorMessage));
      expect(en.unexpectedErrorTitle, isNot(vi.unexpectedErrorTitle));
      expect(en.unexpectedErrorMessage, isNot(vi.unexpectedErrorMessage));
    });
  });
}
