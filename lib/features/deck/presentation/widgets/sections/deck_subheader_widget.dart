import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_list_snapshot_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_level_summary_widget.dart';
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // **A dot that means something, not a decoration** (owner brief,
              // 2026-09-10). The reference draws one before this line
              // unconditionally; a mark that is always there says nothing, so
              // it is spent on the one fact this line does not carry — whether
              // any of those cards is waiting.
              //
              // The same fold the panel below uses to decide whether it
              // appears at all, called through its own static rather than
              // recomputed here: two counts deciding one thing is how a header
              // and the panel under it come to disagree about the same
              // instant.
              if (DeckLevelSummaryWidget.hasStudyable(snapshot)) ...<Widget>[
                _ReadyDot(),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
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
            ],
          ),
        ),
      );
    }

    return DeckPathWidget(snapshot: snapshot);
  }
}

/// "Something here is ready to study", as one mark.
///
/// **Announced, not merely drawn.** A coloured dot is invisible to a screen
/// reader and to anyone who cannot separate this green from this grey, so the
/// sentence rides on the node rather than on the colour. The line beside it
/// counts decks and cards and never says this.
class _ReadyDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      // **`container: true`, and without it there is no node at all.** A
      // `Semantics` widget with only a label annotates its child's node; the
      // child here is a painted circle with no semantics of its own, so there
      // was nothing to annotate and the sentence reached nobody. It looked
      // right in the widget tree and was silent in the semantics tree — the
      // exact shape of bug `deck_header_chrome_test.dart` was written to
      // catch, and it caught this one on the first run.
      container: true,
      label: context.l10n.deckHeaderReadySemanticLabel,
      // **8, off the spacing scale rather than out of a new token.** A
      // dimension token is `v1-freeze.md` §2 line 5, and one dot does not
      // justify reopening a frozen foundation for the third time in a day.
      // 8 is on the 4px grid and is the reference's own `w-2`.
      child: Container(
        width: AppSpacing.sm,
        height: AppSpacing.sm,
        decoration: BoxDecoration(
          color: context.semanticColors.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
