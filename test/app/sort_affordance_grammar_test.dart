import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_list_sort_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';
import 'package:memox/shared/widgets/mx_text_button.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/deck/presentation/support/fake_deck_repository.dart';

/// One action, one grammar: "choose the order of this list" is a text link with
/// a leading `swap_vert` opening a sheet, on both lists a user drills between.
///
/// **The sibling of `create_affordance_grammar_test.dart`, and it exists for the
/// same reason.** Both controls documented their own shape in prose and neither
/// prose mentioned the other: the deck list's heading row opened a sheet from an
/// `MxTextButton` with the glyph *leading* the order it is in, while the card
/// list's count row — one tap deeper — opened an `MxMenuButton` whose trailing
/// `expand_more` said "a menu" rather than naming the axis. Two mechanisms and
/// two shapes for one act, and nothing failed (SC-C4-13). The deck side carries
/// three recorded owner-review passes, so the card side is the one that moved.
///
/// The assertion is deliberately *symmetric* rather than a pair of per-screen
/// expectations: both screens are pumped in one test against the same finder,
/// and the two controls are compared to each other. A future change that
/// re-shapes one of them has to re-shape the other or explain itself here.
///
/// The two screens are pumped over their own feature's fake, each in its own
/// `ProviderScope`, because they read different contracts. Neither is routed:
/// the sort control opens a sheet, and the resting frame is what is measured.
void main() {
  final english = AppLocalizationsEn();

  // The app around one screen — the same helper, and the same reason for not
  // folding the `ProviderScope` in, as `create_affordance_grammar_test.dart`.
  Widget app(Widget screen) => MaterialApp(
    theme: buildLightTheme(),
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: screen,
  );

  /// The sort controls on screen, identified by the glyph rather than by type.
  ///
  /// Both lists carry other text links — the empty faces' way back out of a
  /// filter is one — so `find.byType(MxTextButton)` is not the control, and a
  /// test that took `.single` from it would start failing for the wrong reason
  /// the next time a link is added.
  List<MxTextButton> sortControls(WidgetTester tester) => tester
      .widgetList<MxTextButton>(find.byType(MxTextButton))
      .where((MxTextButton button) => button.icon == Icons.swap_vert)
      .toList();

  Future<void> pumpDeckLevel(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Keyed, and the card scope below carries a different key: without
        // them the second `pumpWidget` updates the first scope in place and
        // Riverpod refuses, because the two screens override different
        // providers.
        key: const ValueKey<String>('deck-scope'),
        overrides: [
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository.withSummaries(<DeckSummary>[
              fakeSummary(id: '1', name: 'Japanese N5', totalCardCount: 120),
            ]),
          ),
        ],
        child: app(const DeckListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<FakeCardRepository> pumpCardList(WidgetTester tester) async {
    // A loaded deck, because the count row the control sits on only exists
    // once there are cards to count.
    final cards = FakeCardRepository.loaded(<CardListItemModel>[
      FakeCardRepository().listItem('c1', front: 'ephemeral'),
    ], total: 1);
    addTearDown(cards.dispose);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey<String>('card-scope'),
        overrides: [cardRepositoryProvider.overrideWithValue(cards)],
        child: app(const CardListScreen(deckId: 'deck-1')),
      ),
    );
    await tester.pumpAndSettle();

    return cards;
  }

  testWidgets('both lists choose an order through the same control', (
    tester,
  ) async {
    await pumpDeckLevel(tester);
    final onDeckLevel = sortControls(tester);

    await pumpCardList(tester);
    final onCardList = sortControls(tester);

    // Symmetric on purpose — see the file comment. The equality is the rule;
    // the `1` pins which side of it the app settled on, so deleting the control
    // from both would not pass by making the rule vacuous.
    expect(onCardList.length, onDeckLevel.length);
    expect(onDeckLevel.length, 1);

    // The three properties that made the two controls read as different
    // things: the glyph's seat (leading, already the finder's premise), the
    // absence of a disclosure chevron after the label, and the rung.
    expect(onCardList.single.trailingIcon, onDeckLevel.single.trailingIcon);
    expect(onDeckLevel.single.trailingIcon, isNull);
    expect(onCardList.single.isCompact, onDeckLevel.single.isCompact);
    expect(onDeckLevel.single.isCompact, isTrue);

    // The painted word is the order in force, and the announcement contains it
    // rather than replacing it — the same on both, in each list's own words.
    expect(onDeckLevel.single.label, english.deckSortManualLabel);
    expect(
      onDeckLevel.single.semanticLabel,
      contains(english.deckSortManualLabel),
    );
    expect(onCardList.single.label, english.cardSortNewest);
    expect(onCardList.single.semanticLabel, contains(english.cardSortNewest));
  });

  testWidgets('and both open a sheet that ticks the order in force', (
    tester,
  ) async {
    Future<List<MxActionSheetAction>> openSortSheet(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.swap_vert));
      await tester.pumpAndSettle();

      return tester
          .widgetList<MxActionSheet>(find.byType(MxActionSheet))
          .single
          .actions;
    }

    await pumpDeckLevel(tester);
    final deckRows = await openSortSheet(tester);

    await pumpCardList(tester);
    final cardRows = await openSortSheet(tester);

    // Exactly one tick on each. The count is half the assertion: a sheet that
    // ticked two would be worse than one that ticked none, because it would
    // look answered.
    for (final rows in <List<MxActionSheetAction>>[deckRows, cardRows]) {
      expect(rows.where((MxActionSheetAction row) => row.isSelected).length, 1);
      // Every row carries a glyph, so the list does not read as a paragraph.
      expect(rows.every((MxActionSheetAction row) => row.icon != null), isTrue);
    }

    expect(cardRows.map((MxActionSheetAction row) => row.label), <String>[
      english.cardSortNewest,
      english.cardSortDueFirst,
    ]);
    expect(
      cardRows.singleWhere((MxActionSheetAction row) => row.isSelected).label,
      english.cardSortNewest,
    );
  });

  testWidgets('and the card sheet really re-orders the read', (tester) async {
    final cards = await pumpCardList(tester);
    expect(cards.requestedSorts.last, CardListSort.newest);

    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MxActionSheet),
        // Scoped to the sheet: the control and the row it opened name the
        // orders with the same string, so a bare `find.text` would match both
        // and tap whichever the tree holds first.
        matching: find.text(english.cardSortDueFirst),
      ),
    );
    await tester.pumpAndSettle();

    expect(cards.requestedSorts.last, CardListSort.dueFirst);
    expect(sortControls(tester).single.label, english.cardSortDueFirst);
  });
}
