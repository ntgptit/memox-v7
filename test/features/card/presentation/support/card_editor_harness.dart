import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_card_repository.dart';

/// The collapsed disclosure label, named once so a copy change breaks in one
/// place rather than in five test files.
const String kDetailsToggleLabel = 'Add example, hint & pronunciation';

/// The card editor mounted the way production mounts it.
///
/// **A real `GoRouter`, and a route the editor is pushed *onto*.** Two things
/// depend on it. Deleting a card navigates to the deck by name (BR-163: the
/// last card leaves the deck `unset`, which has no card list to pop back to).
/// And leaving the editor has to have somewhere to land — a `PopScope` on the
/// first route of a one-entry stack is not the screen production runs, so a
/// harness without the deck below it would prove nothing about the exit guard.
///
/// The deck screen is a marker widget: where the app *goes* is this feature's
/// business; what the deck then renders is `test/app/router/`'s.
Future<GoRouter> pumpCardEditor(
  WidgetTester tester,
  FakeCardRepository repository, {
  String cardId = 'card-1',
  Locale locale = const Locale('en'),
  ThemeData? theme,
  Size? surfaceSize,
  double textScale = 1,
}) async {
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
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

/// The editor in **create** mode, on the route production pushes it from.
///
/// Separate from [pumpCardEditor] rather than a flag on it: create has no card
/// to load, so a harness that took a nullable id would spend half its body on
/// which half applies.
Future<GoRouter> pumpCardCreator(
  WidgetTester tester,
  FakeCardRepository repository, {
  Locale locale = const Locale('en'),
}) async {
  final router = GoRouter(
    initialLocation: '/decks/deck-1/new',
    routes: <RouteBase>[
      GoRoute(
        path: '/decks/:deckId',
        name: RouteNames.deckDetail,
        builder: (context, state) => const Scaffold(body: Text('deck detail')),
        routes: <RouteBase>[
          GoRoute(
            path: 'new',
            builder: (context, state) =>
                const CardEditorScreen(deckId: 'deck-1'),
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
        theme: buildLightTheme(),
        locale: locale,
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

/// The tag input, found by the button inside it.
///
/// **Not `widgetWithText(TextField, 'Add tag')`.** The label and the hint carry
/// the same string, so once the field is focused and empty that finder matches
/// the same `TextField` twice and every read of it throws `Too many elements`.
Finder tagInput() =>
    find.ancestor(of: find.byIcon(Icons.add), matching: find.byType(TextField));
