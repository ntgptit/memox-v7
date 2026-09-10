import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import 'deck_level_summary_widget.dart';

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
      // **`sm`, the bottom of the walk.** This went `xl` → `lg` → `md` → `sm`
      // across four reviews, each one saying the break under the hero was
      // still too much air, and each step handing the pixels to the list.
      //
      // What holds it at `sm` rather than 0 is the label below it. Measured on
      // ink, the cap sits 28.09 under the hero and the baseline 19.19 over the
      // first card, so the label is nearer its own list by 8.9 — one spacing
      // step, the least this design system asks anyone to see as a difference.
      // At 0 it would be 20.09 against 19.19 and the label would belong to
      // neither side, which is the "floating" an image review named.
      //
      // The row's 48px height is `MxTextButton`'s touch target, and it is why
      // both figures dwarf the tokens: the `Row` centres a 16px label box in
      // 48, so 16 of each is air no token here can see or spend.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: DeckLevelSummaryWidget(
        snapshot: snapshot,
        // **Inside a deck only.** At the root this button used to read
        // "Choose a deck to study" and hand the tap to the Study tab — a
        // session belongs to one root (BR-101), so there was no session to
        // start and the comment on the label admitted as much: it "promised a
        // session and delivered an index". A filled hero pointing at the
        // outlined verbs below it inverted the screen's hierarchy, and the
        // Study tab is already one tap away in the bottom bar. Inside a deck
        // the same control does start that deck's session, so it stays there.
        onStudyDue: snapshot.levelDueCardCount == 0 || snapshot.parent == null
            ? null
            : () => context.goNamed(
                RouteNames.deckStudy,
                pathParameters: <String, String>{
                  RoutePathParams.deckId: snapshot.parent!.id,
                },
              ),
      ),
    );
  }
}
