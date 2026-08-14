import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';
import 'package:memox/features/settings/di/app_settings_repository_provider.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';
import '../../features/settings/domain/support/fake_app_settings_repository.dart';

/// The destination row of the shell, after AD-19 made it four wide.
///
/// Split out of `app_navigation_shell_test.dart` when the four-branch scaffold
/// pushed that file past the source-size ceiling; same harness, one concern —
/// which destinations the bar carries, in which order, in which language, and
/// how the two placeholder branches behave inside the shell's frame.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpShell(
    WidgetTester tester,
    FakeDeckRepository repository, {
    String initialLocation = RoutePaths.decks,
    Size surface = const Size(393, 852),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            FakeAppSettingsRepository(),
          ),
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
        ],
        child: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: MemoxApp(router: router),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  group('the bar on the scaffolded branches', () {
    testWidgets('the progress branch shows its placeholder under the bar', (
      tester,
    ) async {
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.progress,
      );

      expect(find.text(english.progressPlaceholderTitle), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the settings branch shows its screen under the bar', (
      tester,
    ) async {
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.settings,
      );

      expect(find.text(english.settingsStudyDefaultsSection), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the settings screen scrolls its last row clear of the bar', (
      tester,
    ) async {
      // **The bottom-nav clearance of the M99.23 wireframe (W5), measured
      // against the real bar.** The feature's own geometry suite cannot make
      // this claim: it mounts the screen without the shell, so it can prove the
      // last row is reachable and nothing about what it is reachable *under*.
      // Scrolling to the end and finding the row still overlapping the bar is
      // exactly the failure W5 names, and only this harness can see it.
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.settings,
      );

      // `ensureVisible`, not `scrollUntilVisible`: the shell keeps a
      // `Navigator` per branch alive inside an `IndexedStack`, so there is more
      // than one `Scrollable` in the tree and `scrollUntilVisible` throws
      // "Too many elements" before it scrolls anything.
      final lastRow = find.text(english.settingsResetDescription);
      await tester.ensureVisible(lastRow);
      await tester.pumpAndSettle();

      final rowBottom = tester.getRect(lastRow).bottom;
      final barTop = tester.getRect(find.byType(MxNavigationBar)).top;

      expect(rowBottom, lessThanOrEqualTo(barTop));
    });

    testWidgets('the progress placeholder clears the bar at 320 with '
        'textScaler 2.0', (tester) async {
      // The same overflow shape as the deck empty state, on the branch that is
      // nothing but a centred column — and with four destinations the bar is
      // at its widest, so this is the tightest fit the shell has. 320, the
      // narrowest supported surface, not the 360 the sibling file's `compact`
      // constant uses: the claim being tested is M99.7's, and it says 320.
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.progress,
        surface: const Size(320, 568),
        textScale: 2,
      );

      final empty = tester.getRect(find.byType(MxEmptyState));
      final bar = tester.getRect(find.byType(MxNavigationBar));

      expect(empty.bottom, lessThanOrEqualTo(bar.top));
      expect(tester.takeException(), isNull);
    });

    testWidgets('all four labels stay inside the bar at 320 with '
        'textScaler 2.0', (tester) async {
      // The narrowest supported surface at the largest supported text scale is
      // where a fourth destination would push labels out of their slots. Each
      // label must still be present exactly once and laid out inside the bar —
      // an overflow would also surface as an exception, so both are asserted.
      await pumpShell(
        tester,
        FakeDeckRepository(),
        surface: const Size(320, 568),
        textScale: 2,
      );

      final bar = tester.getRect(find.byType(MxNavigationBar));
      for (final label in <String>[
        english.navigationDecksLabel,
        english.navigationStudyLabel,
        english.navigationProgressLabel,
        english.navigationSettingsLabel,
      ]) {
        final labelFinder = find.descendant(
          of: find.byType(MxNavigationBar),
          matching: find.text(label),
        );
        expect(labelFinder, findsOneWidget);

        final labelRect = tester.getRect(labelFinder);
        expect(labelRect.left, greaterThanOrEqualTo(bar.left));
        expect(labelRect.right, lessThanOrEqualTo(bar.right));
        expect(labelRect.bottom, lessThanOrEqualTo(bar.bottom));
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('destinations', () {
    testWidgets('exactly four, in the settled order (AD-19)', (tester) async {
      // The order is a product decision, not a layout accident: Decks is the
      // cold-start branch, Study the daily loop, and the two scaffolded
      // branches follow. An index test rather than a presence test because the
      // shell hands `goBranch` the destination's position — a reordered bar
      // would send every tap to the wrong branch while looking complete.
      await pumpShell(tester, FakeDeckRepository());

      final bar = tester.widget<MxNavigationBar>(find.byType(MxNavigationBar));
      final labels = bar.destinations
          .map((destination) => destination.label)
          .toList();

      expect(labels, <String>[
        english.navigationDecksLabel,
        english.navigationStudyLabel,
        english.navigationProgressLabel,
        english.navigationSettingsLabel,
      ]);
    });

    testWidgets('in Vietnamese the Study tab says Học, not Ôn tập', (
      tester,
    ) async {
      // "Học" covers both learning new cards and reviewing due ones; "Ôn tập"
      // names only the second half, which under-sold the branch. Driven
      // through the platform locale so the same resolution path a device takes
      // is what is being asserted.
      tester.platformDispatcher.localesTestValue = <Locale>[const Locale('vi')];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);

      await pumpShell(tester, FakeDeckRepository());

      final vietnamese = AppLocalizationsVi();
      final bar = tester.widget<MxNavigationBar>(find.byType(MxNavigationBar));
      final labels = bar.destinations
          .map((destination) => destination.label)
          .toList();

      expect(labels, <String>[
        vietnamese.navigationDecksLabel,
        vietnamese.navigationStudyLabel,
        vietnamese.navigationProgressLabel,
        vietnamese.navigationSettingsLabel,
      ]);
      expect(vietnamese.navigationStudyLabel, 'Học');
      expect(labels, isNot(contains('Ôn tập')));
    });
  });
}
