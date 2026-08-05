import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_sort_model.dart';
import 'package:memox/features/card/domain/usecases/watch_card_list_items_use_case.dart';

import '../presentation/support/fake_card_repository.dart';

/// Regression lock for the parameter drop IT-ORG-001 exposed.
///
/// The use case accepted `sort` and `searchTerm` and then forwarded a call
/// without them — legal Dart, because both are optional with defaults, so no
/// analyzer or compiler step could object. The symptom was a card list whose
/// count filtered while its rows did not ("Showing 3 of 1"), and a sort
/// control that changed nothing. This test pins the seam itself: whatever the
/// use case accepts, the repository must receive.
void main() {
  test('every accepted parameter reaches the repository', () async {
    final repository = FakeCardRepository();
    addTearDown(repository.dispose);
    final useCase = WatchCardListItemsUseCase(repository);
    final now = DateTime.utc(2026, 8, 5, 9);

    useCase(
      'deck-1',
      limit: 75,
      filter: CardListFilter.flagged,
      sort: CardListSort.dueFirst,
      searchTerm: 'nhân từ',
      now: now,
    ).listen((_) {});
    await Future<void>.delayed(Duration.zero);

    expect(repository.requestedLimits, <int>[75]);
    expect(repository.requestedFilters, <CardListFilter>[
      CardListFilter.flagged,
    ]);
    expect(repository.requestedSorts, <CardListSort>[
      CardListSort.dueFirst,
    ], reason: 'sort was accepted but never forwarded');
    expect(
      repository.requestedSearchTerms,
      <String?>['nhân từ'],
      reason: 'searchTerm was accepted but never forwarded',
    );
  });
}
