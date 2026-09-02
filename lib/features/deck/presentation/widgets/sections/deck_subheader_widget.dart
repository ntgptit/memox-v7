import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_path_widget.dart';

/// The header's second line: where you are, or what is here.
///
/// Both are chrome and both stay put while the list scrolls, which is what the
/// shell's subheader slot is for.
///
/// **Search opens a surface of its own now, and the scope changed with it
/// (M99.32).** The field used to expand into this strip and searched the
/// subtree the user was standing in — deck names only, because that is all the
/// deck feature can see. Global Library Search covers deck names, card fronts,
/// card backs and tag names in one ranked list, which is a surface neither this
/// feature nor the card feature can own: `features/deck/presentation/` may not
/// import another feature's widgets (AD-13). So the affordance navigates by
/// name, and the search screen holds the input.
///
/// What that costs is the in-place field, and with it the subtree scoping —
/// deliberately, because a result row now carries its full deck path, which
/// answers "where did I put it" better than a scoped list of bare names did.
class DeckSubheaderWidget extends StatelessWidget {
  const DeckSubheaderWidget({required this.snapshot, super.key});

  final DeckListSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    // **At the root the line states the level, not the place** (owner review,
    // 2026-08-21). "Library" over "All decks" was one thing said twice, and
    // the second line is the header's scarcest space. Inside a deck the path
    // earns it back: there the title names the deck and the line names the
    // way out.
    if (snapshot.parent == null) {
      return SizedBox(
        height: MxBreadcrumb.compactLineHeight,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            context.l10n.deckHeaderStatsLabel(
              snapshot.decks.length,
              snapshot.decks.fold<int>(
                0,
                (int sum, DeckSummary deck) => sum + deck.totalCardCount,
              ),
            ),
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return DeckPathWidget(snapshot: snapshot);
  }
}
