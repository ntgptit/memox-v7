import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/failures/tag_catalog_failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/shared/widgets/mx_action_button.dart';

import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// The delete confirmation (UC-18 A3, BR-235, wireframe M4.14 W5).
///
/// **The copy is the subject here, not the plumbing.** BR-235's rule is that a
/// user must not be able to read this dialog as "my cards will be deleted", and
/// the only way to hold that is to assert the words.
void main() {
  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'noun', cardCount: 12),
    TagCatalogEntry(id: 't2', name: 'lonely', cardCount: 1),
    TagCatalogEntry(id: 't3', name: 'unused', cardCount: 0),
  ];

  Future<void> openDelete(
    WidgetTester tester,
    FakeTagCatalogRepository catalog, {
    required String row,
  }) async {
    await pumpTagSurface(
      tester,
      home: const TagCatalogScreen(),
      catalog: catalog,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Actions for tag $row'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete tag'));
    await tester.pumpAndSettle();
  }

  testWidgets('the message names the count and says the cards stay', (
    tester,
  ) async {
    await openDelete(
      tester,
      FakeTagCatalogRepository.seeded(tags),
      row: 'noun',
    );

    expect(find.text('Delete tag?'), findsOneWidget);
    expect(
      find.text(
        '“noun” will be removed from 12 cards. The cards themselves '
        'stay.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('one card gets the singular, and still says it stays', (
    tester,
  ) async {
    await openDelete(
      tester,
      FakeTagCatalogRepository.seeded(tags),
      row: 'lonely',
    );

    expect(
      find.text('“lonely” will be removed from 1 card. The card itself stays.'),
      findsOneWidget,
    );
  });

  testWidgets('a tag on no card gets its own sentence, not a zero', (
    tester,
  ) async {
    await openDelete(
      tester,
      FakeTagCatalogRepository.seeded(tags),
      row: 'unused',
    );

    expect(
      find.text('“unused” is not on any card. Deleting it changes no cards.'),
      findsOneWidget,
    );
    expect(find.textContaining('0 cards'), findsNothing);
  });

  testWidgets('no wording implies a card is deleted, hidden or moved', (
    tester,
  ) async {
    await openDelete(
      tester,
      FakeTagCatalogRepository.seeded(tags),
      row: 'noun',
    );

    // The destructive action carries the noun, so the button cannot be read as
    // "delete these cards" (M4.14 T8).
    expect(find.text('Delete tag'), findsWidgets);
    expect(find.textContaining('delete your cards'), findsNothing);
    expect(find.textContaining('cards will be deleted'), findsNothing);
  });

  testWidgets('confirming submits the delete and closes', (tester) async {
    final catalog = FakeTagCatalogRepository.seeded(tags);
    await openDelete(tester, catalog, row: 'noun');

    await tester.tap(find.widgetWithText(MxActionButton, 'Delete tag').last);
    await tester.pumpAndSettle();

    expect(catalog.deleteCalls, <String>['t1']);
    expect(find.text('Delete tag?'), findsNothing);
  });

  testWidgets('cancelling deletes nothing', (tester) async {
    final catalog = FakeTagCatalogRepository.seeded(tags);
    await openDelete(tester, catalog, row: 'noun');

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(catalog.deleteCalls, isEmpty);
    expect(find.text('Delete tag?'), findsNothing);
  });

  testWidgets('a failure is appended, so the reassurance stays on screen', (
    tester,
  ) async {
    final catalog = FakeTagCatalogRepository.seeded(tags)
      ..nextFailure = const NotFoundFailure(
        message: 'gone',
        reason: TagCatalogProblem.tagMissing,
      );
    await openDelete(tester, catalog, row: 'noun');

    await tester.tap(find.widgetWithText(MxActionButton, 'Delete tag').last);
    await tester.pumpAndSettle();

    expect(find.text('Delete tag?'), findsOneWidget);
    // Both, in one body. Swapping the question out for the error took "The
    // cards themselves stay" off screen while the destructive button was still
    // there to press — the sentence a user needs most right after a failure.
    expect(find.textContaining('The cards themselves stay.'), findsOneWidget);
    expect(find.textContaining('That tag no longer exists.'), findsOneWidget);
  });
  testWidgets('the appended failure is announced, not just shown', (
    tester,
  ) async {
    // **The dialog stays open and only its body changes** (D26), so nothing
    // moves focus and nothing else tells a screen-reader user the delete
    // failed — they would hear the same sentence they already heard. The
    // banded failures elsewhere mark themselves this way; this is the third
    // shape, and it was the one still silent.
    final handle = tester.ensureSemantics();
    final catalog = FakeTagCatalogRepository.seeded(tags)
      ..nextFailure = const NotFoundFailure(
        message: 'gone',
        reason: TagCatalogProblem.tagMissing,
      );
    await openDelete(tester, catalog, row: 'noun');

    await tester.tap(find.widgetWithText(MxActionButton, 'Delete tag').last);
    await tester.pumpAndSettle();

    // `.at(1)`, the content `Text` the failure was appended to — not the
    // title, which never changes.
    expect(
      tester.getSemantics(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(Text),
            )
            .at(1),
      ),
      isSemantics(isLiveRegion: true),
    );
    handle.dispose();
  });
}
