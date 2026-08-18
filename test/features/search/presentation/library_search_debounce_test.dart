import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/app/config/env_config.dart';
import 'package:memox/app/config/env_config_provider.dart';
import 'package:memox/core/time/delay_provider.dart';
import 'package:memox/features/search/di/library_search_repository_provider.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';
import 'package:memox/features/search/presentation/controllers/library_search_controller.dart';
import 'package:memox/features/search/presentation/states/library_search_state.dart';

import 'support/fake_library_search_repository.dart';
import 'support/search_screen_harness.dart';

/// BR-249's debounce, and the request identity that makes a late answer
/// harmless.
///
/// **Driven through an injected scheduler, not through the event loop.** A
/// debounce measured against real time can only be asserted with
/// `await Future.delayed`, which makes "did it fire at 249ms or at 250?" a race
/// — and the two sides of that boundary are the whole rule.
void main() {
  late FakeDelayScheduler scheduler;
  late FakeLibrarySearchRepository repository;

  /// Lets every pending microtask and stream event land, so an assertion sees
  /// the state the screen would have painted.
  Future<void> settle() => pumpEventQueue();

  ProviderContainer buildContainer({bool shouldDisposeAutomatically = true}) {
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(EnvConfig.development),
        librarySearchRepositoryProvider.overrideWithValue(repository),
        delaySchedulerProvider.overrideWithValue(scheduler.schedule),
      ],
    );
    if (shouldDisposeAutomatically) addTearDown(container.dispose);
    // Keeps the autoDispose chain alive for the length of the test, exactly as
    // a mounted screen would.
    container.listen(
      librarySearchResultsProvider,
      (_, _) {},
      fireImmediately: true,
    );

    return container;
  }

  setUp(() {
    scheduler = FakeDelayScheduler();
    repository = FakeLibrarySearchRepository.serving(fakeSearchPage());
  });

  test(
    'typing arms the debounce at 250ms and reads nothing before it',
    () async {
      final container = buildContainer();

      container.read(librarySearchQueryProvider.notifier).update('noun');
      await settle();

      expect(scheduler.lastDelay, kLibrarySearchDebounce);
      expect(
        kLibrarySearchDebounce,
        const Duration(milliseconds: 250),
        reason: 'the number itself is the rule',
      );
      expect(
        repository.calls,
        isEmpty,
        reason: 'at 249ms the window has not closed and nothing has been asked',
      );
      expect(
        container.read(librarySearchResultsProvider).phase,
        LibrarySearchPhase.initial,
        reason: 'the settled query has not moved, so no page exists yet',
      );
    },
  );

  test('the read happens once the window closes', () async {
    final container = buildContainer();

    container.read(librarySearchQueryProvider.notifier).update('noun');
    scheduler.fire();
    await settle();

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.query.folded, 'noun');
    expect(repository.calls.single.pageSize, kLibrarySearchPageSize);
    expect(
      container.read(librarySearchResultsProvider).phase,
      LibrarySearchPhase.ready,
    );
  });

  test('a burst of keystrokes reads once, for the last of them', () async {
    final container = buildContainer();
    final notifier = container.read(librarySearchQueryProvider.notifier);

    for (final String typed in <String>['n', 'no', 'nou', 'noun']) {
      notifier.update(typed);
      expect(
        scheduler.hasPending,
        isTrue,
        reason: 'each keystroke arms a fresh window',
      );
    }
    expect(
      scheduler.cancellations,
      3,
      reason: 'every earlier window was called off, not left to fire',
    );

    scheduler.fire();
    await settle();

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.query.folded, 'noun');
  });

  test('clearing is immediate, and reads nothing', () async {
    final container = buildContainer();
    final notifier = container.read(librarySearchQueryProvider.notifier);

    notifier.update('noun');
    scheduler.fire();
    await settle();
    expect(repository.calls, hasLength(1));

    notifier.update('   ');
    await settle();

    expect(
      container.read(librarySearchQueryProvider),
      SearchQuery.empty,
      reason:
          'an empty query must not wait — the initial state is owed at once',
    );
    expect(
      container.read(librarySearchResultsProvider).phase,
      LibrarySearchPhase.initial,
    );
    expect(
      repository.calls,
      hasLength(1),
      reason: 'clearing opens no statement of its own (BR-249)',
    );
  });

  test(
    're-typing a query that normalises the same reads nothing again',
    () async {
      final container = buildContainer();
      final notifier = container.read(librarySearchQueryProvider.notifier);

      notifier.update('noun');
      scheduler.fire();
      await settle();

      notifier.update('noun');
      await settle();

      expect(scheduler.hasPending, isFalse);
      expect(repository.calls, hasLength(1));
    },
  );

  test('a late answer from an abandoned query never reaches the state', () async {
    // The stale-result rule. The abandoned query's stream is still open when the
    // new one starts; the provider that owned it has been rebuilt, so whatever
    // it says next has nowhere to arrive.
    // Created up front and closed in one place, so the two queries have a
    // feed each and neither is left open when the test ends.
    final old = StreamController<LibrarySearchPage>.broadcast();
    final fresh = StreamController<LibrarySearchPage>.broadcast();
    addTearDown(old.close);
    addTearDown(fresh.close);
    repository = FakeLibrarySearchRepository(
      (query, _, _) => query.folded == 'old' ? old.stream : fresh.stream,
    );

    final container = buildContainer();
    final notifier = container.read(librarySearchQueryProvider.notifier);

    notifier.update('old');
    scheduler.fire();
    await settle();

    notifier.update('new');
    scheduler.fire();
    await settle();
    fresh.add(fakeSearchPage());
    await settle();

    // The abandoned query answers now, long after the user moved on.
    old
      ..add(fakeSearchPage())
      ..addError(StateError('late failure from an old query'));
    await settle();

    final LibrarySearchState state = container.read(
      librarySearchResultsProvider,
    );
    expect(
      state.query.folded,
      'new',
      reason:
          'the state belongs to the query in the field, not to the last answer '
          'that happened to arrive',
    );
    expect(
      state.phase,
      LibrarySearchPhase.ready,
      reason: 'a late error from an abandoned query must not fail the screen',
    );
  });

  test('disposing cancels the armed window', () async {
    final container = buildContainer(shouldDisposeAutomatically: false);

    container.read(librarySearchQueryProvider.notifier).update('noun');
    expect(scheduler.hasPending, isTrue);

    container.dispose();

    expect(scheduler.cancellations, 1);
    expect(
      repository.calls,
      isEmpty,
      reason: 'a screen left before the window closed reads nothing',
    );
  });
}
