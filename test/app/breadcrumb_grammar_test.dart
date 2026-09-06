import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/presentation/screens/deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../features/card/presentation/support/fake_card_repository.dart';
import '../features/deck/presentation/support/fake_deck_repository.dart';

/// One question, one strip: "where am I in the deck tree" is answered the same
/// way on the deck level and on the card list one tap below it (SC-C4-06,
/// SC-C4-10).
///
/// **This file exists because both screens documented the agreement and only
/// one of them kept it.** `card_breadcrumb_widget.dart` opened with "The strip
/// is literal, matching the deck screen"; measured, the two differed in four
/// things at once — a 48dp band below the bar against a 32dp line inside it, no
/// up chevron against a `chevron_left`, a trailing step repeating the app-bar
/// title against none, and therefore a platform back arrow beside an invisible
/// whole-strip target against a single up affordance.
///
/// So the assertions are **symmetric**: each one pumps both screens over the
/// same deck fixture and compares them to each other rather than to a number.
/// A future change that re-composes one strip has to re-compose the other or
/// come back here and say why, which is the argument a comment could not make.
///
/// Neither screen is routed. What is measured is the resting chrome, and the
/// property that replaces "is there a back arrow" — `automaticallyImplyLeading`
/// — is the shell's own decision rather than the route's, so it reads the same
/// whether the screen was pushed or is the first page.
void main() {
  /// The deck both screens are opened on, and its one ancestor. The names are
  /// distinct strings so a finder cannot match the wrong one.
  const String deckName = 'TOPIK II — Vocab';
  const String ancestorName = 'Korean';

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

  /// The deck level *inside* `deckName`, which is where the deck feature draws
  /// its path — at the root the second line states the level instead
  /// (`deck_subheader_widget.dart`).
  ///
  /// Keyed, and the card scope below carries a different key: without them the
  /// second `pumpWidget` updates the first scope in place and Riverpod refuses,
  /// because the two screens override different providers.
  Future<void> pumpDeckLevel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey<String>('deck-scope'),
        overrides: [
          deckRepositoryProvider.overrideWithValue(
            FakeDeckRepository.withLevel(
              parent: fakeSubDeck(
                id: 'deck-1',
                name: deckName,
                parentId: 'korean',
              ),
              ancestors: fakePath(<String>[ancestorName]),
            ),
          ),
          clockProvider.overrideWithValue(() => DateTime.utc(2026)),
        ],
        child: app(const DeckListScreen(parentDeckId: 'deck-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The card list of the same deck, reached from the level above.
  Future<void> pumpCardList(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repository = FakeCardRepository.loaded(<CardListItemModel>[
      FakeCardRepository().listItem('c1', front: '사과', back: 'apple'),
    ], total: 1);
    addTearDown(repository.dispose);
    repository.deckContextToShow = const DeckContextModel(
      deckName: deckName,
      ancestors: <DeckBreadcrumbSegment>[
        DeckBreadcrumbSegment(id: 'korean', name: ancestorName),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey<String>('card-scope'),
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: app(const CardListScreen(deckId: 'deck-1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('both strips stand the same height', (tester) async {
    await pumpDeckLevel(tester);
    final onDeckLevel = tester.getRect(find.byType(MxBreadcrumb)).height;

    await pumpCardList(tester);
    final onCardList = tester.getRect(find.byType(MxBreadcrumb)).height;

    expect(
      onCardList,
      moreOrLessEquals(onDeckLevel, epsilon: 0.5),
      reason:
          'the card list drew a 48dp band where the deck level draws a 32dp '
          'header line, so opening a card deck changed the height of the '
          'chrome and not only its contents (SC-C4-06)',
    );
  });

  testWidgets('neither strip ends by repeating the app-bar title', (
    tester,
  ) async {
    for (final (String label, Future<void> Function(WidgetTester) pump)
        in <(String, Future<void> Function(WidgetTester))>[
          ('the deck level', pumpDeckLevel),
          ('the card list', pumpCardList),
        ]) {
      await pump(tester);

      expect(
        find.descendant(of: find.byType(AppBar), matching: find.text(deckName)),
        findsOneWidget,
        reason: '$label names the open deck in its bar',
      );
      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.text(deckName),
        ),
        findsNothing,
        reason:
            '$label must not spend the header\'s scarcest line repeating the '
            'largest text on screen — and the whole-strip tap goes to the '
            "deck's parent, so a step naming the open deck is not where the "
            'strip goes either',
      );
      // The ancestor is the step that *is* on the strip, so the assertion
      // above cannot pass by the strip having gone missing.
      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.text(ancestorName),
        ),
        findsOneWidget,
        reason: '$label still draws the path above the open deck',
      );
    }
  });

  testWidgets('both screens carry exactly one up affordance', (tester) async {
    for (final (String label, Future<void> Function(WidgetTester) pump)
        in <(String, Future<void> Function(WidgetTester))>[
          ('the deck level', pumpDeckLevel),
          ('the card list', pumpCardList),
        ]) {
      await pump(tester);

      expect(
        find.descendant(
          of: find.byType(MxBreadcrumb),
          matching: find.byIcon(Icons.chevron_left),
        ),
        findsOneWidget,
        reason:
            '$label: the chevron is what says the strip is a control — '
            'without it the whole-strip tap is invisible',
      );
      // The shell's own decision, not the route's: a subline means the title
      // owns the way back, so the bar must not also infer an arrow.
      expect(
        tester.widget<AppBar>(find.byType(AppBar)).automaticallyImplyLeading,
        isFalse,
        reason:
            '$label passes a subline, so a second up control would be the '
            'platform arrow beside the strip that already goes up',
      );
      expect(find.byType(BackButton), findsNothing, reason: label);
    }
  });
}
