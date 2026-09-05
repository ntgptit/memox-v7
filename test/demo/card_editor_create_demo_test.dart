@Tags(<String>['golden', 'review'])
library;

import 'package:flutter/material.dart' show Brightness, Widget;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/deck/presentation/support/fake_deck_repository.dart';
import '../support/study_render.dart';
import '../visual_audit/deck_audit_harness.dart';

/// Device-faithful renders of the card editor in **create** mode — the empty
/// form as the user first meets it (UC-04 W4, A4).
///
/// The gallery already carries `card_editor_edit`; it carried no picture of
/// create at all, which is the gap that matters most on this screen because
/// the two modes compose *differently on purpose*. `card_editor_screen.dart`
/// builds create as a bare `MxContentShell` — an `×` rather than a back arrow,
/// no app-bar actions, no breadcrumb and no tag strip. What it no longer
/// differs on is where `Save` sits: the `Save` / `Save and add another` pair
/// used to be the last child of the scroll and is now pinned in
/// `MxContentShell.footer` like edit's
/// (`docs/reviews/app-wide-screen-consistency.md`, SC-C1-02). None of that is
/// visible in the edit render, so reviewing the two side by side needed a
/// second frame.
///
/// **Mounted through the production router**, unlike the edit renders in
/// `card_screens_demo_test.dart`, which pump `CardEditorScreen` directly and so
/// photograph it without the bottom navigation bar or the safe area. Create
/// lives inside the Library branch (`/decks/<id>/cards/new`, `app_router.dart`),
/// so the bar is part of the screen a user sees — and it is exactly the chrome
/// a "where does Save sit" review has to weigh the scroll against.
void main() {
  // The deck the create form was opened from. It titles nothing on this
  // screen — create has no breadcrumb — but the card list underneath is a real
  // route in the stack, and a fake with no context would put it in a state
  // production never reaches.
  const DeckContextModel demoContext = DeckContextModel(
    deckName: 'Korean · TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[
      DeckBreadcrumbSegment(id: 'lang', name: 'Languages'),
      DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
    ],
  );

  /// The card list the editor is pushed onto, loaded rather than empty: it is
  /// under an opaque route so nothing of it is captured, but a stream that
  /// never resolves is a loading face, and a loading face is the one thing
  /// this suite has learned not to leave in a stack it means to settle.
  FakeCardRepository cards() {
    final repository = FakeCardRepository.loaded(<CardListItemModel>[
      FakeCardRepository().listItem('c1', front: '사과', back: 'apple / quả táo'),
      FakeCardRepository().listItem('c2', front: '바다', back: 'sea / biển'),
    ], total: 142);
    repository
      ..holdsCards = true
      ..deckContextToShow = demoContext;

    return repository;
  }

  Widget scope(FakeCardRepository repository, Brightness brightness) =>
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          cardRepositoryProvider.overrideWithValue(repository),
          deckRepositoryProvider.overrideWithValue(FakeDeckRepository()),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 7, 29, 12)),
        ],
        child: ReviewApp(
          // The full location: the Library branch root is `/`, and the editor
          // hangs off the deck's card list (`route_paths.dart`).
          home: deckRouterAt('/decks/demo/cards/new'),
          brightness: brightness,
        ),
      );

  for (final (String mode, Brightness brightness) in <(String, Brightness)>[
    ('light', Brightness.light),
    ('dark', Brightness.dark),
  ]) {
    testWidgets('card editor — create mode, the empty form, $mode', (
      tester,
    ) async {
      final repository = cards();
      addTearDown(repository.dispose);

      // **The autofocus stays.** `CardCreateFormWidget` asks the front field
      // for focus on the first frame, so the focused outline and the caret are
      // what a user actually meets. A widget test raises no software keyboard,
      // so `viewInsets` stay zero and the whole screen is in frame — which is
      // what this render is for. The keyboard case SC-C1-02 was about is
      // measured rather than photographed, at
      // `card_editor_create_layout_test.dart`, because a golden with no
      // keyboard in it cannot show what the keyboard covered.
      await pumpReview(tester, scope(repository, brightness));

      await matchesReviewGolden('goldens/card_editor_create_$mode.png');
    });
  }
}
