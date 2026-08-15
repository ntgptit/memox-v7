import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/core/time/time_zone_provider.dart';
import 'package:memox/features/progress/di/progress_repository_provider.dart';
import 'package:memox/features/progress/domain/models/deck_activity_model.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/presentation/controllers/deck_activity_controller.dart';
import 'package:memox/features/progress/presentation/controllers/progress_now_controller.dart';
import 'package:memox/features/progress/presentation/controllers/progress_range_controller.dart';
import 'package:memox/features/progress/domain/models/progress_range_model.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// The level controller: which read it opens, and the wake-up it schedules for
/// the moment its windows expire.
void main() {
  final start = progressLevelTestNow;

  /// A container whose clock advances to whatever instant it is asked for,
  /// driven inside `testWidgets` so `Timer` runs on fake time.
  ///
  /// The clock has to move when the timer fires, or the test proves nothing: a
  /// re-measure at the same instant re-reads the same boundary, and the guard in
  /// `_armBoundary` would then refuse to arm again.
  ({ProviderContainer container, void Function(DateTime) setNow}) driven(
    FakeProgressRepository repository, {
    String? deckId,
  }) {
    var current = start;
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        progressRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => current),
        utcOffsetProvider.overrideWithValue(() => progressTestOffset),
      ],
    );
    addTearDown(container.dispose);
    container.listen<AsyncValue<DeckActivitySnapshot>>(
      deckActivityLevelProvider(deckId),
      (_, _) {},
    );

    return (container: container, setNow: (DateTime at) => current = at);
  }

  FakeProgressRepository servingBoundary(DateTime boundary) =>
      FakeProgressRepository.withSnapshot(
        activitySnapshot(
          decks: <DeckActivity>[deckActivity(deckId: 'd1', name: 'Spanish')],
          nextDayBoundaryAt: boundary,
        ),
      );

  group('the read it opens', () {
    test('passes the caller-owned clock and offset down', () {
      final repository = FakeProgressRepository();
      driven(repository);

      expect(repository.levelReads.single.now, start);
      expect(repository.levelReads.single.utcOffset, progressTestOffset);
      expect(repository.levelReads.single.deckId, isNull);
    });

    test('the family keys the read by deck, so one level does not disturb '
        'another', () {
      final repository = FakeProgressRepository();
      final probe = driven(repository, deckId: 'deck-1');
      probe.container.listen<AsyncValue<DeckActivitySnapshot>>(
        deckActivityLevelProvider(null),
        (_, _) {},
      );

      expect(
        repository.levelReads.map((read) => read.deckId).toList(),
        <String?>['deck-1', null],
      );
    });

    test('a failure lands as an error state rather than being retried', () async {
      // Automatic retry is off: while Riverpod retries, the state is
      // `AsyncLoading`, so a failed local read would spin forever instead of
      // showing its error state and its retry action. Settling once and finding
      // the error already there is what "not retried" looks like from outside.
      final probe = driven(
        FakeProgressRepository.failing(
          const DatabaseFailure(message: 'read failed'),
        ),
      );

      await pumpEventQueue();
      final state = probe.container.read(deckActivityLevelProvider(null));

      expect(state.hasError, isTrue);
      expect(state.error, isA<DatabaseFailure>());
    });
  });

  group('the day-boundary wake-up (BR-194)', () {
    testWidgets('re-measures at the next local midnight and not before', (
      tester,
    ) async {
      final boundary = start.add(const Duration(hours: 8));
      final repository = servingBoundary(boundary);
      final probe = driven(repository);
      await tester.pump();

      final readsBefore = repository.levelReadCount;

      // One minute short of the boundary: nothing has expired yet.
      probe.setNow(boundary.subtract(const Duration(minutes: 1)));
      await tester.pump(const Duration(hours: 7, minutes: 59));
      expect(repository.levelReadCount, readsBefore);

      // Across it: the windows have moved with no database write behind them,
      // so the read has to be re-opened at the new `now`.
      probe.setNow(boundary);
      await tester.pump(const Duration(minutes: 1));
      expect(repository.levelReadCount, greaterThan(readsBefore));
      expect(probe.container.read(progressNowProvider), boundary);
    });

    testWidgets('a boundary already behind us refreshes once, not in a loop', (
      tester,
    ) async {
      // The clock reached midnight before the emission was processed. Chasing
      // it is right; chasing it forever is the bug the guard exists to stop.
      final repository = servingBoundary(
        start.subtract(const Duration(days: 1)),
      );
      driven(repository);
      await tester.pump();

      final afterFirstChase = repository.levelReadCount;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(repository.levelReadCount, afterFirstChase);
    });

    testWidgets('leaving the level cancels its pending wake-up', (
      tester,
    ) async {
      // Its own container, disposed inside the test rather than in a teardown:
      // `flutter_test` asserts on pending timers when the test body ends, and a
      // container torn down after that check would let a leaked timer pass.
      final repository = servingBoundary(start.add(const Duration(hours: 2)));
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          progressRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => start),
          utcOffsetProvider.overrideWithValue(() => progressTestOffset),
        ],
      );
      final subscription = container.listen<AsyncValue<DeckActivitySnapshot>>(
        deckActivityLevelProvider(null),
        (_, _) {},
      );
      await tester.pump();

      subscription.close();
      container.dispose();
      await tester.pump();

      // If the timer outlived the level, `flutter_test`'s own end-of-test
      // invariant fails with "A Timer is still pending" — so this test passing
      // at all is the assertion.
      expect(repository.levelReadCount, 1);
    });
  });

  group('the selected window', () {
    test('starts at the shorter one and is not a query parameter', () {
      final repository = FakeProgressRepository();
      final probe = driven(repository);

      expect(
        probe.container.read(progressRangeChoiceProvider),
        ProgressRange.initial,
      );

      probe.container
          .read(progressRangeChoiceProvider.notifier)
          .select(ProgressRange.last30Days);

      expect(
        probe.container.read(progressRangeChoiceProvider),
        ProgressRange.last30Days,
      );
      // Both windows ride on one snapshot, so choosing one must not re-open the
      // read — that is what makes the switch instant and the two windows one
      // snapshot (BR-194).
      expect(repository.levelReadCount, 1);
    });
  });
}
