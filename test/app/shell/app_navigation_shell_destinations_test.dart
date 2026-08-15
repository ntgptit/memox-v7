import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/app.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/app/router/app_router.dart';
import 'package:memox/app/router/route_paths.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/study/di/study_home_repository_provider.dart';
import 'package:memox/features/study/di/study_repository_provider.dart';
import 'package:memox/l10n/generated/app_localizations_en.dart';
import 'package:memox/l10n/generated/app_localizations_vi.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_navigation_bar.dart';

import '../../features/deck/presentation/support/fake_deck_repository.dart';
import '../../features/progress/presentation/support/fake_progress_repository.dart';
import '../../features/study/domain/support/fake_study_home_repository.dart';
import '../../features/study/domain/support/fake_study_repository.dart';

/// The destination row of the shell, after AD-19 made it four wide.
///
/// Split out of `app_navigation_shell_test.dart` when the four-branch scaffold
/// pushed that file past the source-size ceiling; same harness, one concern —
/// which destinations the bar carries, in which order, in which language, and
/// how the two branches AD-19 scaffolded behave inside the shell's frame.
///
/// Progress stopped being a placeholder at M99.23, so the branch is pumped with
/// a fake repository here. The 320 × 2.0 clearance claim below still measures an
/// `MxEmptyState`, and deliberately: Progress's lifetime-empty face (UC-12 A2)
/// is the same centred column the placeholder was, which keeps the tightest-fit
/// measurement pointing at the same shape it was written for.
void main() {
  final english = AppLocalizationsEn();

  Future<void> pumpShell(
    WidgetTester tester,
    FakeDeckRepository repository, {
    String initialLocation = RoutePaths.decks,
    Size surface = const Size(393, 852),
    double textScale = 1,
    bool hasProgressActivity = true,
  }) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
          // The Study branch is Study Home since UC-12, which reads its own
          // contract — a screen with no method that could open a session.
          studyHomeRepositoryProvider.overrideWithValue(
            FakeStudyHomeRepository(),
          ),
          studyRepositoryProvider.overrideWithValue(FakeStudyRepository()),
          progressRepositoryProvider.overrideWithValue(
            FakeProgressRepository(
              initial: progressOverviewFixture(
                totals: hasProgressActivity
                    ? const <int>[2, 0, 4, 1, 0, 3, 5]
                    : const <int>[0, 0, 0, 0, 0, 0, 0],
                streakDays: hasProgressActivity ? 1 : 0,
              ),
            ),
          ),
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
    testWidgets('the progress branch shows its content under the bar', (
      tester,
    ) async {
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.progress,
      );

      expect(find.text(english.progressStreakSectionLabel), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the settings branch shows its placeholder under the bar', (
      tester,
    ) async {
      await pumpShell(
        tester,
        FakeDeckRepository(),
        initialLocation: RoutePaths.settings,
      );

      expect(find.text(english.settingsPlaceholderTitle), findsOneWidget);
      expect(find.byType(MxNavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the progress empty face clears the bar at 320 with '
        'textScaler 2.0', (tester) async {
      // The same overflow shape as the deck empty state, on a branch that is
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
        hasProgressActivity: false,
      );

      // At this size the empty face is taller than the viewport, so it
      // scrolls — which is the correct outcome, not a defect: W6 forbids
      // buying the height back by shrinking the type or clipping the copy.
      // What must hold is that the action stays **reachable** and, once
      // reached, sits clear of the bar. Measuring the unscrolled rect would
      // assert the opposite of the design, and asserting nothing here would
      // leave a CTA that can sit permanently under the bar undetected.
      await tester.ensureVisible(find.text(english.progressEmptyAction));
      await tester.pumpAndSettle();

      final action = tester.getRect(find.text(english.progressEmptyAction));
      final bar = tester.getRect(find.byType(MxNavigationBar));

      expect(find.byType(MxEmptyState), findsOneWidget);
      expect(action.bottom, lessThanOrEqualTo(bar.top));
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
