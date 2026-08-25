import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../controllers/deck_list_view_controller.dart';
import '../../states/deck_list_view_state.dart';
import 'deck_level_summary_widget.dart';

/// Toggling the panel's disclosure, bound to a `ref`.
///
/// A free function rather than a closure written inline in `build()`. `ref.read`
/// is the right call — opening or shutting is a command, and a `watch` inside a
/// callback would subscribe the widget to a value it is about to set — but
/// written inline it sits lexically inside `build`, where neither a reader nor
/// `memox.state_management.no_ref_read_in_build` can tell a deliberate command
/// from a missed subscription.
VoidCallback _toggleSummaryDetail(WidgetRef ref) =>
    () => ref.read(deckSummaryDetailChoiceProvider.notifier).toggle();

/// The level summary, or nothing.
///
/// **The panel or nothing, since the compaction** (owner decision, 2026-08-25).
/// It used to be dismissible, and a one-line link stood in for it so that
/// hiding it was a preference rather than a loss. Both are gone: at 18% of the
/// viewport the panel is not in the way of the list, so there is nothing to
/// hide from, and the chevron it carried now opens the resting figures instead.
/// What is left is the rule the old `auto` default already followed — a level
/// with work waiting gets the panel, a level without gets the list.
class DeckSummarySectionWidget extends ConsumerWidget {
  const DeckSummarySectionWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A level with nothing in it has an empty state that says more than a
    // summary of nothing would.
    if (!DeckLevelSummaryWidget.hasContent(snapshot)) {
      return const SizedBox.shrink();
    }

    // A panel whose whole content is "nothing is waiting" is a panel that opens
    // to say no action is needed. The deck cards below carry their own progress
    // bars, so a caught-up level loses no figure by not printing this one.
    if (!DeckLevelSummaryWidget.hasStudyable(snapshot)) {
      return const SizedBox.shrink();
    }

    final isExpanded =
        ref.watch(deckSummaryDetailChoiceProvider) ==
        DeckSummaryDetail.expanded;

    return Padding(
      // **Nothing above, and the bar already carries the break** (owner review,
      // 2026-08-25, vertical-rhythm pass). It was `sm`, on top of the 8.5 the
      // app bar keeps below the subheader — 16.5 in total, where the design
      // asks for 16. Swapping the heading row's gaps cost 8px of the list's
      // headroom, and this is where the owner said to find them.
      //
      // `deck_list_spacing_test.dart` still holds: it asks for `sm` between the
      // header strip and this card, and the bar's own centring clears it —
      // exactly, at 8, since `_toolbarHeight` was made to reserve what it
      // renders. It used to clear by half a pixel, on five pixels of slack the
      // bar had reserved for a line height it does not use. The separation
      // rests on that arithmetic either way, so a change there breaks the
      // guard rather than merely moving a gap. Putting `sm` back is one token
      // if the trade sours.
      //
      // **`xl` below, and the reason is grouping rather than taste** (owner
      // review, 2026-08-25, vertical-rhythm pass). It was 0, which put the list
      // heading against the hero's own edge while leaving 24 between that
      // heading and the first card it names. By proximity the reader groups
      // `YOUR DECKS` with the panel above it instead of the list below — the
      // label was closer to the thing it does not describe.
      //
      // **`md`, walked down from `xl` in two owner reviews.** The swap first
      // put the whole `xl` here, then `lg`, and both read as too much air
      // under the hero. `md` is where it settled: 12 above the heading against
      // `sm` below it. The grouping this was for needs only that the break be
      // *bigger* than the tie — 12 against 8 still reads the label as the
      // list's, and every step down gives the list back its pixels.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: DeckLevelSummaryWidget(
        snapshot: snapshot,
        isExpanded: isExpanded,
        onToggleExpanded: _toggleSummaryDetail(ref),
        onStudyDue: snapshot.levelDueCardCount == 0
            ? null
            : () => snapshot.parent == null
                  // The Study tab lists every root's workload; one
                  // session cannot span roots (BR-101).
                  ? context.goNamed(RouteNames.study)
                  : context.goNamed(
                      RouteNames.deckStudy,
                      pathParameters: <String, String>{
                        RoutePathParams.deckId: snapshot.parent!.id,
                      },
                    ),
      ),
    );
  }
}
