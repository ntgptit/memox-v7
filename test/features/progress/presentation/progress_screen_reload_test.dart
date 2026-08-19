import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/deck_activity_snapshot_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:memox/features/progress/presentation/widgets/sections/progress_streak_hero_widget.dart';
import 'package:memox/shared/widgets/mx_loading_state.dart';

import 'support/fake_progress_repository.dart';
import 'support/progress_screen_harness.dart';

/// A resume is a transition between two loaded states (UC-12 UI states,
/// wireframe P8), and this file is the only place that can prove the screen
/// treats it as one.
///
/// **Why the shared fake cannot.** `FakeProgressRepository.watchProgressOverview`
/// is an `async*` that yields its seed on subscription, so the replacement value
/// is already there in the frame after the rebuild — the loading state exists for
/// no frame anybody can observe, and an assertion that no spinner appears passes
/// whatever the widget's reload policy is. A real drift `watch()` needs a turn of
/// the event loop before its first row arrives; the repository below models that.
/// With `shouldSkipLoadingOnReload` left at its default the resume test fails: the
/// frame after a resume renders `MxLoadingState` over three populated sections,
/// for as long as a full scan of `study_answers` takes. **That test is the
/// policy pin**; the midnight one says in its own doc what it does and does not
/// prove.
class _DeferredProgressRepository implements ProgressRepository {
  _DeferredProgressRepository(this._snapshot);

  final ProgressOverview _snapshot;

  /// How many times the screen opened a read.
  int subscriptions = 0;

  /// How long the first row takes to arrive.
  ///
  /// Non-zero on purpose. A zero-delay future is still a timer, so a `pump` that
  /// elapses hours to fire the midnight wake-up would run it in the same call
  /// and hand the frame its data before anybody could look — which is how the
  /// original S-g assertion came to hold no matter what the widget did.
  static const Duration readDuration = Duration(milliseconds: 50);

  @override
  Stream<ProgressOverview> watchProgressOverview({
    required DateTime now,
    required Duration utcOffset,
  }) {
    subscriptions++;

    return Stream<ProgressOverview>.fromFuture(
      Future<ProgressOverview>.delayed(readDuration, () => _snapshot),
    );
  }

  /// The level read is not the subject here, so it answers at once with an
  /// empty level: what this file measures is the frame after the *overview*
  /// re-opens, and a level that also took a turn of the event loop would put a
  /// second reason on screen for the same frame.
  @override
  Stream<DeckActivitySnapshot> watchDeckActivity({
    required String? deckId,
    required DateTime now,
    required Duration utcOffset,
  }) => Stream<DeckActivitySnapshot>.value(emptyActivitySnapshot());
}

void main() {
  ProgressOverview snapshot() => progressOverviewFixture(
    totals: const <int>[3, 5, 0, 2, 7, 4, 6],
    streakDays: 5,
    today: DateTime.utc(2026, 8, 12),
  );

  testWidgets('an app resume re-reads without flashing a spinner over the '
      'sections', (tester) async {
    final repository = _DeferredProgressRepository(snapshot());
    // Production reads the wall clock, so every resume hands `ProgressNow` a
    // different instant and the dependency genuinely changes. A pinned clock
    // makes `refresh()` a no-op and the whole path unobservable.
    DateTime now = progressTestNow;

    await pumpProgressScreen(tester, repository: repository, clock: () => now);
    await tester.pumpAndSettle();
    expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
    expect(repository.subscriptions, 1);

    now = progressTestNow.add(const Duration(minutes: 3));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    // The frame straight after the rebuild is the one that used to be a
    // spinner. The sections must still be there, holding the previous numbers,
    // until the new ones arrive.
    await tester.pump();
    expect(repository.subscriptions, 2);
    expect(find.byType(MxLoadingState), findsNothing);
    expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MxLoadingState), findsNothing);
    expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);
  });

  /// The midnight path, for coverage rather than as the policy pin.
  ///
  /// Said plainly because the point of this file is that a green test is not
  /// evidence: with `shouldSkipLoadingOnReload` removed, the resume test above fails
  /// and **this one still passes**. The wake-up fires inside a timer and the
  /// tree it produces settles differently from a lifecycle event, so what this
  /// asserts is that the read really re-opens at the new local day and the
  /// sections survive it — not which reload policy the widget uses. Do not
  /// treat it as the second half of a proof.
  testWidgets('crossing local midnight re-opens the read at the new day', (
    tester,
  ) async {
    final repository = _DeferredProgressRepository(snapshot());
    DateTime now = progressTestNow;

    await pumpProgressScreen(tester, repository: repository, clock: () => now);
    await tester.pumpAndSettle();
    expect(repository.subscriptions, 1);

    // The timer was armed for the snapshot's `nextLocalMidnight`, twelve hours
    // out. Elapse exactly that and no more: a longer pump would run the
    // repository's own zero-delay timer in the same call and skip past the one
    // frame this is about.
    now = DateTime.utc(2026, 8, 13);
    await tester.pump(const Duration(hours: 12));
    expect(repository.subscriptions, 2);

    // One more frame, elapsing nothing: the provider re-opened synchronously
    // inside the timer, but the widget has not rebuilt yet, so the previous
    // frame still holds the old tree either way. This is the frame that used to
    // be a spinner — and the read has not landed, because it takes
    // [_DeferredProgressRepository.readDuration].
    await tester.pump();
    expect(find.byType(MxLoadingState), findsNothing);
    expect(find.byType(ProgressStreakHeroWidget), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(MxLoadingState), findsNothing);
  });
}
