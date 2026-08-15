import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';

import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// The rename sheet, including the merge disclosure (UC-18, BR-233, BR-234,
/// wireframe M4.14 W4).
void main() {
  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'nouns', cardCount: 3),
    TagCatalogEntry(id: 't2', name: 'Noun', cardCount: 5),
  ];

  Future<void> openRename(
    WidgetTester tester,
    FakeTagCatalogRepository catalog, {
    String row = 'nouns',
  }) async {
    await pumpTagSurface(
      tester,
      home: const TagCatalogScreen(),
      catalog: catalog,
    );
    await tester.pumpAndSettle();

    // The row's own menu, found through its tooltip so the tap cannot land on
    // a different row's button.
    await tester.tap(find.byTooltip('Actions for tag $row'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens prefilled with the current name', (tester) async {
    await openRename(tester, FakeTagCatalogRepository.seeded(tags));

    expect(find.text('Rename tag'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField).last);
    expect(field.controller?.text, 'nouns');
    // No collision yet, so the primary action is a rename.
    expect(find.text('Rename'), findsOneWidget);
    expect(find.text('Merge tags'), findsNothing);
  });

  testWidgets('a free name submits as a rename (BR-233)', (tester) async {
    final catalog = FakeTagCatalogRepository.seeded(tags);
    await openRename(tester, catalog);

    await tester.enterText(find.byType(TextField).last, 'substantives');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();

    expect(catalog.renameCalls.single.tagId, 't1');
    expect(catalog.renameCalls.single.name, 'substantives');
    expect(find.text('Rename tag'), findsNothing, reason: 'the sheet closed');
  });

  group('the merge disclosure appears before confirming (BR-234)', () {
    testWidgets('typing another tag name discloses the target and changes '
        'the action label', (tester) async {
      await openRename(tester, FakeTagCatalogRepository.seeded(tags));

      // `noun` folds onto the stored `Noun` — the collision BR-93 defines.
      await tester.enterText(find.byType(TextField).last, 'noun');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.merge), findsOneWidget);
      // The disclosure names the target rather than saying "this will merge".
      expect(find.textContaining('Noun'), findsWidgets);
      expect(find.text('Merge tags'), findsOneWidget);
      expect(find.text('Rename'), findsNothing);
    });

    testWidgets('changing only the case is not a merge (BR-233)', (
      tester,
    ) async {
      await openRename(tester, FakeTagCatalogRepository.seeded(tags));

      await tester.enterText(find.byType(TextField).last, 'Nouns');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.merge), findsNothing);
      expect(find.text('Rename'), findsOneWidget);
    });

    testWidgets('a name the field will refuse discloses nothing', (
      tester,
    ) async {
      await openRename(tester, FakeTagCatalogRepository.seeded(tags));

      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.merge), findsNothing);
    });

    testWidgets('the confirmation says what the transaction did, not what '
        'the form predicted', (tester) async {
      final catalog = FakeTagCatalogRepository.seeded(tags)
        ..renameOutcome = TagRenameOutcome.merged;
      await openRename(tester, catalog);

      await tester.enterText(find.byType(TextField).last, 'noun');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Merge tags'));
      await tester.pumpAndSettle();

      expect(find.textContaining('was merged'), findsOneWidget);
    });
  });

  group('failures keep the sheet open with what was typed', () {
    testWidgets('a validation problem lands under the field', (tester) async {
      final catalog = FakeTagCatalogRepository.seeded(tags)
        ..nextFailure = const ValidationFailure(
          message: 'invalid',
          problems: <Enum>{TagValidationProblem.nameTooLong},
        );
      await openRename(tester, catalog);

      await tester.enterText(find.byType(TextField).last, 'substantives');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Rename tag'), findsOneWidget, reason: 'still open');
      expect(find.text('Tag is at the character limit'), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField).last);
      expect(field.controller?.text, 'substantives');
    });

    testWidgets('a vanished tag gets its own line, not the generic one', (
      tester,
    ) async {
      final catalog = FakeTagCatalogRepository.seeded(tags)
        ..nextFailure = const NotFoundFailure(
          message: 'gone',
          reason: TagCatalogProblem.tagMissing,
        );
      await openRename(tester, catalog);

      await tester.enterText(find.byType(TextField).last, 'substantives');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('That tag no longer exists.'), findsOneWidget);
    });
  });
}
