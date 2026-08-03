import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/presentation/controllers/card_list_window_controller.dart';
import 'package:memox/features/card/presentation/screens/card_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/core/theme/app_theme.dart';

import 'support/fake_card_repository.dart';

/// The card list screen through its four states, and the load-more window
/// (UC-04 W1, W1b).
void main() {
  Future<void> pump(WidgetTester tester, FakeCardRepository repository) async {
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
          home: const CardListScreen(deckId: 'deck-1'),
        ),
      ),
    );
  }

  testWidgets('a spinner shows before the first emission', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);

    await pump(tester, repository);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('an empty deck shows the empty state with an add action', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[].cast());
    repository.emitCount(0);
    await tester.pump();

    expect(find.text('No cards yet'), findsOneWidget);
    expect(find.text('Add card'), findsOneWidget);
  });

  testWidgets('a loaded deck lists its cards and the showing line', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem('c1', front: 'ephemeral'),
        repository.listItem('c2', front: 'ubiquitous'),
      ].cast(),
    );
    repository.emitCount(214);
    await tester.pump();

    expect(find.text('ephemeral'), findsOneWidget);
    expect(find.text('ubiquitous'), findsOneWidget);
    // The count is the deck's total, not the window's length.
    expect(find.text('Showing 2 of 214'), findsOneWidget);
  });

  testWidgets(
    'a flagged card shows the flag indicator, an unflagged one does not',
    (tester) async {
      final repository = FakeCardRepository();
      addTearDown(repository.dispose);
      await pump(tester, repository);

      repository.emitItems(
        <dynamic>[
          repository.listItem('c1', front: 'marked', isFlagged: true),
          repository.listItem('c2', front: 'plain'),
        ].cast(),
      );
      repository.emitCount(2);
      await tester.pump();

      // One flag icon, for the one flagged card.
      expect(find.byIcon(Icons.flag), findsOneWidget);
    },
  );

  testWidgets('each row shows its state label (D5, BR-90/91/88)', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem('c1', front: 'fresh'),
        repository.listItem('c2', front: 'done', state: CardState.mastered),
      ].cast(),
    );
    repository.emitCount(2);
    await tester.pump();

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Mastered'), findsOneWidget);
  });

  testWidgets('selecting a pill re-reads the list with that filter (D3)', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    repository.filterCounts[CardListFilter.isNew] = 4;
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(10);
    await tester.pumpAndSettle();

    // The pill carries its count.
    expect(find.widgetWithText(FilterChip, 'New 4'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'New 4'));
    // A plain pump, not settle: switching filter re-subscribes the list, which
    // spins until the fake re-emits, and pumpAndSettle would wait on the spinner.
    await tester.pump();

    expect(repository.requestedFilters, contains(CardListFilter.isNew));
  });

  testWidgets('a row shows its tag names as chips (BR-93)', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(
      <dynamic>[
        repository.listItem(
          'c1',
          front: 'tagged',
          tagNames: <String>['noun', 'people'],
        ),
      ].cast(),
    );
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('noun'), findsOneWidget);
    expect(find.text('people'), findsOneWidget);
  });

  testWidgets('a card due now shows the now badge (BR-22)', (tester) async {
    // The seeded rows carry no due date, so every one is due now.
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('now'), findsOneWidget);
  });

  testWidgets('the tail offers load-more while rows remain', (tester) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(120);
    await tester.pump();

    expect(find.text('Load 50 more'), findsOneWidget);
  });

  testWidgets('the tail says all shown when the window covers the deck', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(1);
    await tester.pump();

    expect(find.text('Load 50 more'), findsNothing);
    expect(find.textContaining('shown'), findsOneWidget);
  });

  testWidgets('tapping load-more grows the requested window', (tester) async {
    // The behaviour C2 rests on: the window re-reads at a larger limit, and the
    // repository is asked for that larger limit.
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitItems(<dynamic>[repository.listItem('c1')].cast());
    repository.emitCount(120);
    await tester.pump();

    await tester.tap(find.text('Load 50 more'));
    await tester.pump();

    // First subscription at the initial window, second at one step larger.
    expect(repository.requestedLimits, <int>[
      kCardWindowSize,
      kCardWindowSize * 2,
    ]);
  });

  testWidgets('a read failure shows the error copy, not a spinner', (
    tester,
  ) async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    await pump(tester, repository);

    repository.emitError(StateError('boom'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining("couldn't be loaded"), findsOneWidget);
  });
}
