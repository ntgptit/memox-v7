import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/presentation/controllers/progress_overview_controller.dart';

import 'support/fake_progress_repository.dart';

/// The midnight wake-up and the read states of the Progress controller
/// (BR-189, UC-12).
///
/// **The bug these cover.** A screen left open across local midnight keeps
/// yesterday on it: Today still shows the count from a day that ended, the
/// chart's last bar is the wrong day, and the streak is measured against the
/// wrong anchor. Nothing about that looks broken — every number is a number
/// somebody could believe — so only a test that moves a clock can find it.
void main() {
  final DateTime noon = DateTime.utc(2026, 8, 12, 12);
  final DateTime midnight = DateTime.utc(2026, 8, 13);

  ProgressOverview snapshot({
    DateTime? nextMidnight,
    int streak = 3,
    List<int>? totals,
  }) => progressOverviewFixture(
    totals: totals ?? const <int>[1, 1, 1, 0, 0, 0, 2],
    streakDays: streak,
  ).copyWith(nextLocalMidnight: nextMidnight ?? midnight);

  /// A container whose clock advances to whatever the test says, so a `Timer`
  /// fires against a clock that has actually moved.
  ///
  /// Moving the clock is not decoration: `_armMidnight` refuses to re-arm for a
  /// boundary it has already chased, so a rollover measured at the same instant
  /// would prove nothing about the guard *or* about the refresh.
  ({ProviderContainer container, void Function(DateTime) setNow}) driven(
    FakeProgressRepository repository, {
    required DateTime start,
    Duration offset = Duration.zero,
  }) {
    var current = start;
    final Duration currentOffset = offset;
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => current),
        utcOffsetProvider.overrideWithValue(() => currentOffset),
      ],
    );
    addTearDown(container.dispose);
    container.listen<AsyncValue<ProgressOverview>>(
      progressOverviewControllerProvider,
      (_, _) {},
    );

    // **Every test below ends by disposing.** `flutter_test` asserts that no
    // timer is pending when the body returns, and a controller that has just
    // armed a wake-up for tonight's midnight has one *by design* — that is the
    // feature. Disposing is what leaving the tab does, so the teardown is the
    // behaviour rather than housekeeping; `addTearDown` above is only the net
    // for a test that fails before it gets there.

    return (container: container, setNow: (DateTime at) => current = at);
  }

  group('read states', () {
    testWidgets('starts loading and then carries the snapshot', (tester) async {
      final repository = FakeProgressRepository();
      final fixture = driven(repository, start: noon);

      expect(
        fixture.container.read(progressOverviewControllerProvider).isLoading,
        isTrue,
      );

      repository.emit(snapshot());
      await tester.pump();

      final value = fixture.container
          .read(progressOverviewControllerProvider)
          .value;
      expect(value?.currentStreakDays, 3);
      expect(value?.today.totalCards, 2);
      fixture.container.dispose();
    });

    testWidgets('surfaces a failure without retrying on its own', (
      tester,
    ) async {
      // `noAutomaticRetry` matters here and nowhere else: while Riverpod
      // retries, the state is `AsyncLoading`, so the screen would spin instead
      // of offering the Retry that UC-12 E1 promises.
      final repository = FakeProgressRepository();
      final fixture = driven(repository, start: noon);
      // Pump first: the fake's stream is a broadcast controller, so an error
      // pushed before the provider has subscribed goes nowhere.
      await tester.pump();

      repository.fail(const DatabaseFailure(message: 'read failed'));
      await tester.pump();

      final state = fixture.container.read(progressOverviewControllerProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<DatabaseFailure>());

      await tester.pump(const Duration(seconds: 5));
      expect(
        fixture.container.read(progressOverviewControllerProvider).hasError,
        isTrue,
      );
      fixture.container.dispose();
    });

    testWidgets('a new emission replaces the numbers without dropping the '
        'previous value', (tester) async {
      // Live refresh (UC-12 A3): an answer written while the screen is open
      // must update in place. `AsyncValue.value` surviving through the refresh
      // is what lets `MxAsyncView` keep the sections on screen instead of
      // flashing a spinner over them.
      final repository = FakeProgressRepository(initial: snapshot());
      final fixture = driven(repository, start: noon);
      await tester.pump();

      repository.emit(
        snapshot(streak: 4, totals: const <int>[1, 1, 1, 0, 0, 0, 9]),
      );
      await tester.pump();

      final state = fixture.container.read(progressOverviewControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.value?.today.totalCards, 9);
      expect(repository.subscriptionCount, 1, reason: 'no re-read was needed');
      fixture.container.dispose();
    });
  });

  group('the midnight boundary', () {
    testWidgets('re-reads at the midnight the emission carried', (
      tester,
    ) async {
      final repository = FakeProgressRepository(initial: snapshot());
      final fixture = driven(repository, start: noon);
      await tester.pump();
      expect(repository.subscriptionCount, 1);

      await tester.pump(const Duration(hours: 11));
      expect(repository.subscriptionCount, 1, reason: 'not before midnight');

      fixture.setNow(midnight);
      await tester.pump(const Duration(hours: 1));

      expect(repository.subscriptionCount, 2);
      expect(repository.reads.last.now, midnight);
      fixture.container.dispose();
    });

    testWidgets('a boundary already in the past refreshes once and does not '
        'loop', (tester) async {
      // The app was suspended across midnight, so the first emission after
      // resume carries a boundary that has already gone. One immediate refresh
      // is right; a second for the same boundary is a busy loop, and the fake
      // deliberately keeps answering with the stale boundary to try to cause
      // one.
      //
      // The clock is moved past the boundary before the emission is processed,
      // which is the only shape this can take in production: a boundary is in
      // the past *because* time passed. It also matters mechanically — the
      // refresh re-reads the clock, so with a clock that had not moved the
      // instant would be unchanged and Riverpod would not rebuild at all.
      final stale = noon.add(const Duration(hours: 1));
      final repository = FakeProgressRepository(
        initial: snapshot(nextMidnight: stale),
      );
      final fixture = driven(repository, start: noon);
      fixture.setNow(noon.add(const Duration(hours: 2)));
      // `pump(Duration.zero)`, not `pump()`. A bare `pump` renders a frame
      // without elapsing the fake clock, so a `Timer(Duration.zero)` never
      // comes due and the immediate-refresh path would look dead when it is
      // not — a test that would have "proved" the guard by measuring nothing.
      await tester.pump(Duration.zero);

      expect(repository.subscriptionCount, 2);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(repository.subscriptionCount, 2);
      fixture.container.dispose();
    });

    testWidgets('a boundary exactly at now counts as passed', (tester) async {
      // `delay <= 0`, not `< 0`: at exactly midnight the day has changed, and
      // arming a zero-delay timer for it would be the same as not arming one.
      final DateTime boundary = noon.add(const Duration(hours: 1));
      final repository = FakeProgressRepository(
        initial: snapshot(nextMidnight: boundary),
      );
      final fixture = driven(repository, start: noon);
      fixture.setNow(boundary);
      await tester.pump(Duration.zero);

      expect(repository.subscriptionCount, 2);
      expect(repository.reads.last.now, boundary);
      fixture.container.dispose();
    });

    testWidgets('disposing the controller cancels the pending wake-up', (
      tester,
    ) async {
      final repository = FakeProgressRepository(initial: snapshot());
      final fixture = driven(repository, start: noon);
      await tester.pump();

      fixture.container.dispose();
      fixture.setNow(midnight);
      await tester.pump(const Duration(hours: 13));

      expect(repository.subscriptionCount, 1);
    });
  });

  testWidgets('a changed UTC offset is picked up on the next re-read', (
    tester,
  ) async {
    // A device that crosses a border or changes season moves the offset, and
    // every boundary in the snapshot is measured against it. Resolving it per
    // build is what makes the next refresh use the new one rather than the one
    // the screen opened with.
    var offset = const Duration(hours: 7);
    var current = noon;
    final repository = FakeProgressRepository(initial: snapshot());
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => current),
        utcOffsetProvider.overrideWithValue(() => offset),
      ],
    );
    addTearDown(container.dispose);
    container.listen<AsyncValue<ProgressOverview>>(
      progressOverviewControllerProvider,
      (_, _) {},
    );
    await tester.pump();
    expect(repository.reads.single.utcOffset, const Duration(hours: 7));

    offset = const Duration(hours: 9);
    current = midnight;
    container.invalidate(progressOverviewControllerProvider);
    container.listen<AsyncValue<ProgressOverview>>(
      progressOverviewControllerProvider,
      (_, _) {},
    );
    await tester.pump();

    expect(repository.reads.last.utcOffset, const Duration(hours: 9));
    container.dispose();
  });
}
