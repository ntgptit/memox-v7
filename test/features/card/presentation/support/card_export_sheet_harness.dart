import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/card/di/card_export_repository_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_transfer_record_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';

import '../../data/support/card_export_fixture.dart';
import 'fake_card_export_repositories.dart';
import 'fake_card_repository.dart';

/// The card list with all four export seams faked, and the two entry points
/// reachable the way a user reaches them.
///
/// **Mounted through the real screen rather than the sheet alone.** The two
/// entry points are half of what M4.13 W1 specifies, and a harness that pumped
/// the sheet directly could never see whether the deck's count hides the menu
/// item or whether the selection survives an export (BR-178).
///
/// The use case itself is **not** faked: `exportCardsUseCaseProvider` composes
/// the three overridden contracts and the clock, so every test here runs the
/// production ordering of read → encode → name → hand over.
final class CardExportSheetHarness {
  final AppLocalizationsEn english = AppLocalizationsEn();
  final AppLocalizationsVi vietnamese = AppLocalizationsVi();

  late FakeCardRepository cards;
  late FakeCardExportRepository exports;
  late FakeCardExportDestinationRepository destination;
  late FakeCardExportEncoders encoders;

  static const DeckContextModel deckContext = DeckContextModel(
    deckName: 'Korean · TOPIK I',
    ancestors: <DeckBreadcrumbSegment>[
      DeckBreadcrumbSegment(id: 'ko', name: 'Korean'),
    ],
  );

  /// A fixed instant, so the file name a test inspects is the one it expects
  /// and nothing here reads the wall clock.
  static final DateTime now = DateTime.utc(2026, 8, 13, 9, 30);

  /// Seeds the list with [cardCount] rows and a deck total of [deckTotal]
  /// (default: the same number). `deckTotal: 0` is the empty deck, which must
  /// offer no export at all.
  void seed({int cardCount = 3, int? deckTotal}) {
    cards = FakeCardRepository.loaded(
      List<CardListItemModel>.generate(
        cardCount,
        (index) => FakeCardRepository().listItem(
          'c$index',
          front: 'front $index',
          back: 'back $index',
        ),
      ),
      total: deckTotal ?? cardCount,
    )..deckContextToShow = deckContext;
  }

  Future<void> pump(
    WidgetTester tester, {
    Size surface = const Size(393, 852),
    double textScale = 1,
    Locale? locale,
    Brightness brightness = Brightness.light,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        // Inlined rather than hoisted into a field: Riverpod's `Override` is
        // not a public type, so a shared list cannot be typed — the same
        // reason `study_render.dart` leaves the overrides at the call site.
        overrides: [
          cardRepositoryProvider.overrideWithValue(cards),
          cardExportRepositoryProvider.overrideWithValue(exports),
          cardExportDestinationRepositoryProvider.overrideWithValue(
            destination,
          ),
          cardTransferEncoderResolverProvider.overrideWithValue(
            encoders.resolver,
          ),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark
              ? buildDarkTheme()
              : buildLightTheme(),
          locale: locale,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // **`builder`, not a `MediaQuery` around `home`.** The export sheet
          // is a route pushed onto the navigator, so a MediaQuery inside
          // `home` sits *below* it and the sheet would render at 1.0× while
          // the screen behind it scaled — which is exactly the combination
          // the 320dp × 2.0 checks exist to rule out. `builder` wraps the
          // navigator, so every route inherits the scale the way it does from
          // the platform in production.
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: const CardListScreen(deckId: 'deck-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the app-bar overflow menu.
  Future<void> openOverflow(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
  }

  /// Entry point 1 (M4.13 W1): overflow → `Export cards`, scope `all`.
  Future<void> openWholeDeckExport(
    WidgetTester tester, {
    AppLocalizations? l10n,
  }) async {
    await openOverflow(tester);
    await tester.tap(find.text((l10n ?? english).cardExportEntryAction).last);
    await tester.pumpAndSettle();
  }

  /// Enters selection mode and selects [count] rows, leaving the selection
  /// bar on screen.
  Future<void> selectCards(WidgetTester tester, {int count = 2}) async {
    await tester.longPress(find.byType(CardTileWidget).first);
    await tester.pumpAndSettle();
    for (var index = 1; index < count; index++) {
      await tester.tap(find.byType(CardTileWidget).at(index));
      await tester.pumpAndSettle();
    }
  }

  /// Entry point 2 (M4.13 W1): selection bar overflow → `Export selected`.
  Future<void> openSelectionExport(
    WidgetTester tester, {
    AppLocalizations? l10n,
  }) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text((l10n ?? english).cardExportSelectionAction).last,
    );
    await tester.pumpAndSettle();
  }
}

/// Registers fresh fakes per test and returns the harness the tests read.
CardExportSheetHarness installCardExportSheetHarness() {
  final harness = CardExportSheetHarness();
  setUp(() {
    harness
      ..exports = (FakeCardExportRepository()
        // A non-empty snapshot: the use case refuses an empty one outright
        // (BR-174), so every happy-path test would otherwise reach E5.
        ..records = <CardTransferRecord>[
          exportRecord(front: '사과', back: 'apple', tags: <String>['fruit']),
          exportRecord(front: '바다', back: 'sea'),
        ])
      ..destination = FakeCardExportDestinationRepository()
      ..encoders = FakeCardExportEncoders()
      ..seed();
  });
  tearDown(() => harness.cards.dispose());

  return harness;
}
