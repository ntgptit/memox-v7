import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../domain/models/deck_summary_model.dart';
import '../items/deck_tile_widget.dart';
import '../overlays/deck_actions_widget.dart';

/// Space under the last card. It was 112 while a floating action hovered.
const double _kListBottomInset = AppSpacing.lg;

/// The rows of one deck level, as a sliver.
///
/// Split out of `deck_list_screen.dart` at the file-size guard, along the seam
/// the screen already had: everything above it is chrome the level composes —
/// summary panel, toolbar — and this is the list they are about.
/// The visible decks, or the note that the filter matched none of them.
///
/// Empty here means exactly one thing: this level has decks, and the due-only
/// filter matched none of them. The "nothing here at all" cases never reach this
/// widget — `_DeckLevel` answers them before the toolbar is even built, because
/// they need different words and different actions.
class DeckListSliverWidget extends StatelessWidget {
  const DeckListSliverWidget({
    required this.shouldShowScheduler,
    required this.summaries,
    required this.onClearFilter,
    super.key,
  });

  /// Forwarded to every tile — see [DeckTileWidget.shouldShowScheduler].
  final bool shouldShowScheduler;

  final List<DeckSummary> summaries;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      // `hasScrollBody: false` so the state is sized to its content and centred
      // in what is left, rather than stretched down a viewport it does not fill.
      return SliverFillRemaining(
        hasScrollBody: false,
        child: MxEmptyState(
          // `MxEmptyState`'s default check-mark, left unset on purpose: nothing
          // due means the reviews are finished, which is the one state in this
          // feature where that icon tells the truth.
          title: context.l10n.decksNoDueTitle,
          message: context.l10n.decksNoDueMessage,
          actionLabel: context.l10n.decksShowAllAction,
          onAction: onClearFilter,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        _kListBottomInset,
      ),
      sliver: SliverList.separated(
        itemCount: summaries.length,
        // `lg`: the track on each card's base makes that boundary loud, so 12
        // after it read as part of the card rather than as the space between.
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          final summary = summaries[index];

          return DeckTileWidget(
            summary: summary,
            shouldShowScheduler: shouldShowScheduler,
            // By name, with the id as a path parameter. The literal path would
            // work today and break silently the first time the route moves.
            //
            // `push`, not `go`: `go` replaces the one `/decks/:deckId` entry,
            // so Back from level 5 landed on the root list. The breadcrumb
            // keeps `go` — a jump *should* replace the stack (IT-NAV-003/004).
            onTap: () => context.pushNamed(
              RouteNames.deckDetail,
              pathParameters: <String, String>{
                RoutePathParams.deckId: summary.deck.id,
              },
            ),
            onActions: () => showDeckActions(
              context,
              deck: summary.deck,
              // Whether a deck may be reset is a question about its own
              // children, answered on its own level where they are known.
              // Offering it from the level above would mean guessing.
              mayOfferReset: false,
              // The one place that knows the learned total, so the one place
              // Reset learning progress is offered from (UC-07).
              hasLearnedCards: summary.learnedCardCount > 0,
              // Deleting from a list leaves the user on that list; there is
              // nowhere to navigate back from.
              onDeleted: () {},
            ),
          );
        },
      ),
    );
  }
}
