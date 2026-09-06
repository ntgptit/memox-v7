import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/deck/presentation/support/fake_deck_repository.dart';

/// One action, one grammar: "create the thing this list holds" is a floating
/// action on both lists a user drills between.
///
/// **This file exists because a comment is not an enforcement.** The card list
/// carried its create verb as a plain app-bar glyph and justified it in prose —
/// "the same place the deck list puts its create action" — which was true when
/// it was written and stopped being true on 2026-08-20, when the deck list's
/// create floated again. Nothing failed. A user drilling deck level -> card
/// list simply watched the primary create verb change position, weight and
/// colour tier one tap apart, and the screen's own comment went on asserting
/// they matched (SC-C4-05, SC-C4-11; the direction was settled by owner
/// decision on 2026-09-06 — the card list adopts the deck list's `MxFab`).
///
/// So the assertion is deliberately *symmetric* rather than a pair of
/// per-screen expectations: both screens are pumped in one test against the
/// same finder, and either both have an [MxFab] or neither does. A future
/// change that moves one of them has to move the other or explain itself here,
/// which is the argument this file replaces.
///
/// The two screens are pumped over their own feature's fake, each in its own
/// `ProviderScope`, because they read different contracts. Neither is routed:
/// both create actions open something, and what is measured is the resting
/// frame.
void main() {
  // The app around one screen. The `ProviderScope` is *not* folded in here:
  // its `overrides` list is typed `List<Override>`, and `Override` is not a
  // name `flutter_riverpod` exports, so a helper taking one cannot be written
  // without reaching into the package's internals.
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

  testWidgets('both lists offer create through the same widget type', (
    tester,
  ) async {
    // The deck root level: a level that may create (BR-63 only withholds it
    // from a `card` deck, which is the level that redirects to the card screen
    // below).
    await tester.pumpWidget(
      ProviderScope(
        // Keyed, and the card scope below carries a different key. Without
        // them the second `pumpWidget` updates the first scope in place, and
        // Riverpod refuses: the two screens override different providers, so
        // that update reads as "an override appeared that was not there
        // before". A new key is a new element, which is what pumping a
        // different screen means here.
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
    await tester.pump();

    final onDeckLevel = tester.widgetList<MxFab>(find.byType(MxFab)).length;

    // The card list of a loaded deck — the screen the deck level above hands
    // off to.
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
    await tester.pump();

    final onCardList = tester.widgetList<MxFab>(find.byType(MxFab)).length;

    // Symmetric on purpose — see the file comment. The equality is the rule;
    // the `1` pins which side of it the app settled on, so a change that
    // deleted the button from both would not pass by making the rule vacuous.
    expect(onCardList, onDeckLevel);
    expect(onDeckLevel, 1);
  });
}
