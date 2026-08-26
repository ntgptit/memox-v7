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
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_card_repository.dart';

/// The collapsed disclosure label, named once so a copy change breaks in one
/// place rather than in five test files.
const String kDetailsToggleLabel = 'Add example, hint & pronunciation';

/// The card editor mounted the way production mounts it.
///
/// **A real `GoRouter`, and a route the editor is pushed *onto*.** Three things
/// depend on it. Moving a card to Trash navigates to the deck by name (BR-163:
/// the last card leaves the deck `unset`, which has no card list to pop back
/// to). Leaving the editor has to have somewhere to land — a `PopScope` on the
/// first route of a one-entry stack is not the screen production runs. And the
/// history row goes to the card detail route by name, so a harness without it
/// would make that row throw where production navigates.
///
/// The deck and detail screens are marker widgets: where the app *goes* is this
/// feature's business; what those screens then render is their own tests'.
Future<GoRouter> pumpCardEditor(
  WidgetTester tester,
  FakeCardRepository repository, {
  String cardId = 'card-1',
  Locale locale = const Locale('en'),
  ThemeData? theme,
  Size? surfaceSize,
  double textScale = 1,
}) async {
  // **Seeded unless the caller says otherwise, and that is a correction.**
  // `FakeCardRepository.watchDeckContext` returns an empty stream by default,
  // so every test that did not set this was quietly exercising an editor with
  // no breadcrumb and no deck row — a screen production never shows. The audit
  // found that before it found anything the screen was doing wrong.
  repository.deckContextToShow ??= const DeckContextModel(
    deckName: 'TOPIK II — Vocab',
    ancestors: <DeckBreadcrumbSegment>[
      DeckBreadcrumbSegment(id: 'korean', name: 'Korean'),
    ],
  );

  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  final router = GoRouter(
    initialLocation: '/decks/deck-1/editor',
    routes: <RouteBase>[
      GoRoute(
        path: '/decks/:deckId',
        name: RouteNames.deckDetail,
        builder: (context, state) => const Scaffold(body: Text('deck detail')),
        routes: <RouteBase>[
          GoRoute(
            path: 'editor',
            builder: (context, state) =>
                CardEditorScreen(deckId: 'deck-1', cardId: cardId),
          ),
          GoRoute(
            path: 'cards/:cardId',
            name: RouteNames.cardDetail,
            builder: (context, state) =>
                const Scaffold(body: Text('card detail')),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [cardRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        theme: theme ?? buildLightTheme(),
        locale: locale,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: textScale,
          maxScaleFactor: textScale,
          child: child!,
        ),
      ),
    ),
  );
  // Let the prefill future resolve.
  await tester.pumpAndSettle();

  return router;
}

/// Fires the platform back gesture the way Android does, so the assertion is
/// about `PopScope` and not about a button that happens to call the same code.
Future<void> pressSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

/// Two back gestures in the same frame — the shape of a double-tap on a
/// gesture bar, and the one a re-entrancy guard has to survive. Neither is
/// awaited before the pump: awaiting the first would let its dialog finish
/// opening, which is the case the single-press helper already covers.
Future<void> pressSystemBackTwice(WidgetTester tester) async {
  final Future<void> first = tester.binding.handlePopRoute();
  final Future<void> second = tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
  await first;
  await second;
}

/// Opens the inline tag entry and returns the field it put on screen.
///
/// The entry lives behind the `+ Add tag` chip now, so every tag test starts
/// with the same two taps; naming them once keeps the tests about tags rather
/// than about how the entry opens.
Future<Finder> openTagEntry(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Add tag'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Add tag'));
  await tester.pumpAndSettle();

  return find.byType(TextField).last;
}
