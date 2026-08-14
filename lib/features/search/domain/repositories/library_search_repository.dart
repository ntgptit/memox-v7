import '../models/search_cursor_model.dart';
import '../models/search_page_model.dart';
import '../models/search_query_model.dart';

/// Contract for Global Library Search (UC-12).
///
/// Written from what the search screen needs, not from the shape of any table
/// (AD-01): no Drift row, companion or DAO type appears in a signature, and no
/// Drift/SQLite exception escapes an implementation — failures surface as the
/// domain `Failure` hierarchy, thrown from the returned stream.
///
/// **One method, because the screen shows one list.** Decks and cards are two
/// statements underneath and one snapshot above: a screen that read them
/// separately could render a deck's new name in one section and its old name
/// inside a card's path in the same frame (AD-13).
///
/// Reads are `watch()` streams (AD-01): each page re-emits when anything it
/// depends on changes, which is what makes a rename, a move, a tag rename or a
/// delete correct a path already on screen instead of leaving it stale
/// (BR-189).
abstract interface class LibrarySearchRepository {
  /// One page of results for [query], continuing after [after].
  ///
  /// **An empty [query] performs no read at all** (BR-184). The stream emits
  /// [LibrarySearchPage.empty] and completes its first frame without opening a
  /// statement — a whitespace query is not a cheaper search, it is not a search.
  ///
  /// [pageSize] bounds the page. The page is filled with decks first and topped
  /// up with cards once the deck group is exhausted, so the two sections never
  /// interleave (BR-186).
  ///
  /// The returned page's `cursor` is what the next call passes as [after];
  /// passing [LibrarySearchCursor.start] asks for the first page. The cursor is
  /// a keyset, so a write landing between two pages can neither duplicate a row
  /// nor step over one (BR-188).
  Stream<LibrarySearchPage> watchSearchPage({
    required SearchQuery query,
    required LibrarySearchCursor after,
    required int pageSize,
  });
}
