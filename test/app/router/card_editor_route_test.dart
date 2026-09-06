import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_action_bar_widget.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/card/presentation/support/fake_card_repository.dart';
import '../../features/card/presentation/support/fake_card_transfer_repositories.dart';
import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';

/// Where the editor's edit route lives, and what that costs (SC-C4-04).
///
/// **This encodes a decision, and it is the opposite of the one the finding
/// first proposed.** Edit stacks two pinned bottom bands — its own action bar
/// in `MxContentShell.footer`, above the branch's four-destination navigation
/// bar — and no golden can show it, because every editor golden pumps the
/// screen bare, outside `createAppRouter`. The fix considered was moving the
/// route to the root navigator the way the import wizard escapes. It is
/// refused: edit is a **page** pushed onto the card list and returning to it,
/// and it pushes a branch route of its own for the card's history, which a
/// root-navigator placement would render *beneath* the editor.
///
/// So the variance is accepted and pinned here rather than left as an accident
/// of nesting — recorded in `docs/wbs.md`, "Deferred and descoped", and at the
/// route itself. A future change either keeps this shape or has to argue with
/// a red test.
void main() {
  const DeckContextModel deckContext = DeckContextModel(
    deckName: 'TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[],
  );

  Future<GoRouter> pumpApp(WidgetTester tester, String location) async {
    final cards =
        FakeCardRepository.loaded(
            <dynamic>[
              FakeCardRepository().listItem('card-1', front: '사과'),
            ].cast(),
            total: 1,
          )
          ..holdsCards = true
          ..deckContextToShow = deckContext;
    cards.cardToGet = cards.card('card-1', front: '사과', back: 'apple');
    addTearDown(cards.dispose);

    final router = createAppRouter(initialLocation: location);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          cardRepositoryProvider.overrideWithValue(cards),
          cardTransferRepositoryProvider.overrideWithValue(
            FakeCardTransferRepository(),
          ),
        ],
        child: MemoxApp(router: router),
      ),
    );
    await tester.pumpAndSettle();

    return router;
  }

  testWidgets('edit renders inside the Decks branch, so its footer sits above '
      'the navigation bar', (tester) async {
    await pumpApp(tester, '/decks/deck-1/cards/card-1/edit');

    expect(find.byType(CardEditorScreen), findsOneWidget);
    expect(find.byType(CardEditorActionBarWidget), findsOneWidget);
    // Both bands, which is the accepted cost. The import wizard's own route
    // test asserts the opposite for the same reason stated the other way: it
    // is a task and covers the shell, this is a page inside it.
    expect(find.byType(MxNavigationBar), findsOneWidget);
    expect(
      tester.getRect(find.byType(CardEditorActionBarWidget)).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(MxNavigationBar)).top),
    );
  });
}
