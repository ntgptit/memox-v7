import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/clock_provider.dart';
import 'package:memox/features/deck/di/deck_repository_provider.dart';
import 'package:memox/features/deck/domain/models/deck_list_snapshot_model.dart';
import 'package:memox/features/deck/domain/models/deck_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_now_controller.dart';
import 'package:memox/features/deck/presentation/controllers/deck_list_controller.dart';

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
      container.listen<AsyncValue<DeckListSnapshot>>(
        deckListProvider(null),
        (_, _) {},
      );

      return (container: container, setNow: (DateTime at) => current = at);
    }

    /// A repository whose snapshot always claims the same next boundary.
    FakeDeckRepository servingBoundary(
      DateTime? nextDueAt, {
      DateTime? nextOverdueTickAt,
    }) => FakeDeckRepository(
      deckList: (_) => Stream<DeckListSnapshot>.value(
        fakeListSnapshot(
          <DeckSummary>[
            fakeSummary(id: '1', name: 'Japanese', totalCardCount: 4),
          ],
          nextDueAt: nextDueAt,
          nextOverdueTickAt: nextOverdueTickAt,
        ),
      ),
    );

    testWidgets('every card already due still arms the midnight tick', (
      tester,
    ) async {
      // The hole the second boundary closes (BR-161): with every scheduled
      // card already due, `nextDueAt` goes null — which is exactly when the
      // overdue badge still has to gain a day at local midnight. Without this
      // timer a list left open overnight kept saying "+2d" forever.
      final DateTime midnight = fixedNow.add(const Duration(hours: 5));
      final repository = servingBoundary(null, nextOverdueTickAt: midnight);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.deckListCallCount, 1);

      await tester.pump(const Duration(hours: 4));
      expect(repository.deckListCallCount, 1, reason: 'not before midnight');

      fixture.setNow(midnight.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(hours: 2));

      expect(repository.deckListCallCount, 2);
      expect(
        repository.readInstants.last,
        midnight.add(const Duration(seconds: 1)),
        reason: 'the re-read measures the new day, and the badge with it',
      );
    });

    testWidgets('the earlier of the two boundaries wins', (tester) async {
      // A future due card an hour out beats a midnight five hours out; the
      // re-read then derives the next midnight from its own emission.
      final DateTime dueAt = fixedNow.add(const Duration(hours: 1));
      final DateTime midnight = fixedNow.add(const Duration(hours: 5));
      final repository = servingBoundary(dueAt, nextOverdueTickAt: midnight);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.deckListCallCount, 1);

      fixture.setNow(dueAt.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(hours: 1, minutes: 1));

      expect(repository.deckListCallCount, 2);
    });

    testWidgets('a boundary in the future re-reads when it is crossed', (
      tester,
    ) async {
      // The bug this fixes: the user sits on the list, a card comes due, and the
      // badge keeps saying what it said an hour ago. Resume was the only trigger.
      final DateTime boundary = fixedNow.add(const Duration(minutes: 30));
      final repository = servingBoundary(boundary);
      final fixture = driven(repository, start: fixedNow);
      await tester.pump();
      expect(repository.deckListCallCount, 1);

      // Not yet. A timer that fired early would re-read for nothing.
      await tester.pump(const Duration(minutes: 29));
      expect(repository.deckListCallCount, 1);

      fixture.setNow(boundary.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(minutes: 2));

      expect(repository.deckListCallCount, 2);
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

      expect(repository.deckListCallCount, 1);
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
      expect(repository.deckListCallCount, 1);

      fixture.setNow(fixedNow.add(kMaxDueBoundaryDelay));
      await tester.pump(kMaxDueBoundaryDelay + const Duration(seconds: 1));

      expect(repository.deckListCallCount, 2);
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
        repository.deckListCallCount,
        1,
        reason:
            'a timer surviving disposal would read through a torn-down '
            'provider',
      );
    });

    /// A repository whose first list read is a controller the test feeds by
    /// hand, so the emission lands at an instant the test chooses — after the
    /// clock has moved — instead of whenever `Stream.value` happens to deliver.
    ///
    /// That timing is the whole point of these cases: the race is a snapshot read
    /// at one `now` and *processed* at a later one. Feeding the first emission by
    /// hand, after `setNow`, is the only way to place the clock strictly between
    /// the read and the processing without depending on stream-delivery order.
    ///
    /// [reReadBoundary] is what every read *after* the first returns — `null` for
    /// a healthy repository that has moved past the boundary, or the same past
    /// instant to model a repository stuck on it (the loop-guard case).
    ({FakeDeckRepository repository, void Function(DateTime?) emit}) fed({
      DateTime? reReadBoundary,
    }) {
      final controller = StreamController<DeckListSnapshot>();
      addTearDown(controller.close);
      DeckListSnapshot snapshot(DateTime? nextDueAt) =>
          fakeListSnapshot(<DeckSummary>[
            fakeSummary(id: '1', name: 'Japanese', totalCardCount: 4),
          ], nextDueAt: nextDueAt);
      var opened = 0;
      final repository = FakeDeckRepository(
        deckList: (_) {
          opened += 1;
          return opened == 1
              ? controller.stream
              : Stream<DeckListSnapshot>.value(snapshot(reReadBoundary));
        },
      );

      return (
        repository: repository,
        emit: (DateTime? nextDueAt) => controller.add(snapshot(nextDueAt)),
      );
    }

    testWidgets(
      'a boundary already crossed when the emission lands refreshes at once',
      (tester) async {
        // The race this closes. The query opened at `fixedNow`; by the time its
        // snapshot is processed the clock has passed `nextDueAt`, so a future
        // timer would be armed for a moment already gone. The old code returned
        // and the count sat stale until the next resume. It must refresh now.
        final DateTime boundary = fixedNow.add(const Duration(milliseconds: 5));
        final f = fed();
        final fixture = driven(f.repository, start: fixedNow);
        expect(f.repository.deckListCallCount, 1);
        expect(f.repository.readInstants.single, fixedNow);

        // The clock crosses the boundary, then the snapshot read at `fixedNow`
        // finally lands.
        fixture.setNow(fixedNow.add(const Duration(milliseconds: 10)));
        f.emit(boundary);
        // `pump()` drains the emission microtask and arms the immediate-refresh
        // `Timer(Duration.zero)`; a short non-zero pump is then needed to advance
        // fake time to its deadline and fire it — a zero-duration pump never does.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        expect(
          f.repository.deckListCallCount,
          2,
          reason: 'the crossed boundary must trigger exactly one refresh',
        );
        expect(
          f.repository.readInstants.last,
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
      final f = fed();
      final fixture = driven(f.repository, start: fixedNow);
      expect(f.repository.deckListCallCount, 1);

      fixture.setNow(boundary);
      f.emit(boundary);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(f.repository.deckListCallCount, 2);
      expect(f.repository.readInstants.last, boundary);
    });

    testWidgets(
      'a repository stuck on a past boundary refreshes once, not forever',
      (tester) async {
        // The degenerate input the loop guard exists for: a read that keeps
        // reporting the same already-past boundary however new `now` is. A
        // healthy read advances past it; this one never does, so without the
        // guard the immediate refresh would re-arm on every rebuild.
        final DateTime boundary = fixedNow.add(const Duration(milliseconds: 5));
        final f = fed(reReadBoundary: boundary);
        final fixture = driven(f.repository, start: fixedNow);
        expect(f.repository.deckListCallCount, 1);

        fixture.setNow(fixedNow.add(const Duration(milliseconds: 10)));
        f.emit(boundary);
        // `pump()` drains the emission microtask and arms the immediate-refresh
        // `Timer(Duration.zero)`; a short non-zero pump is then needed to advance
        // fake time to its deadline and fire it — a zero-duration pump never does.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));

        // One immediate refresh — the second read — and then silence, even
        // though the re-read still reports the same past boundary.
        expect(f.repository.deckListCallCount, 2);

        // Pump far past any schedule. The count must not climb: the guard has to
        // refuse a second refresh for a boundary it already chased.
        await tester.pump(const Duration(minutes: 5));
        expect(
          f.repository.deckListCallCount,
          2,
          reason: 'the loop guard must stop a stuck boundary re-refreshing',
        );
      },
    );

    testWidgets('disposing before a stale emission lands mutates nothing', (
      tester,
    ) async {
      // Dispose while a crossed-boundary snapshot is in flight — the exact state
      // that would arm an immediate refresh. The torn-down provider must not be
      // read or mutated, and no timer may be left to fail the pending-timer check.
      final DateTime boundary = fixedNow.add(const Duration(milliseconds: 5));
      final f = fed();
      final fixture = driven(f.repository, start: fixedNow);
      expect(f.repository.deckListCallCount, 1);

      fixture.setNow(fixedNow.add(const Duration(milliseconds: 10)));
      f.emit(boundary);
      fixture.container.dispose();

      await tester.pump();
      await tester.pump(const Duration(minutes: 1));

      expect(
        f.repository.deckListCallCount,
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
      final int readsBeforeBoundary = repository.deckListCallCount;

      fixture.setNow(boundary.add(const Duration(seconds: 1)));
      await tester.pump(const Duration(minutes: 11));

      expect(
        repository.deckListCallCount,
        readsBeforeBoundary + 1,
        reason: 'exactly one wake-up fired, however many times it was re-armed',
      );
    });
  });
}
