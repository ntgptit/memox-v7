import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/features/card/presentation/widgets/items/card_tile_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_selection_bar_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';

import 'support/fake_card_repository.dart';
import 'dart:ui' show Tristate;

/// Selection mode on the card list (UC-04 A6, BR-167).
///
/// The behaviours here are the ones a repository test cannot see: what a tap
/// means depends on the mode, Back leaves the mode before the screen, and
/// Select all covers the filtered result rather than the loaded window.
void main() {
  final english = AppLocalizationsEn();

  FakeCardRepository seeded({int cards = 3}) => FakeCardRepository.loaded(
    List<CardListItemModel>.generate(
      cards,
      (i) => FakeCardRepository().listItem(
        'c$i',
        front: 'front $i',
        back: 'back $i',
      ),
    ),
    total: cards,
  );

  Future<void> pump(
    WidgetTester tester,
    FakeCardRepository repository, {
    Size surface = const Size(393, 852),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cardRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildLightTheme(),
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: const CardListScreen(deckId: 'deck-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder tileAt(int index) => find.byType(CardTileWidget).at(index);

  testWidgets('a long-press enters selection mode with that card', (
    tester,
  ) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    expect(find.byType(CardSelectionBarWidget), findsOneWidget);
    expect(find.text(english.cardSelectionCountLabel(1)), findsOneWidget);
    expect(
      tester.widget<CardTileWidget>(tileAt(0)).isSelected,
      isTrue,
      reason: 'the card that was pressed is the one selected',
    );
    expect(tester.widget<CardTileWidget>(tileAt(1)).isSelected, isFalse);
  });

  testWidgets('the app-bar Select action enters the mode too', (tester) async {
    // The visible affordance: a user who does not know the gesture still finds
    // bulk management.
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    await tester.tap(find.bySemanticsLabel(english.cardSelectAction).first);
    await tester.pumpAndSettle();

    expect(find.byType(CardSelectionBarWidget), findsOneWidget);
    expect(find.text(english.cardSelectionCountLabel(0)), findsOneWidget);
  });

  testWidgets('inside the mode a tap toggles instead of opening', (
    tester,
  ) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    await tester.tap(tileAt(1));
    await tester.pumpAndSettle();
    expect(find.text(english.cardSelectionCountLabel(2)), findsOneWidget);

    await tester.tap(tileAt(1));
    await tester.pumpAndSettle();
    expect(find.text(english.cardSelectionCountLabel(1)), findsOneWidget);
  });

  testWidgets('deselecting the last card leaves the mode', (tester) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    await tester.tap(tileAt(0));
    await tester.pumpAndSettle();

    expect(find.byType(CardSelectionBarWidget), findsNothing);
  });

  testWidgets('Select all covers the filtered result, not the window', (
    tester,
  ) async {
    // The loaded window holds three rows; the filter matches 142. Selecting
    // "all" must mean the 142 (BR-167), which is why the count and the label
    // both come from the read rather than from `items.length`.
    final repository = seeded()
      ..idsMatching = <String>[for (var i = 0; i < 142; i++) 'c$i'];
    addTearDown(repository.dispose);
    repository.filterCounts[CardListFilter.all] = 142;
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(english.cardSelectAllAction).first);
    await tester.pumpAndSettle();

    expect(
      repository.idsMatchingCalls.single.filter,
      CardListFilter.all,
      reason: 'the live filter, not a remembered one',
    );
    expect(find.text(english.cardSelectionAllLabel(142)), findsOneWidget);
  });

  testWidgets('the close button leaves the mode', (tester) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel(english.cardSelectionCloseLabel).first,
    );
    await tester.pumpAndSettle();

    expect(find.byType(CardSelectionBarWidget), findsNothing);
  });

  testWidgets('a selected row announces itself, not just tints', (
    tester,
  ) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    // Colour is never the only signal: the row carries a semantics label and
    // the check glyph replaces the state dot.
    // OLD ASSERTION: a "selected" semantics label on the row. WHY WRONG:
    // `MxCard.isSelected` already announces the `selected` flag, so the label
    // spoke the state a second time (A20.1 P2-13). NEW CONTRACT: exactly one
    // row carries the selected flag. AUTHORITY: A20.1 P2-13 / A19-11.
    final handle = tester.ensureSemantics();
    final selectedRows = find
        .byType(CardTileWidget)
        .evaluate()
        .where(
          (e) =>
              tester
                  .getSemantics(find.byWidget(e.widget))
                  .flagsCollection
                  .isSelected ==
              Tristate.isTrue,
        );
    expect(selectedRows, hasLength(1));
    handle.dispose();
    // The multi-select glyph is the checkbox pair the Trash rows use too
    // (A20.1 P2-19, V8) — one vocabulary for "picked" across the app.
    expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(CardTileWidget),
        matching: find.byIcon(Icons.check_box_outline_blank),
      ),
      findsNWidgets(2),
    );
  });

  testWidgets('the bar survives 320px at double text scale', (tester) async {
    // `flutter_test` turns a RenderFlex overflow into a failure by itself, so
    // reaching the assertions means the bar wrapped rather than overflowed —
    // and the count is still readable, which is the one thing that must not
    // be clipped.
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository, surface: const Size(320, 852), textScale: 2);

    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    expect(find.byType(CardSelectionBarWidget), findsOneWidget);
    expect(find.text(english.cardSelectionCountLabel(1)), findsOneWidget);
  });

  testWidgets('a successful bulk flag clears the selection', (tester) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(english.cardSelectionMoreLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardSelectionFlagAction).last);
    await tester.pumpAndSettle();

    expect(repository.bulkFlags.single.isFlagged, isTrue);
    expect(find.byType(CardSelectionBarWidget), findsNothing);
    expect(find.text(english.cardBulkUpdatedMessage(1)), findsOneWidget);
  });

  testWidgets('a refused bulk write keeps the selection and says why', (
    tester,
  ) async {
    final repository = seeded()
      ..nextBulkFailure = const DatabaseFailure(message: 'disk full');
    addTearDown(repository.dispose);
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(english.cardSelectionMoreLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardSelectionFlagAction).last);
    await tester.pumpAndSettle();

    // Still selecting, and the message is the recovery line — never a
    // success the write did not achieve.
    expect(find.byType(CardSelectionBarWidget), findsOneWidget);
    expect(find.text(english.cardSelectionCountLabel(1)), findsOneWidget);
    expect(find.text(english.writeErrorMessage), findsOneWidget);
  });

  testWidgets('bulk delete confirms with the count and the consequence', (
    tester,
  ) async {
    final repository = seeded();
    addTearDown(repository.dispose);
    await pump(tester, repository);
    await tester.longPress(tileAt(0));
    await tester.pumpAndSettle();
    await tester.tap(tileAt(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(english.cardSelectionMoreLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(english.cardSelectionDeleteAction).last);
    await tester.pumpAndSettle();

    expect(find.text(english.cardBulkDeleteTitle(2)), findsOneWidget);
    expect(find.text(english.cardBulkDeleteMessage), findsOneWidget);
    // Nothing is deleted until it is confirmed.
    expect(repository.bulkDeletes, isEmpty);

    await tester.tap(find.text(english.cardBulkDeleteConfirmAction));
    await tester.pumpAndSettle();

    expect(repository.bulkDeletes.single, hasLength(2));
  });
}
