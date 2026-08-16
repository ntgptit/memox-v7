import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_history_cursor_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/domain/usecases/load_card_history_page_use_case.dart';
import 'package:memox/features/card/domain/usecases/watch_card_detail_use_case.dart';

import '../presentation/support/fake_card_detail_repository.dart';

/// The two detail interactions, and the one thing a thin use case can still get
/// wrong (UC-19).
///
/// **A pass-through with an optional parameter is exactly where a slice has
/// broken before.** `watchCardListItems` dropped `searchTerm` and `sort` on the
/// floor: the call compiled, the analyzer was clean, and the card list shipped
/// with an inert sort control. The lock is cheap and it is this file.
void main() {
  group('LoadCardHistoryPageUseCase', () {
    test('forwards the card id and asks for the first page when no cursor is '
        'given', () async {
      final repository = FakeCardDetailRepository()
        ..pages.add(fakeHistoryPage(count: 2));

      await LoadCardHistoryPageUseCase(repository)('card-9');

      expect(repository.requestedCursors, <CardHistoryCursor?>[null]);
    });

    test('forwards the cursor, so a load-more cannot silently restart at page '
        'one', () async {
      final repository = FakeCardDetailRepository()
        ..pages.add(CardHistoryPageModel.empty);
      final cursor = CardHistoryCursor(answeredAt: fakeNow, id: 'e-49');

      await LoadCardHistoryPageUseCase(repository)('card-9', after: cursor);

      expect(repository.requestedCursors.single, cursor);
    });

    test('returns the page as the repository built it', () async {
      final page = fakeHistoryPage(count: 3, hasMore: true);
      final repository = FakeCardDetailRepository()..pages.add(page);

      final result = await LoadCardHistoryPageUseCase(repository)('card-9');

      expect(result.events, hasLength(3));
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, page.events.last.cursor);
    });
  });

  group('WatchCardDetailUseCase', () {
    test('passes the stream through', () async {
      final repository = FakeCardDetailRepository()
        ..seededDetail = fakeCardDetail(front: '사과');

      final detail = await WatchCardDetailUseCase(repository)('card-1').first;

      expect(detail.card.front, '사과');
    });
  });

  group('CardHistoryCursor', () {
    test('two cursors on the same row are equal, which is what lets a stale '
        'request be recognised', () {
      final first = CardHistoryCursor(answeredAt: fakeNow, id: 'e-1');
      final second = CardHistoryCursor(answeredAt: fakeNow, id: 'e-1');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('rows sharing an instant are different cursors', () {
      expect(
        CardHistoryCursor(answeredAt: fakeNow, id: 'e-1'),
        isNot(CardHistoryCursor(answeredAt: fakeNow, id: 'e-2')),
      );
    });

    test('printing a cursor leaks neither the id nor the instant (BR-51)', () {
      final cursor = CardHistoryCursor(answeredAt: fakeNow, id: 'private-id');

      expect(cursor.toString(), isNot(contains('private-id')));
      expect(cursor.toString(), isNot(contains('2026')));
    });
  });

  group('CardHistoryPageModel', () {
    test('the empty page is also the end, so nothing offers a load-more with '
        'nothing behind it', () {
      expect(CardHistoryPageModel.empty.events, isEmpty);
      expect(CardHistoryPageModel.empty.hasMore, isFalse);
      expect(CardHistoryPageModel.empty.nextCursor, isNull);
    });
  });

  group('CardHistoryEventModel.hasScheduleChange', () {
    test('a turn that recorded no schedule column moved nothing (BR-144)', () {
      final event = fakeHistoryEvent(
        id: 'e-1',
        previousBox: null,
        nextBox: null,
      );

      expect(event.hasScheduleChange, isFalse);
    });

    test('a scheduled review of a box-8 card counts as a schedule change even '
        'though the box did not move (BR-76)', () {
      final event = fakeHistoryEvent(id: 'e-1', previousBox: 8, nextBox: 8);

      // The inference AD-11 forbids would call this "unchanged"; the row says
      // otherwise, and the row is what is shown.
      expect(event.hasScheduleChange, isTrue);
    });
  });
}
