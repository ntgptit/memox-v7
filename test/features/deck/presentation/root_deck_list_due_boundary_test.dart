import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/root_deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/root_deck_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_now_controller.dart';
import 'package:memox/features/deck/presentation/controllers/root_deck_list_controller.dart';

import 'support/fake_deck_repository.dart';

/// The due-boundary wake-up: the deck list re-measuring while the screen is open.
///
/// Split from `root_deck_list_controller_test.dart`, which keeps the read states
/// and the subscription lifecycle. The split was forced by the 400-line file limit
/// and is the right shape anyway: these cases all drive a `Timer` on fake time,
/// which is a different apparatus from the rest.
///
/// **The bug they cover.** The list re-measured only when the app returned to the
/// foreground. A user sitting on it when a card came due kept seeing the old
/// count, so the badge said 3 while the session it launches handed out 4 — which
/// reads as a scheduler bug and is not one.
void main() {
  final fixedNow = DateTime.utc(2026, 7, 29, 12);

  group('the due boundary', () {
    /// A container whose clock advances itself to whatever instant it is asked
    /// for, driven inside `testWidgets` so `Timer` runs on fake time.
    ///
    /// The clock has to move when the timer fires, or the test proves nothing: a
    /// re-measure at the same instant reads the same counts and the guard in
    /// `_armBoundary` would then refuse to re-arm. So `setNow` is called from the
    /// test as it pumps, mirroring what a real clock does while a real timer waits.
    ({ProviderContainer container, void Function(DateTime) setNow}) driven(
      FakeDeckRepository repository, {
      required DateTime start,
    }) {
      var current = start;
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(EnvConfig.development),
          deckRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => current),
        ],
      );
      addTearDown(container.dispose);
      container.listen<AsyncValue<RootDeckListSnapshot>>(
        rootDeckListProvider,
        (_, _) {},
      );

      return (container: container, setNow: (DateTime at) => current = at);
    }

    /// A repository whose snapshot always claims the same next boundary.
    FakeDeckRepository servingBoundary(DateTime? nextDueAt) =>
        FakeDeckRepository(
          summaries: () => Stream<RootDeckListSnapshot>.value(
            fakeListSnapshot(<RootDeckSummary>[
              fakeSummary(id: '1', name: 'Japanese', totalCardCount: 4),
            ], nextDueAt: nextDueAt),
          ),
        );

    testWidgets('a boundary in the future re-reads when it is crossed', (
      tester,
    ) async {
      // The bug this fixes: the user sits on the list, a card comes due, and the
      // badge keeps saying what it said an hour ago. Resume was the only trigger.
      final DateTime boundary = fixedNow.add(const Duration(minutes: 30));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.summariesCallCount, 1);

      // Not yet. A timer that fired early would re-read for nothing.
      await tester.pump(const Duration(minutes: 29));
      expect(repository.summariesCallCount, 1);

      fixture.setNow(boundary.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(minutes: 2));

      expect(repository.summariesCallCount, 2);
      expect(
        repository.readInstants.last,
        boundary.add(const Duration(seconds: 1)),
        reason: 'the re-read must measure against the new instant, not the old',
      );
    });

    testWidgets('no boundary means no timer at all', (tester) async {
      // Nothing scheduled to come due — no cards, or every card already due. A
      // periodic timer would wake here anyway; this one does not exist.
      final repository = servingBoundary(null);
      driven(repository, start: fixedNow);
      await tester.pump();

      await tester.pump(const Duration(days: 2));

      expect(repository.summariesCallCount, 1);
      // `flutter_test` fails a test that leaves a Timer pending, so reaching the
      // end of this one is itself the assertion that none was armed.
    });

    testWidgets('a boundary past the ceiling still re-measures', (
      tester,
    ) async {
      // `kMaxDueBoundaryDelay` exists because a `setTimeout` delay is a 32-bit
      // millisecond count on the web. A boundary beyond it must degrade to one
      // wake at the ceiling, not to a timer that fires immediately and forever.
      final repository = servingBoundary(
        fixedNow.add(const Duration(days: 400)),
      );
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.summariesCallCount, 1);

      fixture.setNow(fixedNow.add(kMaxDueBoundaryDelay));
      await tester.pump(kMaxDueBoundaryDelay + const Duration(seconds: 1));

      expect(repository.summariesCallCount, 2);
      expect(repository.readInstants.last, fixedNow.add(kMaxDueBoundaryDelay));

      // Disposed here rather than in a tear-down, because this is the one case
      // that *does* leave a timer armed: 399 days still remain, so the ceiling
      // fires again. `flutter_test` asserts on pending timers before tear-downs
      // run, and that assertion is worth keeping — so the test says explicitly
      // that it is ending a still-running schedule.
      fixture.container.dispose();
    });

    testWidgets('disposing cancels the pending wake-up', (tester) async {
      final repository = servingBoundary(
        fixedNow.add(const Duration(minutes: 30)),
      );
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();

      fixture.container.dispose();
      await tester.pump(const Duration(hours: 2));

      expect(
        repository.summariesCallCount,
        1,
        reason:
            'a timer surviving disposal would read through a torn-down '
            'provider',
      );
    });

    testWidgets(
      'a boundary already crossed when the emission lands refreshes at once',
      (tester) async {
        // The race this closes. The query opened at `fixedNow`; by the time its
        // snapshot is processed the clock has passed `nextDueAt`, so a future
        // timer would be armed for a moment already gone. The old code returned
        // and the count sat stale until the next resume. It must refresh now.
        //
        // Driven without an intervening pump: `driven` builds and subscribes
        // synchronously, so the first read has already run at `fixedNow` while
        // its `Stream.value` is still in flight. Advancing the clock before the
        // pump is exactly the gap between reading a snapshot and processing it.
        final DateTime boundary = fixedNow.add(const Duration(milliseconds: 5));
        final repository = servingBoundary(boundary);
        final fixture = driven(repository, start: fixedNow);
        expect(repository.summariesCallCount, 1);
        expect(repository.readInstants.single, fixedNow);

        fixture.setNow(fixedNow.add(const Duration(milliseconds: 10)));
        await tester.pump();
        await tester.pump();

        expect(
          repository.summariesCallCount,
          2,
          reason: 'the crossed boundary must trigger exactly one refresh',
        );
        expect(
          repository.readInstants.last,
          fixedNow.add(const Duration(milliseconds: 10)),
          reason: 'the refresh must re-measure against the new instant',
        );
      },
    );

    testWidgets('a boundary exactly at the current instant refreshes once', (
      tester,
    ) async {
      // BR-22's equality case, on the wake-up side: `nextDueAt == now` is a
      // crossing, not a future boundary, so it takes the immediate path.
      final DateTime boundary = fixedNow.add(const Duration(minutes: 5));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      expect(repository.summariesCallCount, 1);

      fixture.setNow(boundary);
      await tester.pump();
      await tester.pump();

      expect(repository.summariesCallCount, 2);
      expect(repository.readInstants.last, boundary);
    });

    testWidgets(
      'a repository stuck on a past boundary refreshes once, not forever',
      (tester) async {
        // The degenerate input the loop guard exists for: a read that keeps
        // reporting the same already-past boundary however new `now` is. A
        // healthy read advances past it; this one never does, so without the
        // guard the immediate refresh would re-arm on every rebuild.
        final DateTime boundary = fixedNow.add(const Duration(milliseconds: 5));
        final repository = servingBoundary(boundary);
        final fixture = driven(repository, start: fixedNow);
        expect(repository.summariesCallCount, 1);

        fixture.setNow(fixedNow.add(const Duration(milliseconds: 10)));
        await tester.pump();
        await tester.pump();

        // One immediate refresh — the second read — and then silence.
        expect(repository.summariesCallCount, 2);

        // Pump far past any schedule. The count must not climb: the guard has to
        // refuse a second refresh for a boundary it already chased.
        await tester.pump(const Duration(minutes: 5));
        expect(
          repository.summariesCallCount,
          2,
          reason: 'the loop guard must stop a stuck boundary re-refreshing',
        );
      },
    );

    testWidgets('disposing before a stale emission lands mutates nothing', (
      tester,
    ) async {
      // Dispose while a crossed-boundary snapshot is in flight — the exact state
      // that arms an immediate refresh. The torn-down provider must not be read
      // or mutated, and no timer may be left to fail the pending-timer check.
      final DateTime boundary = fixedNow.add(const Duration(milliseconds: 5));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      expect(repository.summariesCallCount, 1);

      fixture.setNow(fixedNow.add(const Duration(milliseconds: 10)));
      fixture.container.dispose();

      await tester.pump();
      await tester.pump(const Duration(minutes: 1));

      expect(
        repository.summariesCallCount,
        1,
        reason: 'a disposed provider must not re-read from a late emission',
      );
    });

    testWidgets('one emission never leaves two timers pending', (tester) async {
      // Each rebuild re-arms. If the previous timer were not cancelled, the
      // wake-ups would multiply with every re-read — the failure mode that makes a
      // timer bug look like a performance problem months later.
      final DateTime boundary = fixedNow.add(const Duration(minutes: 10));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();

      // Three rebuilds, each arming a timer for the same boundary.
      for (var i = 1; i <= 3; i++) {
        fixture.setNow(fixedNow.add(Duration(seconds: i)));
        fixture.container.read(deckListNowProvider.notifier).refresh();
        await tester.pump();
      }
      final int readsBeforeBoundary = repository.summariesCallCount;

      fixture.setNow(boundary.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(minutes: 11));

      expect(
        repository.summariesCallCount,
        readsBeforeBoundary + 1,
        reason: 'exactly one wake-up fired, however many times it was re-armed',
      );
    });
  });
}
