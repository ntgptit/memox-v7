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
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../features/settings/domain/support/fake_app_settings_repository.dart';

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
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
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
      // Excluding editable text: an empty search field is legitimately empty,
      // and the failure this guards against is a *label* that resolved to
      // nothing. Without the exclusion the guard fires on the one widget on the
      // screen that is supposed to start blank.
      expect(
        find.descendant(
          of: find.byType(MaterialApp),
          matching: find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == '',
          ),
        ),
        findsNothing,
      );
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

  group('the delete-impact sentence is a sentence', () {
    // BR-04 makes this string state exactly what goes with the deck, so it is
    // assembled from two plurals. Assembly is where it broke: the sub-deck arm
    // contributes nothing at zero, which left the card arm starting the
    // sentence in lower case, and left its verb agreeing with a subject that
    // was no longer there.
    //
    // Neither is visible to any other gate. `arb_parity_test` checks that both
    // languages have the key; the guard reads Dart, not ICU; and a golden of an
    // empty deck's confirm dialog matched the day it was first drawn wrong.
    final en = AppLocalizationsEn();
    final vi = AppLocalizationsVi();

    test('it starts with a capital when there are no sub-decks', () {
      // The common case: deleting an empty deck. It read `no cards go to Trash
      // with it.`
      expect(en.deckDeleteImpactMessage(0, 0), startsWith('No cards'));
      expect(en.deckDeleteImpactMessage(0, 1), startsWith('1 card'));
      expect(en.deckDeleteImpactMessage(0, 5), startsWith('5 cards'));
      expect(vi.deckDeleteImpactMessage(0, 0), startsWith('Không có thẻ nào'));
    });

    test('the verb agrees with what is actually going to Trash', () {
      // One card alone `goes`; one card *and* a sub-deck `go`. It said `1 card
      // go to Trash with it.`
      expect(en.deckDeleteImpactMessage(0, 1), contains('1 card goes to'));
      expect(en.deckDeleteImpactMessage(0, 2), contains('2 cards go to'));
      expect(
        en.deckDeleteImpactMessage(1, 1),
        contains('1 sub-deck and 1 card go to'),
      );
    });

    test('it still names both counts exactly (BR-04)', () {
      expect(
        en.deckDeleteImpactMessage(4, 570),
        startsWith('4 sub-decks and 570 cards go to Trash'),
      );
      expect(
        vi.deckDeleteImpactMessage(4, 570),
        startsWith('4 bộ thẻ con và 570 thẻ vào Trash'),
      );
    });
  });
}
