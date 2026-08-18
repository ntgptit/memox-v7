import 'dart:async';

import 'package:drift/drift.dart' show TableUpdate;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/search/data/datasources/library_search_dao.dart';
import 'package:memox/features/search/data/repositories/library_search_repository_impl.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';

import '../../../database/support/test_database.dart';

/// The ordering guard: within one settled query, only the newest read may emit.
///
/// **A real database cannot produce this.** Two reads against SQLite complete in
/// the order they were issued, so the interleaving the guard exists for — an
/// earlier read finishing *after* a later one — never happens there, and
/// `search_live_update_test.dart` fires one write at a time. Without this test
/// the guard is correct only by inspection, which is exactly the shape of defect
/// `CLAUDE.md` records having lived through seventy pull requests.
void main() {
  test('a slower earlier read never overwrites a faster later one', () async {
    // A real database goes in and is never read from: every method a search
    // performs is overridden below. It exists because the DAO's constructor
    // takes one, not because a statement is issued.
    final AppDatabase database = openTestDatabase();
    addTearDown(database.close);
    final dao = _SequencedDao(database);
    final repository = LibrarySearchRepositoryImpl.withDao(dao);

    final emitted = <LibrarySearchPage>[];
    final StreamSubscription<LibrarySearchPage> subscription = repository
        .watchSearchPage(
          query: SearchQuery.parse('noun'),
          after: LibrarySearchCursor.start,
          pageSize: 20,
        )
        .listen(emitted.add);
    addTearDown(subscription.cancel);

    // The first read is in flight. Nudge the library so a second one starts
    // before it has answered.
    await pumpEventQueue();
    expect(dao.pending, hasLength(1));
    dao.change();
    await pumpEventQueue();
    expect(dao.pending, hasLength(2), reason: 'two reads are now overlapping');

    // The **second** read answers first, then the first one answers late.
    dao.completeAt(1);
    await pumpEventQueue();
    dao.completeAt(0);
    await pumpEventQueue();

    expect(
      emitted,
      hasLength(1),
      reason:
          'the late answer describes a snapshot the database has moved past',
    );
  });
}

/// A DAO whose reads complete when the test says so.
///
/// Every `allDecks` call parks a completer; `completeAt` resolves one by the
/// order it was started, so a test can answer them out of order.
final class _SequencedDao extends LibrarySearchDao {
  _SequencedDao(super.database);

  final List<Completer<List<Deck>>> pending = <Completer<List<Deck>>>[];
  final StreamController<Set<TableUpdate>> _changes =
      StreamController<Set<TableUpdate>>.broadcast();

  void change() => _changes.add(const <TableUpdate>{});

  void completeAt(int index) => pending[index].complete(const <Deck>[]);

  @override
  Future<T> runInTransaction<T>(Future<T> Function() action) => action();

  @override
  Future<List<Deck>> allDecks() {
    final completer = Completer<List<Deck>>();
    pending.add(completer);

    return completer.future;
  }

  @override
  Future<List<SearchCardRow>> searchCardPage({
    required String folded,
    required int afterTier,
    required String afterKey,
    required DateTime afterCreatedAt,
    required String afterId,
    required int limit,
  }) async => const <SearchCardRow>[];

  @override
  Stream<Set<TableUpdate>> onLibraryChanged() => _changes.stream;
}
