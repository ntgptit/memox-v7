import 'package:flutter/material.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_content_shell.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_error_state.dart';
import '../../../../../shared/widgets/mx_loading_state.dart';
import '../../../domain/models/search_destination_model.dart';
import '../../../domain/models/search_result_model.dart';
import '../../states/library_search_state.dart';
import '../items/card_result_tile_widget.dart';
import '../items/deck_result_tile_widget.dart';
import 'search_group_header_widget.dart';
import 'search_page_footer_widget.dart';
import '../../../../../shared/widgets/mx_scroll_end_inset.dart';

/// Breathing room under the last row.
///
/// **Not clearance for the bottom bar** — a `Scaffold` with a
/// `bottomNavigationBar` takes that height out of its body's `MediaQuery`, so
/// the shell has already reserved it. This is the gap that stops the last row
/// sitting on the bar's hairline — `lg`, the same value every other
/// scrollable list uses for the same reason (D21).

/// Every state the search surface can be in, in one place.
///
/// **The results are never blanked while a new query is being typed.** The
/// previous answer is the closest thing to the new one until the new one exists,
/// and a list that flashes away and back on every keystroke is unreadable. Only
/// a *failed* first page clears the list, because results left under "could not
/// search" would claim to answer the query in the field.
class LibrarySearchBodyWidget extends StatelessWidget {
  const LibrarySearchBodyWidget({
    required this.state,
    required this.isDebouncing,
    required this.onOpen,
    required this.onLoadMore,
    required this.onRetry,
    super.key,
  });

  final LibrarySearchState state;

  /// The field holds text the settled query has not caught up with. Nothing has
  /// been asked of the database yet — which is why this is not
  /// [LibrarySearchPhase.loading].
  final bool isDebouncing;

  final ValueChanged<SearchDestination> onOpen;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (state.phase == LibrarySearchPhase.failed) {
      return MxErrorState(
        title: context.l10n.librarySearchErrorTitle,
        // The failure itself never reaches the screen: a Drift message would
        // tell the user nothing they can act on, and can carry card content.
        message: context.l10n.librarySearchErrorMessage,
        retryLabel: context.l10n.retryAction,
        onRetry: onRetry,
      );
    }

    if (!state.hasResults) return _empty(context);

    return _results(context);
  }

  /// The three states that show no rows, told apart because the next move
  /// differs in each.
  Widget _empty(BuildContext context) {
    final bool isWaiting =
        isDebouncing || state.phase == LibrarySearchPhase.loading;
    if (isWaiting) {
      return MxLoadingState(
        semanticsLabel: context.l10n.librarySearchLoadingLabel,
      );
    }

    if (state.phase == LibrarySearchPhase.initial) {
      return MxEmptyState(
        icon: Icons.search,
        title: context.l10n.librarySearchInitialTitle,
        message: context.l10n.librarySearchInitialMessage,
      );
    }

    return MxEmptyState(
      icon: Icons.search_off,
      title: context.l10n.librarySearchNoResultsTitle(state.query.raw),
      message: context.l10n.librarySearchNoResultsMessage,
    );
  }

  Widget _results(BuildContext context) {
    // **The gutter comes from the shell, not from a literal.** The field lives
    // in the shell's subheader, which takes `mxScreenGutter` — `md` below the
    // compact breakpoint and `lg` above it. Three hardcoded `AppSpacing.lg`
    // here made the rows sit 4dp inside the field at 320dp and match it at 390,
    // which is exactly the drift W5/G1 exists to catch and exactly the mistake
    // `deck_path_widget.dart` records having made once already.
    final double gutter = mxScreenGutter(context);

    return CustomScrollView(
      slivers: <Widget>[
        if (state.decks.isNotEmpty)
          ..._group(
            gutter: gutter,
            group: SearchResultGroup.decks,
            children: <Widget>[
              for (final DeckSearchHit hit in state.decks)
                DeckResultTileWidget(
                  key: ValueKey<String>('deck-${hit.deckId}'),
                  hit: hit,
                  onOpen: () => onOpen(SearchDestination.of(hit)),
                ),
            ],
          ),
        if (state.cards.isNotEmpty)
          ..._group(
            gutter: gutter,
            group: SearchResultGroup.cards,
            children: <Widget>[
              for (final CardSearchHit hit in state.cards)
                CardResultTileWidget(
                  key: ValueKey<String>('card-${hit.cardId}'),
                  hit: hit,
                  onOpen: () => onOpen(SearchDestination.of(hit)),
                ),
            ],
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            gutter,
            AppSpacing.sm,
            gutter,
            mxScrollEndInsetOf(context),
          ),
          sliver: SliverToBoxAdapter(
            child: SearchPageFooterWidget(
              state: state,
              onLoadMore: onLoadMore,
              onRetry: onRetry,
            ),
          ),
        ),
      ],
    );
  }

  /// One section: its header, then its rows, all on the screen gutter.
  List<Widget> _group({
    required double gutter,
    required SearchResultGroup group,
    required List<Widget> children,
  }) => <Widget>[
    SliverPadding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        AppSpacing.lg,
        gutter,
        AppSpacing.sm,
      ),
      sliver: SliverToBoxAdapter(child: SearchGroupHeaderWidget(group: group)),
    ),
    SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      sliver: SliverList.separated(
        itemCount: children.length,
        itemBuilder: (BuildContext context, int index) => children[index],
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(height: AppSpacing.sm),
      ),
    ),
  ];
}
