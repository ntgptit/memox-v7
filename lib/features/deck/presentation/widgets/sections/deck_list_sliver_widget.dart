import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';

import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';
import '../../../../../shared/widgets/mx_row_group.dart';
import '../../../domain/models/deck_summary_model.dart';
import '../../../domain/models/deck_reorder_placement_model.dart';
import '../../controllers/deck_write_controller.dart';
import '../items/deck_tile_widget.dart';
import '../overlays/deck_actions_widget.dart';
import '../support/deck_undo_widget.dart';
import '../../../../../shared/widgets/mx_scroll_end_inset.dart';

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
class DeckListSliverWidget extends ConsumerWidget {
  const DeckListSliverWidget({
    required this.summaries,
    required this.manualSummaries,
    required this.isManualSort,
    required this.onClearFilter,
    super.key,
  });

  final List<DeckSummary> summaries;
  final List<DeckSummary> manualSummaries;
  final bool isManualSort;
  final VoidCallback onClearFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        // The shell knows whether a floating action sits over the list and
        // answers the clearance, gesture inset included (A20.1 P2-18).
        mxScrollEndInsetOf(context),
      ),
      // **One card, rows on it, a hairline between each pair** — the handoff's
      // ListRow grouping (owner decision 7, M100.91). Each deck used to be its
      // own card `lg` apart; as rows on one surface there is no gap to space,
      // and the card clips the first and last row's ink to its corners.
      //
      // ponytail: builds every row eagerly — a level holds tens of decks, not
      // thousands. Move to a DecoratedSliver-backed list if a level ever
      // measures slow.
      sliver: SliverToBoxAdapter(
        child: MxCard.raised(
          padding: MxCardPadding.none,
          child: MxRowGroup(
            children: <Widget>[
              for (final summary in summaries) _tileFor(context, ref, summary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tileFor(BuildContext context, WidgetRef ref, DeckSummary summary) {
    final manualIndex = manualSummaries.indexWhere(
      (DeckSummary candidate) => candidate.deck.id == summary.deck.id,
    );
    final earlier = manualIndex > 0 ? manualSummaries[manualIndex - 1] : null;
    final later = manualIndex >= 0 && manualIndex < manualSummaries.length - 1
        ? manualSummaries[manualIndex + 1]
        : null;

    return DeckTileWidget(
      summary: summary,
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
        // Reset belongs to a root (BR-05), so it is offered from the
        // list where a root is a row and nowhere else (UC-07).
        //
        // **The answer state, not the learned count.** This read
        // `learnedCardCount > 0` — box 8, or a 128-day interval (BR-88)
        // — and treated it as having been studied. A deck answered up to
        // box 3 has zero learned cards and a full schedule, and it got an
        // ordinary-looking row and a confirmation promising nothing to
        // lose, for the operation that throws that schedule away.
        // `firstAnsweredAt` is the column the reset itself clears
        // (BR-44), which is what makes it the one describing the risk.
        hasStudyProgress: summary.deck.firstAnsweredAt != null,
        // Deleting from a list leaves the user on that list; there is
        // nowhere to navigate back from — so the only thing left to do
        // is say where the deck went and offer it back (BR-256, BR-263).
        onDeleted: (batchId) =>
            showDeckMovedToTrash(context, ref, batchId: batchId),
        onMoveEarlier: isManualSort && earlier != null
            ? () => ref
                  .read(reorderDeckControllerProvider(summary.deck.id).notifier)
                  .submit(
                    targetSiblingDeckId: earlier.deck.id,
                    placement: DeckReorderPlacement.before,
                  )
            : null,
        onMoveLater: isManualSort && later != null
            ? () => ref
                  .read(reorderDeckControllerProvider(summary.deck.id).notifier)
                  .submit(
                    targetSiblingDeckId: later.deck.id,
                    placement: DeckReorderPlacement.after,
                  )
            : null,
      ),
    );
  }
}
