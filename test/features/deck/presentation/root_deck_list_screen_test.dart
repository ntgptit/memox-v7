import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/di/deck_repository_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/features/deck/domain/deck_entity.dart';
import 'package:memox/features/deck/presentation/root_deck_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_tile.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_deck_repository.dart';

/// The four states of the deck list, and the two viewports that break layouts.
///
/// The screen is pumped under the production themes and the real localization
/// delegates. A test-only `MaterialApp` with hardcoded strings would pass while
/// the shipped screen threw on every `context.l10n` — which is how the first run
/// of the visual audit harness found two production screens rendering Flutter's
/// error box and still reporting a pass.
void main() {
  final english = AppLocalizationsEn();

  /// Pumps the screen with [repository] behind it.
  ///
  /// [size] and [textScaler] are the two axes CLAUDE.md requires every screen
  /// to be checked on; they default to a normal phone so the state tests read
  /// without noise.
  Future<void> pumpScreen(
    WidgetTester tester,
    FakeDeckRepository repository, {
    bool isDark = false,
    Size size = const Size(393, 852),
    double textScaler = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: isDark ? buildDarkTheme() : buildLightTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScaler)),
            child: const RootDeckListScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  List<DeckEntity> threeDecks() => <DeckEntity>[
    fakeRootDeck(id: 'deck-1', name: 'Japanese N5'),
    fakeRootDeck(id: 'deck-2', name: 'Spanish verbs'),
    fakeRootDeck(id: 'deck-3', name: 'Kanji radicals'),
  ];

  group('loading', () {
    testWidgets('shows the shared loading state, announced to a screen reader', (
      tester,
    ) async {
      await pumpScreen(tester, FakeDeckRepository.pending());

      final loading = tester.widget<MxLoadingState>(
        find.byType(MxLoadingState),
      );

      expect(loading.semanticsLabel, english.decksLoadingLabel);
      // The title stays put while the body swaps, so the screen does not appear
      // to be replaced by a different one every time the data changes.
      expect(find.text(english.decksTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows neither the empty nor the error state', (tester) async {
      await pumpScreen(tester, FakeDeckRepository.pending());

      expect(find.byType(MxEmptyState), findsNothing);
      expect(find.byType(MxErrorState), findsNothing);
    });
  });

  group('empty', () {
    testWidgets('reads as a starting point, not as a failure', (tester) async {
      await pumpScreen(
        tester,
        FakeDeckRepository.emitting(const <DeckEntity>[]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(find.byType(MxErrorState), findsNothing);
      expect(find.text(english.decksEmptyTitle), findsOneWidget);
      expect(find.text(english.decksEmptyMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('offers no action, because there is no flow behind one', (
      tester,
    ) async {
      // Guards the decision, not the layout: a button wired to an empty
      // callback, or to a "coming soon" snackbar, is a worse answer than no
      // button, and it is the thing most likely to be added by accident.
      await pumpScreen(
        tester,
        FakeDeckRepository.emitting(const <DeckEntity>[]),
      );
      await tester.pumpAndSettle();

      final empty = tester.widget<MxEmptyState>(find.byType(MxEmptyState));

      expect(empty.onAction, isNull);
      expect(empty.actionLabel, isNull);
    });
  });

  group('loaded', () {
    testWidgets('renders one row per root deck, in the stream order', (
      tester,
    ) async {
      await pumpScreen(tester, FakeDeckRepository.emitting(threeDecks()));
      await tester.pumpAndSettle();

      expect(find.byType(MxListTile), findsNWidgets(3));
      expect(find.text('Japanese N5'), findsOneWidget);
      expect(find.text('Spanish verbs'), findsOneWidget);
      expect(find.text('Kanji radicals'), findsOneWidget);
      expect(find.byType(MxEmptyState), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('rows carry no tap target while deck detail does not exist', (
      tester,
    ) async {
      await pumpScreen(tester, FakeDeckRepository.emitting(threeDecks()));
      await tester.pumpAndSettle();

      final tile = tester.widget<MxListTile>(find.byType(MxListTile).first);

      expect(tile.onTap, isNull);
    });

    testWidgets('a later emission updates the list without a manual refresh', (
      tester,
    ) async {
      // UC-06 A2. The whole reason the read is a stream: a deck created on
      // another screen has to arrive here on its own.
      final controller = StreamController<List<DeckEntity>>();
      addTearDown(controller.close);

      await pumpScreen(tester, FakeDeckRepository(() => controller.stream));

      controller.add(const <DeckEntity>[]);
      await tester.pumpAndSettle();
      expect(find.byType(MxEmptyState), findsOneWidget);

      controller.add(threeDecks());
      await tester.pumpAndSettle();

      expect(find.byType(MxListTile), findsNWidgets(3));
      expect(find.byType(MxEmptyState), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('error', () {
    testWidgets('shows localized copy and no technical detail', (tester) async {
      const failure = DatabaseFailure(
        message: 'SqliteException(11): database disk image is malformed',
      );
      await pumpScreen(tester, FakeDeckRepository.failing(failure));
      await tester.pumpAndSettle();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(find.text(english.decksLoadErrorTitle), findsOneWidget);
      expect(find.text(english.decksLoadErrorMessage), findsOneWidget);
      // The `Failure`'s own message is a developer string. It must not be what
      // the user reads, even though it is right there on the exception.
      expect(find.textContaining('Sqlite'), findsNothing);
      expect(find.textContaining('malformed'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry re-subscribes and can recover into a loaded list', (
      tester,
    ) async {
      var attempt = 0;
      final repository = FakeDeckRepository(() {
        attempt += 1;
        if (attempt == 1) {
          return Stream<List<DeckEntity>>.error(
            const DatabaseFailure(message: 'read failed'),
          );
        }

        return Stream<List<DeckEntity>>.value(threeDecks());
      });

      await pumpScreen(tester, repository);
      await tester.pumpAndSettle();
      expect(find.byType(MxErrorState), findsOneWidget);

      await tester.tap(find.text(english.retryAction));
      await tester.pumpAndSettle();

      expect(repository.watchRootDecksCallCount, 2);
      expect(find.byType(MxListTile), findsNWidgets(3));
      expect(find.byType(MxErrorState), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('dark mode', () {
    testWidgets('every state builds under the dark theme', (tester) async {
      // `pump`, never `pumpAndSettle`: the loading state holds a
      // `CircularProgressIndicator`, which animates forever, so settling would
      // time out on a screen that is behaving correctly. One extra pump is
      // enough — it flushes the stream event the fake delivers as a microtask.
      for (final repository in <FakeDeckRepository>[
        FakeDeckRepository.pending(),
        FakeDeckRepository.emitting(const <DeckEntity>[]),
        FakeDeckRepository.emitting(threeDecks()),
        FakeDeckRepository.failing(const DatabaseFailure(message: 'x')),
      ]) {
        await pumpScreen(tester, repository, isDark: true);
        await tester.pump();

        expect(tester.takeException(), isNull);
      }
    });
  });

  group('responsive', () {
    // 320x568 is the smallest phone the project supports, and textScaler 2.0 is
    // the accessibility setting that breaks a layout first. Both are checked on
    // the loaded list *and* on the two centred states, because they overflow for
    // different reasons: a list clips, a centred column runs off the bottom.
    const compact = Size(320, 568);

    testWidgets('the loaded list fits a 320x568 screen', (tester) async {
      await pumpScreen(
        tester,
        FakeDeckRepository.emitting(threeDecks()),
        size: compact,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxListTile), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the loaded list survives textScaler 2.0 on a small screen', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FakeDeckRepository.emitting(threeDecks()),
        size: compact,
        textScaler: 2,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the empty state survives textScaler 2.0 on a small screen', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FakeDeckRepository.emitting(const <DeckEntity>[]),
        size: compact,
        textScaler: 2,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the error state survives textScaler 2.0 on a small screen', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FakeDeckRepository.failing(const DatabaseFailure(message: 'x')),
        size: compact,
        textScaler: 2,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxErrorState), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a long deck name truncates instead of overflowing', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        FakeDeckRepository.emitting(<DeckEntity>[
          fakeRootDeck(id: 'deck-1', name: 'A' * DeckEntity.maxNameLength),
        ]),
        size: compact,
        textScaler: 2,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MxListTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
