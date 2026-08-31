@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_impact_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of the deck feature's **overlays** — the sheets,
/// menus, forms and dialogs that had no picture at all.
///
/// **The gap this closes.** The gallery's four deck entries are all the same
/// screen in four states; every sheet the screen opens was unphotographed and
/// unmeasured, so the layout review scored 4 of the feature's 15 surfaces and
/// the other 11 were not judged, not even badly. An overlay is where this app
/// puts its destructive actions (delete, reset learning progress) and its only
/// free-text input (rename, create) — the surfaces where being wrong costs the
/// most were the ones with no evidence.
///
/// **Opened by tapping, not by calling `showX` directly.** A sheet reached
/// through its real entry point carries the real screen behind it — the scrim,
/// the bar it covers, the tile it was opened from. Calling the function against
/// a bare `Scaffold` would photograph the sheet and lose everything the sheet
/// sits on, which is half of what a reviewer needs to judge a modal.
void main() {
  final english = AppLocalizationsEn();

  /// A root deck with learned cards, so its menu offers every action a root
  /// can have: rename, change scheduler, reset progress, delete.
  List<DeckSummary> roots() => <DeckSummary>[
    fakeSummary(
      id: 'd1',
      name: 'Academic Word List',
      totalCardCount: 570,
      newCardCount: 46,
      dueCardCount: 12,
      overdueCardCount: 8,
      overdueDayCount: 7,
      learnedCardCount: 120,
      subDeckCount: 4,
    ),
    fakeSummary(
      id: 'd2',
      name: 'IELTS Writing Task 2',
      totalCardCount: 210,
      dueCardCount: 3,
      learnedCardCount: 145,
      subDeckCount: 2,
      schedulerType: SchedulerType.sm2,
    ),
    fakeSummary(
      id: 'd3',
      name: 'Phrasal verbs',
      totalCardCount: 88,
      learnedCardCount: 88,
      subDeckCount: 1,
    ),
  ];

  /// A level inside a deck: its menu is the one that carries Move, because a
  /// root cannot be moved (BR-06, UC-09 A2).
  FakeDeckRepository levelRepo() => FakeDeckRepository.withLevel(
    parent: fakeSubDeck(id: 'd1a', name: 'Sublist 1', parentId: 'd1'),
    ancestors: <DeckPathSegment>[
      const DeckPathSegment(id: 'd1', name: 'Academic Word List'),
    ],
    children: <DeckSummary>[
      fakeChildSummary(
        id: 'd1a1',
        name: 'Nouns',
        parentId: 'd1a',
        totalCardCount: 60,
        newCardCount: 14,
        dueCardCount: 7,
        overdueCardCount: 4,
        overdueDayCount: 1,
        learnedCardCount: 22,
      ),
      fakeChildSummary(
        id: 'd1a2',
        name: 'Verbs',
        parentId: 'd1a',
        totalCardCount: 60,
        learnedCardCount: 60,
      ),
    ],
  );

  /// **Scope outside the app, not inside it.** `showDialog` puts its route on
  /// the *root* navigator, so a dialog opened from a screen mounted at
  /// `ReviewApp(home: deckShellWith(...))` lands above the `ProviderScope` and
  /// throws `No ProviderScope found` — which is what the delete confirm did on
  /// the first run of this file. `main.dart` wraps `MaterialApp.router` in the
  /// scope; this reproduces that order so both navigators sit inside it.
  Widget shell(
    FakeDeckRepository repository,
    Brightness brightness, {
    String? location,
    Locale? locale,
  }) => deckScopeAround(
    repository,
    ReviewApp(
      home: deckRouterAt(location),
      brightness: brightness,
      locale: locale,
    ),
  );

  /// The impact the confirm dialog states, matched to the deck it is opened
  /// over. Left at the fake's `(0, 0)` default, the dialog told a 570-card deck
  /// that "no cards" would go with it — a true sentence about the fixture and a
  /// false one about the picture.
  FakeDeckRepository rootRepo() => FakeDeckRepository.withSummaries(roots())
    ..deletionImpact = const DeckDeletionImpact(
      descendantDeckCount: 4,
      cardCount: 570,
    );

  Widget rootShell(Brightness brightness) => shell(rootRepo(), brightness);

  Widget levelShell(Brightness brightness) =>
      shell(levelRepo(), brightness, location: '/decks/deck-1');

  /// The ⋮ on the first deck tile — the deck's own menu, not the library's.
  ///
  /// **Found by label, not by index, because index was wrong and the picture
  /// did not say so.** Four `more_vert` glyphs are on this screen — one per
  /// tile plus the app bar's — and the bar's is *last* in the tree, not first.
  /// Selecting `.at(1)` photographed the second deck's menu under a name that
  /// claimed the first, and `.first` photographed a deck menu into a file
  /// called `library_menu`. Both PNGs looked perfectly plausible.
  Future<void> openTileMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
  }

  Future<void> chooseAction(WidgetTester tester, String label) async {
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  // ---------------------------------------------------------------- menus ---

  testWidgets('deck actions — a root deck, light', (tester) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await openTileMenu(tester);

    await matchesReviewGolden('goldens/deck_actions_root_light.png');
  });

  testWidgets('deck actions — a root deck, dark', (tester) async {
    await pumpReview(tester, rootShell(Brightness.dark));
    await openTileMenu(tester);

    await matchesReviewGolden('goldens/deck_actions_root_dark.png');
  });

  testWidgets('deck actions — a sub-deck, which is the one that can move', (
    tester,
  ) async {
    await pumpReview(tester, levelShell(Brightness.light));
    // The level's own menu lives on the app bar and acts on the deck being
    // viewed — the only menu on this screen that offers Move.
    await tester.tap(
      find.bySemanticsLabel(english.deckActionsSemanticLabel).first,
    );
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_actions_child_light.png');
  });

  testWidgets('library menu — the root overflow', (tester) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await tester.tap(find.byTooltip(english.libraryActionsTitle));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_library_menu_light.png');
  });

  testWidgets('sort sheet — the five orders a list can take', (tester) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await tester.tap(find.byIcon(Icons.swap_vert));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_sort_sheet_light.png');
  });

  // ---------------------------------------------------------------- forms ---

  testWidgets('create root deck — the form the FAB opens', (tester) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_create_root_light.png');
  });

  testWidgets('rename — the same form with a name already in it', (
    tester,
  ) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await openTileMenu(tester);
    await chooseAction(tester, english.deckRenameAction);

    await matchesReviewGolden('goldens/deck_rename_form_light.png');
  });

  // ----------------------------------------------------------- destructive ---

  testWidgets('delete — the confirm that states what goes with it', (
    tester,
  ) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await openTileMenu(tester);
    await chooseAction(tester, english.deckDeleteAction);

    await matchesReviewGolden('goldens/deck_delete_confirm_light.png');
  });

  testWidgets('delete — the confirm, dark', (tester) async {
    await pumpReview(tester, rootShell(Brightness.dark));
    await openTileMenu(tester);
    await chooseAction(tester, english.deckDeleteAction);

    await matchesReviewGolden('goldens/deck_delete_confirm_dark.png');
  });

  /// The empty deck is the case that exposes the sentence: with no sub-decks,
  /// the plural's `=0` arm contributes nothing and the message opens on a
  /// lower-case `no`.
  testWidgets('delete — an empty deck, where the sentence starts lower-case', (
    tester,
  ) async {
    await pumpReview(
      tester,
      shell(
        FakeDeckRepository.withSummaries(<DeckSummary>[
          fakeSummary(id: 'd1', name: 'Business email'),
        ]),
        Brightness.light,
      ),
    );
    await openTileMenu(tester);
    await chooseAction(tester, english.deckDeleteAction);

    await matchesReviewGolden('goldens/deck_delete_empty_light.png');
  });

  /// The confirm's button pair already wraps in English (SUMMARY C1). Vietnamese
  /// is the longer of the two languages the app ships, so this is where the
  /// same miscalculated width costs the most.
  testWidgets('delete — the confirm in Vietnamese', (tester) async {
    await pumpReview(
      tester,
      shell(rootRepo(), Brightness.light, locale: const Locale('vi')),
    );
    await openTileMenu(tester);
    await tester.tap(find.byIcon(Icons.delete_outline).last);
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_delete_confirm_vi.png');
  });

  testWidgets('reset learning progress — UC-07 on a studied deck', (
    tester,
  ) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await openTileMenu(tester);
    await chooseAction(tester, english.deckResetProgressAction);

    await matchesReviewGolden('goldens/deck_reset_progress_light.png');
  });

  // ------------------------------------------------------ move and create ---

  testWidgets('move picker — the targets, and the ones it refuses', (
    tester,
  ) async {
    // The picker reads the whole tree to work out what may receive the deck:
    // not itself, not its own descendants (BR-69, BR-70).
    final source = fakeSubDeck(id: 'd1a', name: 'Sublist 1', parentId: 'd1');
    final repository = FakeDeckRepository(
      deckList: (_) => Stream<DeckListSnapshot>.value(
        DeckListSnapshot(
          parent: source,
          ancestors: const <DeckPathSegment>[
            DeckPathSegment(id: 'd1', name: 'Academic Word List'),
          ],
          decks: <DeckSummary>[
            fakeChildSummary(
              id: 'd1a1',
              name: 'Nouns',
              parentId: 'd1a',
              totalCardCount: 60,
              dueCardCount: 7,
              learnedCardCount: 22,
            ),
          ],
          nextDueAt: null,
          nextOverdueTickAt: null,
        ),
      ),
      allDecks: () => Stream<List<DeckEntity>>.value(<DeckEntity>[
        fakeRootDeck(id: 'd1', name: 'Academic Word List'),
        source,
        fakeSubDeck(id: 'd1b', name: 'Sublist 2', parentId: 'd1'),
        fakeSubDeck(id: 'd1a1', name: 'Nouns', parentId: 'd1a'),
      ]),
    );

    await pumpReview(
      tester,
      shell(repository, Brightness.light, location: '/decks/deck-1'),
    );
    await tester.tap(
      find.bySemanticsLabel(english.deckActionsSemanticLabel).first,
    );
    await tester.pumpAndSettle();
    await chooseAction(tester, english.deckMoveAction);

    await matchesReviewGolden('goldens/deck_move_picker_light.png');
  });

  testWidgets('create child — the kind an unset deck has to ask for', (
    tester,
  ) async {
    // BR-61/BR-62: an `unset` sub-deck may still become either, so the form
    // asks first rather than deciding for the user.
    await pumpReview(
      tester,
      shell(levelRepo(), Brightness.light, location: '/decks/deck-1'),
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_create_child_kind_light.png');
  });

  testWidgets('breadcrumb — every level, which the strip cannot show', (
    tester,
  ) async {
    // Long press is the disclosure: the strip is one target for Up, so the
    // full path needs its own gesture (owner review, 2026-08-21).
    await pumpReview(tester, levelShell(Brightness.light));
    await tester.longPress(find.byType(MxBreadcrumb));
    await tester.pumpAndSettle();

    await matchesReviewGolden('goldens/deck_ancestors_light.png');
  });

  testWidgets('change scheduler — BR-12, on a deck whose choice is open', (
    tester,
  ) async {
    await pumpReview(tester, rootShell(Brightness.light));
    await openTileMenu(tester);
    await chooseAction(tester, english.deckSchedulerChangeAction);

    await matchesReviewGolden('goldens/deck_scheduler_change_light.png');
  });
}
