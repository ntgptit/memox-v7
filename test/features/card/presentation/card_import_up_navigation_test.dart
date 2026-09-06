import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/core/navigation/route_names.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_import_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/di/card_transfer_repository_provider.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_import_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import 'support/fake_card_repository.dart';
import 'support/fake_card_transfer_repositories.dart';

/// The wizard's path strip, in the app's one up-navigation grammar
/// (SC-C4-07).
///
/// **Two grammars one tap apart is what this closes.** The wizard drew the
/// same `MxBreadcrumb` the card list and the editor draw, in the same pinned
/// slot, but passed neither `onUp` nor `onShowAll` — which dropped the widget
/// into its legacy per-step strip: the line did nothing at all, and the fold
/// became an interactive `more_horiz` that expanded in place. "The draft
/// blocks navigation" was never the reason: the editor has the identical
/// unsaved-work problem and routes its strip through the same discard guard,
/// which is exactly what this one does now.
void main() {
  final english = AppLocalizationsEn();

  const DeckContextModel deckContext = DeckContextModel(
    deckName: 'TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[
      DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
    ],
  );

  late FakeCardRepository cards;

  /// A router whose deck screens say which deck they are, so "up" is an
  /// assertion about where the user landed rather than about a callback.
  Future<void> pump(WidgetTester tester) async {
    cards = FakeCardRepository.loaded(
      <dynamic>[FakeCardRepository().listItem('c1', front: '기존')].cast(),
      total: 1,
    )..deckContextToShow = deckContext;
    addTearDown(cards.dispose);

    final router = GoRouter(
      initialLocation: '/decks/deck-1/import',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: RouteNames.decks,
          builder: (_, _) => const Scaffold(body: Text('library')),
        ),
        GoRoute(
          path: '/decks/:deckId',
          name: RouteNames.deckDetail,
          builder: (_, GoRouterState state) =>
              Scaffold(body: Text('deck ${state.pathParameters['deckId']}')),
          routes: <RouteBase>[
            GoRoute(
              path: 'import',
              builder: (_, _) => const CardImportScreen(deckId: 'deck-1'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
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

  Future<void> makeDirty(WidgetTester tester) async {
    await tester.tap(find.text(english.cardImportPasteOptionTitle));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'front\tback');
    await tester.pumpAndSettle();
  }

  testWidgets('the strip is one target, and the fold is not a control', (
    tester,
  ) async {
    await pump(tester);

    final MxBreadcrumb strip = tester.widget<MxBreadcrumb>(
      find.byType(MxBreadcrumb),
    );
    expect(strip.onUp, isNotNull);
    expect(strip.onShowAll, isNotNull);
    expect(strip.upIcon, Icons.chevron_left);
    // `onUp` set is what makes `MxBreadcrumb` build the single-target row; the
    // legacy per-step strip is the one that renders an interactive ellipsis.
    expect(
      find.descendant(
        of: find.byType(MxBreadcrumb),
        matching: find.byIcon(Icons.more_horiz),
      ),
      findsNothing,
    );
    for (final MxBreadcrumbItem item in strip.items) {
      expect(item.onTap, isNull);
    }
  });

  testWidgets('Up goes to the deck the import targets', (tester) async {
    await pump(tester);

    await tester.tap(find.byType(MxBreadcrumb));
    await tester.pumpAndSettle();

    // The path reads `… / TOPIK I / Import`, so one level up from this screen
    // is the deck — not the deck's parent.
    expect(find.text('deck deck-1'), findsOneWidget);
    expect(find.text('deck ko'), findsNothing);
  });

  testWidgets('Up asks before dropping a draft', (tester) async {
    await pump(tester);
    await makeDirty(tester);

    await tester.tap(find.byType(MxBreadcrumb));
    await tester.pumpAndSettle();
    expect(find.text(english.cardImportDiscardTitle), findsOneWidget);
    expect(find.byType(CardImportScreen), findsOneWidget);

    await tester.tap(find.text(english.cardImportDiscardConfirmAction));
    await tester.pumpAndSettle();
    expect(find.text('deck deck-1'), findsOneWidget);
  });

  testWidgets('Cancel on that question leaves the wizard exactly as it was', (
    tester,
  ) async {
    await pump(tester);
    await makeDirty(tester);

    await tester.tap(find.byType(MxBreadcrumb));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.commonCancelAction).last);
    await tester.pumpAndSettle();

    expect(find.byType(CardImportScreen), findsOneWidget);
    expect(find.text('front\tback'), findsOneWidget);
  });

  testWidgets('long-press reaches any ancestor, and the deck itself last', (
    tester,
  ) async {
    await pump(tester);

    await tester.longPress(find.byType(MxBreadcrumb));
    await tester.pumpAndSettle();

    final Offset korean = tester.getTopLeft(find.text('Korean').last);
    final Offset current = tester.getTopLeft(find.text('TOPIK I').last);
    expect(current.dy, greaterThan(korean.dy), reason: 'the deck is last');

    await tester.tap(find.text('Korean').last);
    await tester.pumpAndSettle();
    expect(find.text('deck ko'), findsOneWidget);
  });
}
