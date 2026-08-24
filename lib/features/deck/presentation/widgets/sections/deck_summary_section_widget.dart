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
      // `sm` above (owner review, 2026-08-20): the path is inside the bar now,
      // and the bar's own hairline is the separation between chrome and body,
      // so `md` on top of that break measured about 40px of dead space above
      // the panel on device. `sm` is the floor `deck_list_spacing_test.dart`
      // holds for "visibly separate" and this sits on it.
      //
      // **Nothing below** (owner review, 2026-08-25). The list heading under
      // this owns the gap before the first card and always did; the panel's own
      // bottom inset was a second opinion about the same seam, and the two
      // stacked into dead space that cost most of a deck card.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
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
