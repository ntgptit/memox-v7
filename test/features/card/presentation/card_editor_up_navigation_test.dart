import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_breadcrumb_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'support/fake_card_repository.dart';

/// A20.1 P1-16, corrective pass — the editor's path reads
/// `Library / Korean / TOPIK II — Vocab / Edit`, so one level up is the deck
/// the card is in; the card list, which *is* that deck, still goes to its
/// parent.
void main() {
  const deckContext = DeckContextModel(
    deckName: 'TOPIK II — Vocab',
    ancestors: <DeckBreadcrumbSegment>[
      DeckBreadcrumbSegment(id: 'korean', name: 'Korean'),
    ],
  );

  /// A router whose deck screen says which deck it is.
  GoRouter routerFor(Widget Function() home, {String initialLocation = '/'}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: RouteNames.decks,
          builder: (_, _) => const Scaffold(body: Text('library')),
        ),
        GoRoute(
          path: '/decks/:deckId',
          name: RouteNames.deckDetail,
          builder: (_, state) =>
              Scaffold(body: Text('deck ${state.pathParameters['deckId']}')),
          routes: <RouteBase>[
            GoRoute(path: 'editor', builder: (_, _) => home()),
            GoRoute(path: 'list', builder: (_, _) => home()),
          ],
        ),
      ],
    );
    return router;
  }

  Future<void> pump(
    WidgetTester tester,
    GoRouter router,
    FakeCardRepository repository,
  ) async {
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  FakeCardRepository seed() {
    final repository = FakeCardRepository()..deckContextToShow = deckContext;
    repository.cardToGet = repository.card('card-1');
    return repository;
  }

  Future<void> makeDirty(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'new front');
    await tester.pump();
  }

  group('the editor', () {
    testWidgets('Up goes to the deck the card is in', (tester) async {
      await pump(
        tester,
        routerFor(
          () => const CardEditorScreen(deckId: 'deck-1', cardId: 'card-1'),
          initialLocation: '/decks/deck-1/editor',
        ),
        seed(),
      );
      await tester.tap(find.byType(MxBreadcrumb));
      await tester.pumpAndSettle();

      expect(find.text('deck deck-1'), findsOneWidget);
      expect(find.text('deck korean'), findsNothing);
    });

    testWidgets('Up still asks before dropping a draft', (tester) async {
      await pump(
        tester,
        routerFor(
          () => const CardEditorScreen(deckId: 'deck-1', cardId: 'card-1'),
          initialLocation: '/decks/deck-1/editor',
        ),
        seed(),
      );
      await makeDirty(tester);
      await tester.tap(find.byType(MxBreadcrumb));
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('deck deck-1'), findsOneWidget);
    });

    testWidgets(
      'the ancestor sheet lists the deck itself, last, and reaches it',
      (tester) async {
        await pump(
          tester,
          routerFor(
            () => const CardEditorScreen(deckId: 'deck-1', cardId: 'card-1'),
            initialLocation: '/decks/deck-1/editor',
          ),
          seed(),
        );
        await tester.longPress(find.byType(MxBreadcrumb));
        await tester.pumpAndSettle();

        final korean = tester.getTopLeft(find.text('Korean').last);
        final current = tester.getTopLeft(find.text('TOPIK II — Vocab').last);
        expect(current.dy, greaterThan(korean.dy), reason: 'the deck is last');

        await tester.tap(find.text('TOPIK II — Vocab').last);
        await tester.pumpAndSettle();
        expect(find.text('deck deck-1'), findsOneWidget);
      },
    );
  });

  group('the card list', () {
    testWidgets('Up still goes to the parent deck', (tester) async {
      await pump(
        tester,
        routerFor(
          () => const Scaffold(
            body: CardBreadcrumbWidget(deckContext: deckContext),
          ),
          initialLocation: '/decks/deck-1/list',
        ),
        seed(),
      );
      await tester.tap(find.byType(MxBreadcrumb));
      await tester.pumpAndSettle();
      expect(find.text('deck korean'), findsOneWidget);
    });

    testWidgets('its ancestor sheet does not list the deck it is on', (
      tester,
    ) async {
      await pump(
        tester,
        routerFor(
          () => const Scaffold(
            body: CardBreadcrumbWidget(deckContext: deckContext),
          ),
          initialLocation: '/decks/deck-1/list',
        ),
        seed(),
      );
      await tester.longPress(find.byType(MxBreadcrumb));
      await tester.pumpAndSettle();

      expect(find.text('Korean'), findsWidgets);
      // The strip paints the deck's name once; the sheet adds no second copy.
      expect(find.text('TOPIK II — Vocab'), findsOneWidget);
    });
  });
}
