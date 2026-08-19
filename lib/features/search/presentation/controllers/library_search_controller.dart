import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../../../core/time/delay_provider.dart';
import '../../domain/models/search_page_model.dart';
import '../../domain/models/search_query_model.dart';
import '../../domain/usecases/search_library_use_case.dart';
import '../providers/search_use_case_provider.dart';
import '../states/library_search_state.dart';

part 'library_search_controller.g.dart';

/// How long the field must be quiet before the database is asked (BR-249).
///
/// **250ms, and it lives at this seam rather than inside the `TextField`.** A
/// debounce in the widget would make "did it wait?" a question about the widget
/// tree, answerable only by pumping frames — and the next surface that searches
/// would implement it again. Here there is one timer with one owner, and
/// `library_search_debounce_test.dart` can sit at 249ms and at 250ms exactly.
const Duration kLibrarySearchDebounce = Duration(milliseconds: 250);

/// How many results one page carries.
///
/// **Smaller than the card list's window of 50, deliberately.** That is a window
/// that grows and is re-read whole; this is a keyset page, every row is three
/// lines tall (path, front, back) and the first page is re-read every time the
/// query settles. Twenty fills a phone screen twice over and keeps the read the
/// user is waiting on short.
const int kLibrarySearchPageSize = 20;

/// The query the database is actually asked for — the field's text, settled.
///
/// **An input-state notifier**, the same kind as the deck list's filter and sort
/// choices: a value the UI owns that every read below is parameterized by. What
/// is in the field is *not* here; that is being typed and belongs to the field.
///
/// **Clearing is immediate, typing waits** (BR-249). An empty query has nothing
/// to debounce: it must put the initial state back on screen at once, and it
/// opens no statement either way.
@riverpod
class LibrarySearchQuery extends _$LibrarySearchQuery {
  DelayHandle? _pendingDebounce;

  @override
  SearchQuery build() {
    ref.onDispose(_cancelDebounce);

    return SearchQuery.empty;
  }

  /// One mutator, deliberately. A second setter for "clear" would be the shape
  /// `command_query_separation_test.dart` refuses, and it refuses it correctly:
  /// a notifier with two setters is the shape that grows a third.
  void update(String rawInput) {
    final SearchQuery query = SearchQuery.parse(rawInput);
    // Whatever was armed describes text the user has already moved past.
    _cancelDebounce();

    // `a` and `a ` normalise to the same search, and the answer is on screen.
    if (query == state) return;

    if (query.isEmpty) {
      state = SearchQuery.empty;

      return;
    }

    final DelayScheduler schedule = ref.read(delaySchedulerProvider);
    _pendingDebounce = schedule(kLibrarySearchDebounce, () {
      _pendingDebounce = null;
      state = query;
    });
  }

  void _cancelDebounce() {
    _pendingDebounce?.call();
    _pendingDebounce = null;
  }
}

/// How many pages are open, and therefore how far the results extend.
///
/// **It resets itself when the query changes** — `build` watches the query, so a
/// new search starts at one page without anything having to remember to clear
/// it. That is the same shape `CardListWindow` uses, with the query in place of
/// the deck id.
@riverpod
class LibrarySearchPageCount extends _$LibrarySearchPageCount {
  @override
  int build() {
    ref.watch(librarySearchQueryProvider);

    return 1;
  }

  /// Opens one more page. The page provider below chains itself onto the last
  /// one's cursor, so nothing here has to know where the results got to.
  void grow() => state += 1;
}

/// One page of results, chained onto the page before it (BR-253).
///
/// **The chain is what makes the cursor keyset rather than an offset.** Page
/// `n` cannot be read without knowing the last row of page `n - 1`, and this is
/// where that dependency is expressed: it watches the previous page and
/// continues from its cursor. A write that changes an earlier page therefore
/// re-reads the later ones from the *new* boundary, instead of leaving them
/// describing a position that has moved.
///
/// **Request identity is the provider's own lifetime.** When the query changes,
/// this provider is rebuilt and Riverpod cancels the subscription it had — so a
/// late emission or a late error from the previous query has nowhere to arrive.
/// A hand-rolled request counter would be a second mechanism for the same thing,
/// and the two would only ever agree by inspection.
///
/// **Every dependency is read synchronously, and that is not a style choice.**
/// Written as an `async*` generator awaiting the previous page's `.future`, the
/// body runs *after* `build` returns — so a query cleared in the meantime
/// disposes this provider while its first `ref.watch` is still pending, and
/// Riverpod throws `Cannot use the Ref … after it has been disposed`. Reading
/// the previous page as an `AsyncValue` keeps the whole body synchronous: when
/// it has no value yet the stream is empty, and the arrival of that value
/// rebuilds this provider.
@Riverpod(retry: noAutomaticRetry)
Stream<LibrarySearchPage> librarySearchPage(Ref ref, int index) {
  final SearchQuery query = ref.watch(librarySearchQueryProvider);
  // BR-249: nothing typed, nothing read. The use case guards this too — this
  // one keeps the guard visible at the seam a reader looks at first.
  if (query.isEmpty) {
    return Stream<LibrarySearchPage>.value(LibrarySearchPage.empty);
  }

  final SearchLibraryUseCase search = ref.watch(searchLibraryUseCaseProvider);
  // The first page continues from nowhere, which is the use case's default.
  if (index == 0) {
    return search(query: query, pageSize: kLibrarySearchPageSize);
  }

  final LibrarySearchPage? previous = ref
      .watch(librarySearchPageProvider(index - 1))
      .value;
  // The page before this one has not arrived. There is no boundary to continue
  // from, so this one stays loading — and the value arriving rebuilds it.
  if (previous == null) return const Stream<LibrarySearchPage>.empty();
  // The previous page said there is nothing after it. Reading anyway would
  // re-run the statement to be told the same thing.
  if (previous.cursor.isExhausted) {
    return Stream<LibrarySearchPage>.value(LibrarySearchPage.empty);
  }

  return search(
    query: query,
    pageSize: kLibrarySearchPageSize,
    after: previous.cursor,
  );
}

/// Every open page, flattened into the one value the screen renders.
///
/// **The fold itself lives in `library_search_state.dart`.** Two reasons, and
/// the second is the load-bearing one: it is a pure function over a list of
/// `AsyncValue`s and is worth testing without a container — and this file is in
/// the guard's `provider_files` scope, where a mutable local at two-space
/// indent is indistinguishable from a public mutable field on a notifier. The
/// rule is right about the shape it forbids; the accumulator simply does not
/// belong in a provider body.
@riverpod
LibrarySearchState librarySearchResults(Ref ref) {
  final SearchQuery query = ref.watch(librarySearchQueryProvider);
  // Watching no page provider is what disposes them, which is what makes an
  // empty query cost nothing rather than cost a cancelled read (BR-249).
  if (query.isEmpty) return LibrarySearchState.initial;

  final int pageCount = ref.watch(librarySearchPageCountProvider);

  return foldSearchPages(
    query: query,
    pages: <AsyncValue<LibrarySearchPage>>[
      for (var index = 0; index < pageCount; index++)
        ref.watch(librarySearchPageProvider(index)),
    ],
  );
}
