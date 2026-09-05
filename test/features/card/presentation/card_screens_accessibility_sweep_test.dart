import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'support/card_detail_geometry.dart';
import 'support/card_detail_harness.dart';
import 'support/card_editor_harness.dart';
import 'support/card_import_wizard_harness.dart';
import 'support/fake_card_repository.dart';
import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// A20.1 P2-17 — every `card` screen under the accessibility guidelines the
/// other features already sweep: 48 dp targets and labelled targets.
void main() {
  Future<void> sweep(WidgetTester tester) async {
    final handle = tester.ensureSemantics();
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    // Contrast is deliberately not swept here: `textContrastGuideline`
    // samples rendered pixels, and on a 12px line most glyph pixels are only
    // partially covered — `settings_accessibility_test.dart` records it
    // reporting 1.35:1 on a pair that measures 7.0:1. Every ink this screen
    // writes in is measured from the tokens by the contrast suites under
    // `test/core/theme/`.
    handle.dispose();
  }

  testWidgets('card list, loaded', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const CardListScreen(deckId: 'deck-1'),
        ),
      ),
    );
    repository.emitItems(
      <dynamic>[repository.listItem('c1'), repository.listItem('c2')].cast(),
    );
    repository.emitCount(2);
    await tester.pumpAndSettle();
    await sweep(tester);
  });

  testWidgets('card detail, loaded', (tester) async {
    await pumpCardDetail(tester, loaded());
    await tester.pumpAndSettle();
    await sweep(tester);
  });

  testWidgets('card editor, editing', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.cardToGet = repository.card('card-1');
    await pumpCardEditor(tester, repository);
    await tester.pumpAndSettle();
    await sweep(tester);
  });

  // **The other mode of the same screen, which the sweep never mounted.** Every
  // accessibility measurement taken on the editor was taken on edit, so a fix
  // made there — the save failure's live region — sat unmade in create for as
  // long as it took someone to read both files side by side (SC-C3-03).
  testWidgets('card editor, creating', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pumpCardEditor(tester, repository, cardId: null);
    await tester.pumpAndSettle();
    await sweep(tester);
  });

  final importHarness = installCardImportWizardHarness();

  testWidgets('card import, first step', (tester) async {
    await importHarness.pump(tester);
    await tester.pumpAndSettle();
    await sweep(tester);
  });

  testWidgets('tag catalog, populated', (tester) async {
    await pumpTagSurface(
      tester,
      home: const TagCatalogScreen(),
      catalog: FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[
        TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 12),
        TagCatalogEntry(id: 't2', name: 'food', cardCount: 1),
      ]),
    );
    await tester.pumpAndSettle();
    await sweep(tester);
  });
}
