import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/deck_screen_harness.dart';
import 'support/fake_deck_repository.dart';

/// What on a deck card is a target, and what it opens.
///
/// **The regression this pins.** Only the card's top band used to take the tap —
/// the well, the name and the counts were wrapped in their own `InkWell` — so the
/// progress bar and the due row underneath it looked like part of a tappable card
/// and did nothing. Geometry is the only way to see that: every one of those bands
/// is present and correct in the widget tree either way, and the difference is
/// which pixels react.
///
/// Through the real router, because "it opened the deck" is a location, not a
/// callback. A fired callback would still pass if the tile called the wrong one.
void main() {
  final english = AppLocalizationsEn();

  FakeDeckRepository serving() => FakeDeckRepository.withSummaries(
    <DeckSummary>[
      fakeSummary(
        id: 'deck-1',
        name: 'Korean',
        totalCardCount: 40,
        // Both bands have to exist for the test to mean anything: the progress
        // bar is drawn only when the deck has cards, and the due chip only when
        // something is waiting.
        dueCardCount: 5,
        learnedCardCount: 10,
      ),
    ],
  );

  group('the deck card is one target', () {
    testWidgets('its bottom band opens the deck, not only its top one', (
      tester,
    ) async {
      final repository = serving();
      await pumpDeckApp(tester, repository: repository);

      final card = tester.getRect(find.byType(DeckTileWidget));
      // Bottom-left: the due chip's end of the foot row, as far from the old
      // target as the card goes. The overflow menu is at the other end.
      await tester.tapAt(Offset(card.left + 8, card.bottom - 8));
      await tester.pumpAndSettle();

      // The deck's own level was opened, proven by the read it caused.
      //
      // Not the router's uri: opening a deck is a `push` on a
      // `StatefulShellRoute`, and `currentConfiguration` keeps reporting `/`
      // through it — which would make this assertion, and the one below,
      // indifferent to whether the deck opened at all. The parent id the level
      // read asks for cannot be faked by a screen that never changed.
      expect(
        repository.deckListParents,
        contains('deck-1'),
        reason: 'the tap did not open deck-1',
      );
    });

    testWidgets('the overflow menu is still its own action', (tester) async {
      // The other half of the fix: a card that takes the whole tap must not
      // swallow the controls sitting on it. A nested button wins the gesture
      // arena over the card's ink, and this is what says so.
      final repository = serving();
      await pumpDeckApp(tester, repository: repository);

      await tester.tap(
        find.bySemanticsLabel(RegExp(english.deckActionsSemanticLabel)).last,
      );
      await tester.pumpAndSettle();

      expect(find.text(english.deckRenameAction), findsOneWidget);
      expect(
        repository.deckListParents,
        isNot(contains('deck-1')),
        reason: 'opening the row menu must not also open the deck',
      );
    });
  });
}
