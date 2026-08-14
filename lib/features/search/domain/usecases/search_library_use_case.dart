import '../models/search_cursor_model.dart';
import '../models/search_page_model.dart';
import '../models/search_query_model.dart';
import '../repositories/library_search_repository.dart';

/// One page of Global Library Search (UC-12).
///
/// **Thin, and that is the accepted cost.** AD-12 asks for a use case per
/// interaction rather than only where there is logic to hold, because uniformity
/// is what makes the next feature a clone instead of a judgement call at every
/// operation. What it does hold is the one rule that must not be re-decided by a
/// caller: the empty query is answered here, without the repository being
/// touched at all (BR-184).
///
/// **It does not debounce and it does not own request identity.** Both belong to
/// the controller: they are about the *sequence* of interactions, and a use case
/// that held a timer would be a use case with a lifetime.
class SearchLibraryUseCase {
  const SearchLibraryUseCase(this._repository);

  final LibrarySearchRepository _repository;

  /// [after] defaults to the first page. [pageSize] is the caller's window.
  Stream<LibrarySearchPage> call({
    required SearchQuery query,
    required int pageSize,
    LibrarySearchCursor after = LibrarySearchCursor.start,
  }) {
    // BR-184, and it is enforced above the repository as well as inside it. Two
    // guards for one rule looks redundant and is not: this one proves the
    // *contract* is never called, which is what `search_zero_io_test.dart`
    // asserts by counting statements with no repository in the container at
    // all.
    if (query.isEmpty) {
      return Stream<LibrarySearchPage>.value(LibrarySearchPage.empty);
    }

    return _repository.watchSearchPage(
      query: query,
      after: after,
      pageSize: pageSize,
    );
  }
}
