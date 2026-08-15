@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/tag_catalog_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/models/tag_catalog_entry_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/screens/tag_catalog_screen.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_pill_button.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/card/presentation/support/fake_tag_catalog_repository.dart';
import '../support/study_render.dart';

/// DEMO renders (not assertions) of Tag Management (UC-18, wireframe M4.14):
/// device-faithful PNGs for design review, driven through the real screens with
/// the two repositories faked. Run with:
///   flutter test --update-goldens --tags golden test/demo/tag_management_demo_test.dart
///
/// **Every face the wireframe names gets one**, because the three defects a
/// wireframe cannot catch are all visual: a merge disclosure that reads as an
/// error, a destructive dialog whose copy implies cards are lost, and a filter
/// sheet whose action row falls under the keyboard at 320dp.
const DeckContextModel _demoContext = DeckContextModel(
  deckName: 'Korean · TOPIK I',
  ancestors: <DeckBreadcrumbSegment>[
    DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
    DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
  ],
);

const List<TagCatalogEntry> _tags = <TagCatalogEntry>[
  TagCatalogEntry(id: 't1', name: 'động từ', cardCount: 42),
  TagCatalogEntry(id: 't2', name: 'food', cardCount: 12),
  TagCatalogEntry(id: 't3', name: 'Noun', cardCount: 7),
  TagCatalogEntry(id: 't4', name: 'nouns', cardCount: 3),
  TagCatalogEntry(
    id: 't5',
    name: 'TOPIK II · vocabulary · chapter 3',
    cardCount: 1,
  ),
  TagCatalogEntry(id: 't6', name: 'unused', cardCount: 0),
];

void main() {
  final english = AppLocalizationsEn();

  late FakeCardRepository cards;
  late FakeTagCatalogRepository catalog;

  setUp(() {
    cards = FakeCardRepository.loaded(
      List<CardListItemModel>.generate(
        4,
        (index) => FakeCardRepository().listItem(
          'c$index',
          front: <String>['사과', '바다', '감사합니다', '산'][index],
          back: <String>['apple', 'sea', 'thank you', 'mountain'][index],
          tagNames: index.isEven
              ? <String>['food', 'động từ']
              : const <String>[],
        ),
      ),
      total: 128,
    )..deckContextToShow = _demoContext;
    // So the primary action shows a number that follows the selection (T6)
    // rather than the deck total, which would illustrate nothing.
    cards.tagFilterCounts
      ..[1] = 12
      ..[2] = 19;
    catalog = FakeTagCatalogRepository.seeded(_tags);
  });

  tearDown(() => cards.dispose());

  Widget scope(
    Widget home,
    Brightness brightness, {
    Locale? locale,
    double textScale = 1,
  }) => ProviderScope(
    overrides: [
      cardRepositoryProvider.overrideWithValue(cards),
      tagCatalogRepositoryProvider.overrideWithValue(catalog),
    ],
    child: ReviewApp(
      home: home,
      brightness: brightness,
      locale: locale,
      textScale: textScale,
    ),
  );

  Widget catalogScope(
    Brightness brightness, {
    Locale? locale,
    double textScale = 1,
  }) => scope(
    const TagCatalogScreen(),
    brightness,
    locale: locale,
    textScale: textScale,
  );

  /// Opens one row's menu, by position rather than by tooltip.
  ///
  /// **`byTooltip` raised the tooltip it searched for**, and a `Tooltip` is an
  /// overlay entry that outlives the tap: every rename and delete render came
  /// out with two grey slabs across the app bar that are not part of the design
  /// under review. Waiting the tooltip out was tried and does not clear them.
  /// The glyph is unambiguous once the row is named by index.
  Future<void> openRowMenu(WidgetTester tester, int row) async {
    await tester.tap(find.byIcon(Icons.more_vert).at(row));
    await tester.pumpAndSettle();
  }

  /// Opens the multi-tag filter from the pinned pill.
  ///
  /// Targets the pill, not its glyph: tapping the icon derives a point that
  /// lands on the label's `RenderParagraph` and prints a hit-test warning on
  /// every run — noise that a real miss would later hide behind.
  Future<void> openFilterSheet(WidgetTester tester) async {
    await tester.tap(
      find.ancestor(
        of: find.byIcon(Icons.sell_outlined),
        matching: find.byType(MxPillButton),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Ticks one row of the filter sheet.
  ///
  /// Scoped to the checkbox rows on purpose: the card list behind the sheet
  /// draws the same tag names as chips, so a bare text finder matches three
  /// widgets and taps the wrong one.
  Future<void> tickTag(WidgetTester tester, String tag) async {
    await tester.tap(
      find.descendant(
        of: find.byType(CheckboxListTile),
        matching: find.text(tag),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('catalog — populated, light', (tester) async {
    await pumpReview(tester, catalogScope(Brightness.light));

    await matchesReviewGolden('goldens/tag_catalog_light.png');
  });

  testWidgets('catalog — populated, dark', (tester) async {
    await pumpReview(tester, catalogScope(Brightness.dark));

    await matchesReviewGolden('goldens/tag_catalog_dark.png');
  });

  testWidgets('catalog — Vietnamese, so the plural and the title are read '
      'in the other locale', (tester) async {
    await pumpReview(
      tester,
      catalogScope(Brightness.light, locale: const Locale('vi')),
    );

    await matchesReviewGolden('goldens/tag_catalog_vi.png');
  });

  testWidgets('catalog — 320 at 2.0, where a row has to wrap', (tester) async {
    await pumpReview(
      tester,
      catalogScope(Brightness.light, textScale: 2),
      surface: const Size(320, 568),
    );

    await matchesReviewGolden('goldens/tag_catalog_320_x2.png');
  });

  testWidgets('catalog — no tags at all', (tester) async {
    catalog = FakeTagCatalogRepository.seeded(const <TagCatalogEntry>[]);
    await pumpReview(tester, catalogScope(Brightness.light));

    await matchesReviewGolden('goldens/tag_catalog_empty_light.png');
  });

  testWidgets('rename — the merge disclosure, before anything is confirmed', (
    tester,
  ) async {
    await pumpReview(tester, catalogScope(Brightness.light));
    // row 3 is `nouns`, which folds onto `Noun` above it.
    await openRowMenu(tester, 3);
    await tester.tap(find.text(english.tagRenameAction));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'noun');
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/tag_rename_merge_light.png');
  });

  testWidgets('delete — the confirmation that must not read as card loss', (
    tester,
  ) async {
    await pumpReview(tester, catalogScope(Brightness.light));
    // row 0 is `động từ`, the one with 42 cards.
    await openRowMenu(tester, 0);
    await tester.tap(find.text(english.tagDeleteAction));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/tag_delete_confirm_light.png');
  });

  testWidgets('filter — the sheet with two tags picked, over the card list', (
    tester,
  ) async {
    await pumpReview(
      tester,
      scope(const CardListScreen(deckId: 'demo'), Brightness.light),
    );
    await openFilterSheet(tester);
    await tickTag(tester, 'food');
    await tickTag(tester, 'Noun');

    await matchesReviewGolden('goldens/tag_filter_sheet_light.png');
  });

  testWidgets('filter — the same sheet in dark', (tester) async {
    await pumpReview(
      tester,
      scope(const CardListScreen(deckId: 'demo'), Brightness.dark),
    );
    await openFilterSheet(tester);
    await tickTag(tester, 'food');

    await matchesReviewGolden('goldens/tag_filter_sheet_dark.png');
  });
}
