import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/route_names.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_content_shell.dart';
import '../../../../shared/widgets/mx_search_field.dart';
import '../../domain/models/search_destination_model.dart';
import '../../domain/models/search_query_model.dart';
import '../controllers/library_search_controller.dart';
import '../states/library_search_state.dart';
import '../widgets/sections/library_search_body_widget.dart';

/// Global Library Search (UC-20).
///
/// **A route of its own rather than a panel inside the deck list.** The results
/// span decks *and* cards, so the surface belongs to neither feature's screen —
/// and the deck list may not import this feature's widgets any more than this
/// one may import its (AD-13). A route is the seam both sides can name: the
/// Library header pushes a name from `core/`, and nothing else is shared.
///
/// It is a **child of the Library branch**, so the bottom bar stays, Back
/// returns to the level the user came from, and switching tabs and coming back
/// finds the search still open.
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({super.key});

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  /// What is in the field, right now.
  ///
  /// **View state, and deliberately not in a provider.** The settled query is
  /// what the database is asked for and it lags by the debounce window; binding
  /// the field to it would rewrite the text under the caret 250ms after every
  /// keystroke. Which characters are on screen belongs to the screen.
  String _typed = '';

  void _onChanged(String value) {
    setState(() => _typed = value);
    ref.read(librarySearchQueryProvider.notifier).update(value);
  }

  /// Where a result leads.
  ///
  /// **The switch is here rather than behind a provider**, because navigation
  /// is the one thing a widget is allowed to do with a `BuildContext` and a
  /// provider is not — the guard's `controller_no_build_context` rule says so,
  /// and it is right: a context captured by something that outlives the frame
  /// is a use-after-dispose waiting to happen. The rows report a typed
  /// [SearchDestination] and never a route, so what a row *means* stays
  /// assertable without a route table (BR-254).
  ///
  /// Sealed and exhaustive: a third kind of destination makes the compiler
  /// name this switch as the one place that has to learn about it — which is
  /// how the card case below got wired the moment Card Detail (M99.31)
  /// reached this branch.
  void _open(SearchDestination destination) {
    switch (destination) {
      // A `card`-type deck's route forwards into its card list on arrival, so
      // one destination serves both kinds of deck (BR-63).
      // **Pushed, for the same reason the search itself is pushed (S11).**
      // `/search` is a sibling of `/decks/:deckId`, so `go` would rebuild the
      // match list and throw this screen away — Back from the result would
      // land on the deck list with the query and results gone. Push keeps the
      // search underneath: Back returns to exactly what was found.
      case DeckDestination(:final String deckId):
        unawaited(
          context.pushNamed(
            RouteNames.deckDetail,
            pathParameters: <String, String>{RoutePathParams.deckId: deckId},
          ),
        );

      // The reading surface, never the editor: a search is a read, and
      // landing in an edit form from a read is how content gets changed by
      // accident (BR-254). The route is Card Detail's (UC-19, M99.31); it
      // did not exist on the branch this feature was authored on, which is
      // why the destination is a type — the switch, not the rows, learned
      // about it.
      case CardDestination(:final String cardId, :final String deckId):
        unawaited(
          context.pushNamed(
            RouteNames.cardDetail,
            pathParameters: <String, String>{
              RoutePathParams.deckId: deckId,
              RoutePathParams.cardId: cardId,
            },
          ),
        );
    }
  }

  /// Opens one more page. `ref.read` because this is a command — and hoisted
  /// out of `build` so a reader, and the guard, can tell a deliberate command
  /// from a missed subscription.
  void _loadMore() => ref.read(librarySearchPageCountProvider.notifier).grow();

  /// Re-reads the page that failed. Invalidating it re-reads the chain below it
  /// too, because each page watches the one before it — the same `invalidate`
  /// idiom the deck list's retry uses.
  void _retry() {
    final int? index = ref.read(librarySearchResultsProvider).retryPageIndex;
    if (index == null) return;
    ref.invalidate(librarySearchPageProvider(index));
  }

  static int? _resultCount(
    LibrarySearchState state, {
    required bool isDebouncing,
  }) {
    if (isDebouncing) return null;
    if (state.phase != LibrarySearchPhase.ready) return null;
    if (state.hasMore) return null;

    return state.decks.length + state.cards.length;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(librarySearchResultsProvider);
    final settled = ref.watch(librarySearchQueryProvider);
    // The field has moved on from what the database was asked. Nothing is in
    // flight yet — that is exactly what makes this not a loading state.
    final bool isDebouncing = SearchQuery.parse(_typed) != settled;

    return MxContentShell(
      title: context.l10n.librarySearchTitle,
      // The body is one scroll view and owns its gutters.
      padding: EdgeInsets.zero,
      // Pinned under the app bar, so the input never scrolls away from the
      // results it produced.
      subheader: MxSearchField(
        value: _typed,
        onChanged: _onChanged,
        // The tap that opened this screen was the request to type.
        shouldAutofocus: true,
        hintText: context.l10n.librarySearchHint,
        clearSemanticLabel: context.l10n.librarySearchClearLabel,
        // **Only a finished, complete read gets a number** (wireframe S5). A
        // count over a paged list would be the number *listed*; a count while
        // loading is the previous query's answer wearing the current query's
        // text; and a count on the failure state is a confident `0` printed
        // under "Could not search". Each is a wrong answer stated confidently,
        // which is worse than no answer.
        resultCount: _resultCount(state, isDebouncing: isDebouncing),
      ),
      body: LibrarySearchBodyWidget(
        state: state,
        isDebouncing: isDebouncing,
        onOpen: _open,
        onLoadMore: _loadMore,
        onRetry: _retry,
      ),
    );
  }
}
