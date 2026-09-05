import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/failures/tag_validation_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/shared/widgets/mx_button_pair.dart';
import 'package:memox/shared/widgets/mx_feedback_band.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

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

    testWidgets('the failure is a band, and the primary offers the retry', (
      tester,
    ) async {
      // **Both halves were missing and nothing was red.** W4 item 6 asks for a
      // band with `Try again`; the sheet rendered a red line of text and left
      // the primary saying `Rename`, so the only way to retry was to notice the
      // button was still enabled and press the same word again. The test that
      // covered this state asserted only the message, which both versions show.
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

      // The band's own title, which only the band renders.
      expect(find.text('Couldn’t save'), findsOneWidget);
      // And the recovery, named, where the action was.
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Rename'), findsNothing);
    });
  });

  group('each gap binds to what it separates, not to one uniform value', () {
    // **The sheet used to set one `spacing:` for all four seams.** At `lg` the
    // merge disclosure — a sentence about the field directly above it — sat as
    // far from that field as the action row does, and the shared failure band
    // was promoted to a section of its own, where the export sheet it copied
    // the band from binds it to what it reports on. Measured rather than
    // eyeballed: a uniform value looks deliberate in a screenshot, which is
    // exactly why it survived.
    Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

    testWidgets('the merge notice binds to the field at sm', (tester) async {
      await openRename(tester, FakeTagCatalogRepository.seeded(tags));

      await tester.enterText(find.byType(TextField).last, 'noun');
      await tester.pumpAndSettle();

      final title = rectOf(tester, find.text('Rename tag'));
      final field = rectOf(tester, find.byType(MxTextField));
      // The notice is a `Semantics` over one `Row`; the row is its whole box.
      final notice = rectOf(
        tester,
        find
            .ancestor(of: find.byIcon(Icons.merge), matching: find.byType(Row))
            .first,
      );
      final actions = rectOf(tester, find.byType(MxButtonPair));

      expect(
        field.top - title.bottom,
        AppSpacing.lg,
        reason: 'form opens at lg',
      );
      expect(
        notice.top - field.bottom,
        AppSpacing.sm,
        reason: 'a notice describing the control above it binds tightest',
      );
      expect(
        actions.top - notice.bottom,
        AppSpacing.lg,
        reason: 'the action row closes the sheet at lg',
      );
    });

    testWidgets('the failure band binds to the field at md', (tester) async {
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

      final field = rectOf(tester, find.byType(MxTextField));
      final band = rectOf(tester, find.byType(MxFeedbackBand));
      final actions = rectOf(tester, find.byType(MxButtonPair));

      expect(
        band.top - field.bottom,
        AppSpacing.md,
        reason: 'the in-flow-failure gap five deck sheets already use',
      );
      expect(
        actions.top - band.bottom,
        AppSpacing.lg,
        reason: 'the band reports on the form, it is not a section of its own',
      );
    });

    testWidgets('the pristine sheet gains no stray gap', (tester) async {
      // The hazard of trading `spacing:` for explicit boxes: a gap written
      // outside its `if` opens a hole where nothing is rendered.
      await openRename(tester, FakeTagCatalogRepository.seeded(tags));

      final field = rectOf(tester, find.byType(MxTextField));
      final actions = rectOf(tester, find.byType(MxButtonPair));

      expect(actions.top - field.bottom, AppSpacing.lg);
    });
  });
}
