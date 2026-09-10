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
import 'package:memox/l10n/generated/app_localizations_en.dart';

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
        TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 12, linkedCardCount: 12),
        TagCatalogEntry(id: 't2', name: 'food', cardCount: 1, linkedCardCount: 1),
      ]),
    );
    await tester.pumpAndSettle();
    await sweep(tester);
  });

  // **A sheet is a new surface, and its title is that surface's name.**
  //
  // The durable half of SC-C4-21. Two card sheets set their title as a bare
  // `Text`, so a reader met the name of a surface that had just opened as an
  // ordinary sentence and had nothing to jump to. Each fix is also pinned
  // beside the rest of its own sheet's anatomy; what is *here* is the grammar,
  // and this is the group a newly-added sheet joins.
  //
  // It cannot live in `mx_sheet_test.dart`, which is where the rule is written
  // down: that file asserts `isHeader` on `MxSheetHeader`, and only a
  // `showMxSheet` call reaches it. A sheet opened through `showMxFormSheet`
  // builds its own title inside the feature, and nothing was watching those —
  // which is precisely the pair that drifted.
  group('a sheet names itself as a heading (A20.1 P1-01)', () {
    final english = AppLocalizationsEn();

    void expectHeading(WidgetTester tester, String title) {
      final node = tester.getSemantics(find.text(title));
      expect(
        node.flagsCollection.isHeader,
        isTrue,
        reason: '"$title" names a surface that just opened',
      );
      expect(node.label, title);
    }

    testWidgets('filter by tags, from the card list', (tester) async {
      final handle = tester.ensureSemantics();
      final cards = FakeCardRepository.loaded(
        <dynamic>[FakeCardRepository().listItem('c1')].cast(),
        total: 1,
      );
      addTearDown(cards.dispose);
      await pumpTagSurface(
        tester,
        home: const CardListScreen(deckId: 'deck-1'),
        catalog: FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[
          TagCatalogEntry(id: 't1', name: 'noun', cardCount: 12, linkedCardCount: 12),
        ]),
        cards: cards,
      );
      await tester.pumpAndSettle();

      // By its glyph, not its label: once a filter is applied the pill carries
      // the count, so a text finder stops matching the control it just used.
      await tester.tap(find.byIcon(Icons.sell_outlined).first);
      await tester.pumpAndSettle();

      expectHeading(tester, english.tagFilterTitle);
      handle.dispose();
    });

    testWidgets('rename tag, from the tag catalog', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpTagSurface(
        tester,
        home: const TagCatalogScreen(),
        catalog: FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[
          TagCatalogEntry(id: 't1', name: 'nouns', cardCount: 3, linkedCardCount: 3),
        ]),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(english.tagRowMenuSemantics('nouns')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(english.tagRenameAction));
      await tester.pumpAndSettle();

      expectHeading(tester, english.tagRenameTitle);
      handle.dispose();
    });
  });
}
