import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'fake_card_repository.dart';
import 'fake_card_transfer_repositories.dart';

/// One wizard mounted per test, its three transfer contracts and the card
/// repository faked — shared by the wizard's two test files, which split at
/// the 400-line guard along the step boundary (source/preview vs commit).
final class CardImportWizardHarness {
  final AppLocalizationsEn english = AppLocalizationsEn();

  late FakeCardRepository cards;
  late FakeCardTransferRepository transfer;
  late FakeCardImportSourceRepository picker;
  late FakeCardImportCommitRepository importer;

  static const DeckContextModel deckContext = DeckContextModel(
    deckName: 'TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[
      DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
    ],
  );

  Future<void> pump(
    WidgetTester tester, {
    Size? surface,
    double textScale = 1,
    Locale? locale,
  }) async {
    if (surface != null) {
      tester.view.physicalSize = surface;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cardRepositoryProvider.overrideWithValue(cards),
          cardTransferRepositoryProvider.overrideWithValue(transfer),
          cardImportSourceRepositoryProvider.overrideWithValue(picker),
          cardImportRepositoryProvider.overrideWithValue(importer),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const CardImportScreen(deckId: 'deck-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder button(String label) => find.widgetWithText(FilledButton, label);

  Future<void> pasteAndPreview(WidgetTester tester, String text) async {
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardImportPreviewAction));
    await tester.pumpAndSettle();
  }
}

/// Registers fresh fakes per test and returns the harness the tests read.
CardImportWizardHarness installCardImportWizardHarness() {
  final harness = CardImportWizardHarness();
  setUp(() {
    harness.cards = FakeCardRepository.loaded(
      <dynamic>[FakeCardRepository().listItem('c1', front: '기존')].cast(),
      total: 1,
    )..deckContextToShow = CardImportWizardHarness.deckContext;
    harness.transfer = FakeCardTransferRepository();
    harness.picker = FakeCardImportSourceRepository();
    harness.importer = FakeCardImportCommitRepository();
  });
  tearDown(() => harness.cards.dispose());

  return harness;
}
