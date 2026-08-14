import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_page_model.dart';
import 'package:memox/features/search/domain/models/search_query_model.dart';
import 'package:memox/features/search/domain/usecases/search_library_use_case.dart';

import '../presentation/support/fake_library_search_repository.dart';

/// BR-184, at the use case: an empty query never reaches the contract.
///
/// **Asserted on the calls, not on the result.** An implementation that read the
/// database and returned nothing would produce exactly the same page as one that
/// read nothing at all, so the only assertion that can tell them apart is that
/// the repository was never asked.
void main() {
  for (final String raw in <String>['', ' ', '\n\t ']) {
    test(
      'a query of ${raw.length} whitespace characters asks nothing',
      () async {
        final repository = FakeLibrarySearchRepository.serving(
          fakeSearchPage(),
        );
        final useCase = SearchLibraryUseCase(repository);

        final LibrarySearchPage page = await useCase(
          query: SearchQuery.parse(raw),
          pageSize: 20,
        ).first;

        expect(page, same(LibrarySearchPage.empty));
        expect(repository.calls, isEmpty);
      },
    );
  }

  test('a real query is passed through unchanged', () async {
    final repository = FakeLibrarySearchRepository.serving(fakeSearchPage());
    final useCase = SearchLibraryUseCase(repository);

    await useCase(query: SearchQuery.parse(' Noun '), pageSize: 7).first;

    expect(repository.calls, hasLength(1));
    expect(repository.calls.single.query.folded, 'noun');
    expect(repository.calls.single.pageSize, 7);
    expect(repository.calls.single.after, LibrarySearchCursor.start);
  });
}
