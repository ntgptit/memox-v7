import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_history_cursor_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/controllers/card_history_controller.dart';
import 'package:memox/features/card/presentation/states/card_history_state.dart';

import 'support/fake_card_detail_repository.dart';

/// Paging as a state machine: first page, load-more, failure, retry, end, and
/// the late response that must not land (UC-19 steps 4–6, E4, E5).
void main() {
  ProviderContainer containerWith(FakeCardDetailRepository repository) {
    final container = ProviderContainer(
      overrides: [cardDetailRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    return container;
  }

  /// Subscribes so an `autoDispose` notifier stays alive for the test, and
  /// returns its current state on demand.
  CardHistoryState Function() watch(
    ProviderContainer container,
    String cardId,
  ) {
    final subscription = container.listen(
      cardHistoryProvider(cardId),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    return () => container.read(cardHistoryProvider(cardId));
  }

  test('the first page lands and the timeline is complete when there is no '
      'more', () async {
    final repository = FakeCardDetailRepository()
      ..pages.add(fakeHistoryPage(count: 3));
    final container = containerWith(repository);
    final state = watch(container, 'card-1');

    expect(state().isLoadingInitial, isTrue);
    await pumpEventQueue();

    expect(state().events, hasLength(3));
    expect(state().hasMore, isFalse);
    expect(state().isComplete, isTrue);
    expect(repository.requestedCursors, <CardHistoryCursor?>[null]);
  });

  test('a card with no reviews is empty and not an error (BR-244)', () async {
    final repository = FakeCardDetailRepository()
      ..pages.add(CardHistoryPageModel.empty);
    final container = containerWith(repository);
    final state = watch(container, 'card-1');
    await pumpEventQueue();

    expect(state().isEmpty, isTrue);
    expect(state().hasPageError, isFalse);
    expect(state().isComplete, isFalse);
  });

  test('load-more appends the next page after the cursor, never re-reading '
      'the first', () async {
    final repository = FakeCardDetailRepository()
      ..pages.addAll(<CardHistoryPageModel>[
        fakeHistoryPage(count: 3, hasMore: true),
        fakeHistoryPage(count: 2, prefix: 'f'),
      ]);
    final container = containerWith(repository);
    final state = watch(container, 'card-1');
    await pumpEventQueue();
    final firstCursor = state().nextCursor;

    await container.read(cardHistoryProvider('card-1').notifier).loadMore();

    expect(repository.requestedCursors, <CardHistoryCursor?>[
      null,
      firstCursor,
    ]);
    expect(state().events, hasLength(5));
    expect(state().hasMore, isFalse);
  });

  test('load-more is a no-op at the end of the history', () async {
    final repository = FakeCardDetailRepository()
      ..pages.add(fakeHistoryPage(count: 2));
    final container = containerWith(repository);
    watch(container, 'card-1');
    await pumpEventQueue();

    await container.read(cardHistoryProvider('card-1').notifier).loadMore();

    expect(repository.requestedCursors, hasLength(1));
  });

  test('a second tap while a page is in flight fires nothing', () async {
    final repository = FakeCardDetailRepository()
      ..pages.addAll(<CardHistoryPageModel>[
        fakeHistoryPage(count: 3, hasMore: true),
        fakeHistoryPage(count: 2, prefix: 'f'),
      ]);
    final container = containerWith(repository);
    final state = watch(container, 'card-1');
    await pumpEventQueue();

    final gate = Completer<void>();
    repository.historyGate = gate;
    final notifier = container.read(cardHistoryProvider('card-1').notifier);
    final first = notifier.loadMore();
    await pumpEventQueue();
    expect(state().isLoadingMore, isTrue);

    await notifier.loadMore();
    gate.complete();
    await first;
    await pumpEventQueue();

    // Two taps, one request: a double tap must not fire one cursor twice.
    expect(repository.requestedCursors, hasLength(2));
    expect(state().events, hasLength(5));
  });

  group('failure and retry (UC-19 E4)', () {
    test('a failed page keeps everything already on screen', () async {
      final repository = FakeCardDetailRepository()
        ..pages.add(fakeHistoryPage(count: 3, hasMore: true));
      final container = containerWith(repository);
      final state = watch(container, 'card-1');
      await pumpEventQueue();

      repository.nextHistoryFailure = const DatabaseFailure(
        message: 'read failed',
      );
      await container.read(cardHistoryProvider('card-1').notifier).loadMore();

      expect(state().hasPageError, isTrue);
      expect(state().events, hasLength(3));
      expect(state().nextCursor, isNotNull);
    });

    test('retry resumes from the same cursor, so nothing is appended '
        'twice', () async {
      final repository = FakeCardDetailRepository()
        ..pages.addAll(<CardHistoryPageModel>[
          fakeHistoryPage(count: 3, hasMore: true),
          fakeHistoryPage(count: 2, prefix: 'f'),
        ]);
      final container = containerWith(repository);
      final state = watch(container, 'card-1');
      await pumpEventQueue();
      final cursor = state().nextCursor;

      repository.nextHistoryFailure = const DatabaseFailure(message: 'boom');
      final notifier = container.read(cardHistoryProvider('card-1').notifier);
      await notifier.loadMore();
      await notifier.loadMore();

      expect(repository.requestedCursors, <CardHistoryCursor?>[
        null,
        cursor,
        cursor,
      ]);
      expect(state().events, hasLength(5));
      expect(state().hasPageError, isFalse);
    });

    test('a failed first page retries as a first page, not from a cursor it '
        'does not have', () async {
      final repository = FakeCardDetailRepository()
        ..nextHistoryFailure = const DatabaseFailure(message: 'boom')
        ..pages.add(fakeHistoryPage(count: 2));
      final container = containerWith(repository);
      final state = watch(container, 'card-1');
      await pumpEventQueue();
      expect(state().hasPageError, isTrue);
      expect(state().events, isEmpty);

      await container.read(cardHistoryProvider('card-1').notifier).loadMore();

      expect(repository.requestedCursors, <CardHistoryCursor?>[null, null]);
      expect(state().events, hasLength(2));
    });
  });

  test('a page that lands after the reader has left is dropped rather than '
      'written into a disposed notifier (UC-19 E5)', () async {
    final repository = FakeCardDetailRepository()
      ..pages.add(fakeHistoryPage(count: 3));
    final container = ProviderContainer(
      overrides: [cardDetailRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(
      cardHistoryProvider('card-1'),
      (_, _) {},
      fireImmediately: true,
    );
    final gate = Completer<void>();
    repository.historyGate = gate;
    await pumpEventQueue();

    // The reader leaves while the first page is still in flight.
    subscription.close();
    container.dispose();
    gate.complete();

    // No throw, and nothing written: `ref.mounted` is what makes leaving a
    // screen mid-read a non-event rather than a state write into a disposed
    // notifier.
    await expectLater(pumpEventQueue(), completes);
    expect(repository.requestedCursors, hasLength(1));
  });

  test('every event on screen is distinct, so nothing can be appended '
      'twice (BR-241)', () async {
    // The keyset makes the pages disjoint; this is the controller-side check
    // that appending preserves that, including if a page were to overlap.
    final overlapping = fakeHistoryPage(count: 3, hasMore: true);
    final repository = FakeCardDetailRepository()
      ..pages.addAll(<CardHistoryPageModel>[
        overlapping,
        CardHistoryPageModel(
          events: overlapping.events,
          hasMore: false,
          nextCursor: null,
        ),
      ]);
    final container = containerWith(repository);
    final state = watch(container, 'card-1');
    await pumpEventQueue();

    await container.read(cardHistoryProvider('card-1').notifier).loadMore();

    expect(state().events, hasLength(3));
    expect(
      state().events.map((event) => event.id).toSet(),
      hasLength(state().events.length),
    );
  });
}
