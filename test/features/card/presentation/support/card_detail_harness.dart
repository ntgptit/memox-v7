import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'fake_card_detail_repository.dart';

/// The detail screen under a router, over a fake of its own contract.
///
/// **A real `GoRouter`, not a bare `home:`.** Both of the screen's navigations
/// go by name — `Edit` to the editor, the not-found face back to the card list
/// — so a harness without a router would make those paths throw where
/// production works. The two destinations are marker widgets: where the screen
/// *goes* is what these tests are about, and what the destination renders
/// belongs to its own file.
Future<GoRouter> pumpCardDetail(
  WidgetTester tester,
  FakeCardDetailRepository repository, {
  String cardId = 'card-1',
  Locale locale = const Locale('en'),
  ThemeData? theme,
  Size? surfaceSize,
  double textScale = 1,
}) async {
  final router = GoRouter(
    initialLocation: '/decks/deck-1/cards/$cardId',
    routes: <RouteBase>[
      GoRoute(
        path: '/decks/:deckId/cards',
        name: RouteNames.cardList,
        builder: (context, state) => const Scaffold(body: Text('card list')),
        routes: <RouteBase>[
          GoRoute(
            path: ':cardId/edit',
            name: RouteNames.cardEditorEdit,
            builder: (context, state) => const Scaffold(body: Text('editor')),
          ),
          GoRoute(
            path: ':cardId',
            name: RouteNames.cardDetail,
            builder: (context, state) =>
                CardDetailScreen(deckId: 'deck-1', cardId: cardId),
          ),
        ],
      ),
    ],
  );
  addTearDown(router.dispose);

  if (surfaceSize != null) {
    // `tester.view`, not `setSurfaceSize`: the latter leaves the default 3.0
    // device pixel ratio in place, so a 320 "surface" reaches `MediaQuery` as a
    // logical width the breakpoint reads as a tablet — and a compact-width
    // assertion then passes against a screen that was never narrow.
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: [cardDetailRepositoryProvider.overrideWithValue(repository)],
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
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
      ),
    ),
  );

  return router;
}
