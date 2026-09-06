import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_segment_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_action_sheet.dart';

import '../../card/presentation/support/fake_card_repository.dart';
import '../../card/presentation/support/fake_card_transfer_repositories.dart';
import '../../settings/domain/support/fake_app_settings_repository.dart';
import 'support/fake_deck_repository.dart';

/// Where the `unset` deck's create sheet leaves the user (SC-C4-20).
///
/// **One sheet, one verb, one landing place.** The sheet offers three doors and
/// two of them lead into the card feature; both must `push`, so backing out of
/// either returns to the deck the user started from. The editor row used to
/// `go`, which rebuilds the match list from `/decks/<id>/cards/new` and
/// materialises a `CardListScreen` page underneath the editor — so the close
/// button dropped the user on the card list of a deck they had not made a card
/// deck, which is the outcome the import row three lines away documents as
/// forbidden (UC-10, M4.12 W5).
///
/// Beside `deck_level_create_test.dart` rather than inside it: that file pumps
/// the screen alone and asserts *which rows are offered*, which is a question a
/// router adds nothing to. This one is about where a row lands, so it mounts
/// the real router and shell. `test/app/router/card_import_route_test.dart`
/// covers the import route's own contract; what is asserted here is the pair
/// agreeing, which belongs to the sheet and therefore to the deck feature.
void main() {
  final english = AppLocalizationsEn();

  DeckEntity unsetDeck() =>
      fakeSubDeck(id: 'deck-1', name: 'Unset deck', parentId: 'root');

  DeckListSnapshot levelOf(DeckEntity parent) => DeckListSnapshot(
    ancestors: const <DeckPathSegment>[],
    parent: parent,
    decks: const <DeckSummary>[],
    nextDueAt: null,
    nextOverdueTickAt: null,
  );

  /// The level the deck screen is reading, and the later frames pushed into it.
  ///
  /// **Current value first, then updates.** A test has to move the deck from
  /// `unset` to `card` the way the create transaction does (BR-62) — the fake
  /// applies no business rules, and the post-save landing is a question about a
  /// deck whose type has already changed. A bare broadcast controller could not
  /// do that: the first frame has to exist before the screen subscribes, and a
  /// broadcast stream drops whatever was added before a listener arrived.
  late DeckListSnapshot current;
  late StreamController<DeckListSnapshot> updates;

  setUp(() {
    current = levelOf(unsetDeck());
    updates = StreamController<DeckListSnapshot>.broadcast();
  });

  tearDown(() => updates.close());

  Stream<DeckListSnapshot> levelStream() async* {
    yield current;
    yield* updates.stream;
  }

  void moveLevelTo(DeckEntity parent) {
    current = levelOf(parent);
    updates.add(current);
  }

  Future<(GoRouter, FakeCardRepository)> pumpUnsetLevel(
    WidgetTester tester,
  ) async {
    final router = createAppRouter(initialLocation: '/decks/deck-1');
    addTearDown(router.dispose);
    // Seeded empty rather than left un-emitted: the last case walks into the
    // card list, and a list stream that never answers leaves a spinner running
    // that `pumpAndSettle` can never settle.
    final cards = FakeCardRepository.loaded(const [], total: 0);
    addTearDown(cards.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository(deckList: (_) => levelStream()),
          ),
          cardRepositoryProvider.overrideWithValue(cards),
          cardTransferRepositoryProvider.overrideWithValue(
            FakeCardTransferRepository(),
          ),
          cardImportSourceRepositoryProvider.overrideWithValue(
            FakeCardImportSourceRepository(),
          ),
          cardImportRepositoryProvider.overrideWithValue(
            FakeCardImportCommitRepository(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DeckListScreen), findsOneWidget);

    return (router, cards);
  }

  /// Opens the chooser an `unset` deck answers with (BR-61) and taps one row.
  ///
  /// Scoped to the sheet: the opener behind it carries the sub-deck string too
  /// since SC-C3-05 gave that action one name.
  Future<void> chooseRow(WidgetTester tester, String label) async {
    await tester.tap(find.text(english.deckCreateSubDeckAction).last);
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(MxActionSheet),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'the card row pushes the editor without materialising a card list '
    'underneath it',
    (tester) async {
      final (router, _) = await pumpUnsetLevel(tester);

      await chooseRow(tester, english.deckCreateCardAction);

      expect(find.byType(CardEditorScreen), findsOneWidget);
      // **`skipOffstage: false` is the whole assertion.** A route below an
      // opaque one is built but offstage, so the default finder cannot tell a
      // pushed editor from a `go` that built `/decks/<id>/cards` beneath it.
      expect(find.byType(CardListScreen, skipOffstage: false), findsNothing);
      // A push keeps the base URI and carries the editor's own location on the
      // pushed match — the same shape `card_import_route_test.dart` asserts.
      expect(
        router.routerDelegate.currentConfiguration.last.matchedLocation,
        '/decks/deck-1/cards/new',
      );
    },
  );

  testWidgets('closing the editor returns to the deck, not to its cards', (
    tester,
  ) async {
    final (router, _) = await pumpUnsetLevel(tester);

    await chooseRow(tester, english.deckCreateCardAction);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(CardEditorScreen), findsNothing);
    expect(find.byType(CardListScreen, skipOffstage: false), findsNothing);
    expect(find.byType(DeckListScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1',
      reason: 'the URL is the deck again, not its card list',
    );
    // Nothing was written, so the deck is still the one the user opened: the
    // level still reads as unset (BR-61).
    expect(find.text(english.deckDetailEmptyUnsetTitle), findsOneWidget);
  });

  testWidgets('closing the import wizard lands in the same place (UC-10, W5)', (
    tester,
  ) async {
    final (router, _) = await pumpUnsetLevel(tester);

    await chooseRow(tester, english.cardImportEntryAction);
    expect(find.byType(CardImportScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(CardImportScreen), findsNothing);
    expect(find.byType(DeckListScreen), findsOneWidget);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1',
      reason: 'the two card doors of one sheet leave the user in one place',
    );
  });

  testWidgets('a saved card still ends on the cards, through the deck level', (
    tester,
  ) async {
    final (router, cards) = await pumpUnsetLevel(tester);

    await chooseRow(tester, english.deckCreateCardAction);

    await tester.enterText(find.byType(TextField).at(0), 'front');
    await tester.enterText(find.byType(TextField).at(1), 'back');
    // The create transaction settles `content_type` (BR-62); the fake applies
    // no rules, so the level and the redirect's read are moved by hand to the
    // state the write leaves behind.
    cards.holdsCards = true;
    moveLevelTo(
      fakeSubDeck(
        id: 'deck-1',
        name: 'Unset deck',
        parentId: 'root',
        contentType: DeckContentType.card,
      ),
    );
    await tester.tap(find.text(english.cardEditorSave));
    await tester.pumpAndSettle();

    expect(cards.creates.single.front, 'front');
    expect(find.byType(CardEditorScreen), findsNothing);
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/decks/deck-1',
    );
    // Popping restores the previous match list rather than re-running the
    // route's redirect, so the deck's own level is what answers — and a `card`
    // deck's level is the handoff into its cards (BR-63), one tap away.
    expect(find.text(english.deckDetailOpenCardsAction), findsOneWidget);

    await tester.tap(find.text(english.deckDetailOpenCardsAction));
    await tester.pumpAndSettle();
    expect(find.byType(CardListScreen), findsOneWidget);
  });
}
