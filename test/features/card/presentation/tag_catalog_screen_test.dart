import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/tag_catalog_row_widget.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import 'support/fake_tag_catalog_repository.dart';
import 'support/tag_catalog_harness.dart';

/// The tag catalog through every face of wireframe M4.14 W3 (UC-12, BR-182).
void main() {
  const tags = <TagCatalogEntry>[
    TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 12),
    TagCatalogEntry(id: 't2', name: 'food', cardCount: 1),
    TagCatalogEntry(id: 't3', name: 'TOPIK II', cardCount: 0),
  ];

  Future<void> pump(
    WidgetTester tester,
    FakeTagCatalogRepository catalog, {
    Locale locale = const Locale('en'),
  }) => pumpTagSurface(
    tester,
    home: const TagCatalogScreen(),
    catalog: catalog,
    locale: locale,
  );

  testWidgets('face 1 — a spinner before the first emission', (tester) async {
    await pump(tester, FakeTagCatalogRepository());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('face 2 — every tag with its count, and no create action', (
    tester,
  ) async {
    await pump(tester, FakeTagCatalogRepository.seeded(tags));
    await tester.pumpAndSettle();

    expect(find.byType(TagCatalogRowWidget), findsNWidgets(3));
    expect(find.text('động từ'), findsOneWidget);
    expect(find.text('12 cards'), findsOneWidget);
    expect(find.text('1 card'), findsOneWidget);
    // BR-182: a tag no card carries stays, and says so in words.
    expect(find.text('No cards'), findsOneWidget);
    // Nothing on this screen can create a tag (M4.14 W2 item 1).
    expect(find.byIcon(Icons.add), findsNothing);
  });

  testWidgets('face 3 — no tags at all, and no call to action', (tester) async {
    await pump(
      tester,
      FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[]),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tags yet'), findsOneWidget);
    // No search field either: filtering an empty list is a question with one
    // answer.
    expect(find.byType(MxSearchField), findsNothing);
    final empty = tester.widget<MxEmptyState>(find.byType(MxEmptyState));
    expect(empty.actionLabel, isNull, reason: 'nothing here creates a tag');
  });

  testWidgets('face 4 — a search that matches nothing names the term', (
    tester,
  ) async {
    final catalog = FakeTagCatalogRepository.seeded(tags);
    await pump(tester, catalog);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.textContaining('zzz'), findsWidgets);
    expect(find.byType(TagCatalogRowWidget), findsNothing);
    // The field stays, so the term can be corrected in place.
    expect(find.byType(MxSearchField), findsOneWidget);
  });

  testWidgets('face 5 — a failed read offers a retry, and hides the field', (
    tester,
  ) async {
    final catalog = FakeTagCatalogRepository();
    await pump(tester, catalog);

    catalog.emitError(const DatabaseFailure(message: 'nope'));
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byType(MxSearchField), findsNothing);
  });

  testWidgets('the search term reaches the read, not a Dart filter', (
    tester,
  ) async {
    final catalog = FakeTagCatalogRepository.seeded(tags);
    await pump(tester, catalog);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'độn');
    await tester.pumpAndSettle();

    // BR-182: the fold and the counts belong to the statement. A screen that
    // filtered its cached list would never ask.
    expect(catalog.requestedSearchTerms, contains('độn'));
    expect(find.byType(TagCatalogRowWidget), findsOneWidget);
  });

  testWidgets('VI renders the catalog in Vietnamese', (tester) async {
    await pump(
      tester,
      FakeTagCatalogRepository.seeded(tags),
      locale: const Locale('vi'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nhãn'), findsOneWidget);
    expect(find.text('12 thẻ'), findsOneWidget);
    expect(find.text('Không có thẻ nào'), findsOneWidget);
  });
}
