import 'package:flutter/material.dart';

import '../../../../../core/theme/app_elevation.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_card.dart';
import '../../../../../shared/widgets/mx_icon_button.dart';
import '../../../../../shared/widgets/mx_progress_bar.dart';
import '../../../domain/models/deck_content_type_model.dart';
import '../../../domain/models/deck_summary_model.dart';
import 'deck_due_state_widget.dart';
import 'deck_icon_area_widget.dart';
import 'deck_study_button_widget.dart';
import '../support/deck_labels_widget.dart';

/// One deck in a deck list, at any level (UC-06 step 2).
///
/// There used to be a second tile for sub-decks, showing only a name — because
/// the detail screen's query did not load counts for them. The recursive
/// aggregate landed and the reason evaporated: a sub-deck now carries the same
/// facts a root does, so it gets the same row.
///
/// A feature widget, not a shared one: it knows [DeckSummary], and a shared
/// tile that knew a domain type would drag the deck domain into every widget test
/// in the project. It is built **on** `MxCard`, so the surface colour, the corner
/// radius, the border and the ripple still come from one place.
///
/// **It stopped being an `MxListTile` at M4.12.** A `ListTile` puts everything on
/// one baseline at a fixed height, which reads as a row in a table — every deck
/// the same weight, nothing to scan for. The card gives the name its own line,
/// the counts a quieter one under it, and the state its own colour, so a list of
/// twenty decks can be read by shape rather than by reading each row.
///
/// The due state is carried by an icon, by words **and** by colour, never by
/// colour alone (UC-06 step 3). "Nothing due" is `success` rather than neutral:
/// finishing your reviews is good news, and BR-29 forbids dressing it as a
/// problem — but it is still a state worth seeing at a glance.
class DeckTileWidget extends StatelessWidget {
  const DeckTileWidget({
    required this.summary,
    required this.onTap,
    required this.onActions,
    super.key,
  });

  final DeckSummary summary;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    // **Flat, and padded by its bands rather than as a whole.** The design's
    // deck card carries a hairline and no shadow -- two competing depths in one
    // scrolling column is what makes a list read as busy, and the card no longer
    // needs a shadow to separate from the page now that it has three bands of
    // its own. The padding moves inside so the card's ink covers the whole of
    // what it opens, edge to edge.
    //
    // **The whole card opens the deck.** Only the top band used to, and the two
    // bands under it -- the progress bar, the due chip -- then looked tappable
    // and were not. `MxCard` takes the tap; the overflow menu is a nested button
    // and wins the gesture arena over it, so it stays its own action.
    return MxCard(
      elevation: AppElevation.none,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DeckHeadRegion(summary: summary, onActions: onActions),
          _DeckStateRegion(summary: summary),
        ],
      ),
    );
  }
}

/// The card's first band: the well, the name, the counts, and the row's menu.
///
/// **Layout only — the tap belongs to the card.** This was its own `InkWell` for
/// one release, which made the hover and the ripple cover the top third of a card
/// whose other bands opened the same deck and showed nothing.
///
/// **The menu moved up here from a band of its own.** A 48-tall row holding one
/// icon button cost the card 48 pixels to say nothing; this band is already at
/// least that tall because the button sets its floor, so the row came for free.
/// That is most of what took the card from 168 to about 110 — on a 393x852 screen
/// the difference is 2.3 visible decks against 3.5.
class _DeckHeadRegion extends StatelessWidget {
  const _DeckHeadRegion({required this.summary, required this.onActions});

  final DeckSummary summary;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    // A deck fixed to cards holds no sub-decks (BR-63), so it is the one row
    // that opens onto something other than a list -- and the one that gets the
    // card glyph rather than the folder. A completed deck outranks both: at
    // 100% learned, what the row is *made of* matters less than that it is done.
    //
    // **The chevron that used to sit beside the menu is gone.** It said "this
    // opens onto another level", which the whole card now says by being the
    // target; standing next to a real control it read as a second one that did
    // nothing. What the row is made of is still carried, by this glyph and by
    // the sub-deck count on the meta line.
    final isComplete = summary.isFullyLearned;
    final holdsCards = summary.deck.contentType == DeckContentType.card;

    return Padding(
      // **`xs` on the right, and the arithmetic is the point.** The overflow
      // button is a 48 box around a 24 glyph, so it carries 12 of its own inset;
      // `sm` here made the optical right gutter 20 against the left's 16, which
      // is visible as a card whose contents sit slightly left of centre. 4 + 12
      // is the 16 every other element on the screen starts from.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        // Top, not centre. Once the name wraps -- a long deck title, or any
        // title at `textScaler` 2.0 -- a centred glyph floats halfway down the
        // card with nothing beside it, and the row stops reading left to right.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DeckIconArea(
            icon: isComplete
                ? Icons.check_circle
                : holdsCards
                ? Icons.style_outlined
                : Icons.folder_outlined,
            // Semantics only on the state-carrying glyph. Folder and card are
            // decoration -- the meta line under them says the same thing in
            // words -- and announcing "folder" on every row is noise a
            // screen-reader user has to sit through.
            semanticLabel: isComplete
                ? context.l10n.deckFullyLearnedSemanticLabel
                : null,
            tint: isComplete
                ? context.semanticColors.success
                : context.colors.onPrimaryContainer,
            // A finished deck steps off the brand container onto the neutral
            // one. The design does the same, and the reason shows in a list:
            // every well is indigo, so a green tick inside an indigo square
            // still reads as "one of the indigo ones" until you look at it. On
            // the muted surface it reads as done from across the column.
            wellColor: isComplete ? context.semanticColors.surfaceMuted : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  summary.deck.name,
                  style: context.texts.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                _DeckMetaLine(summary: summary),
              ],
            ),
          ),
          MxIconButton(
            icon: Icons.more_vert,
            semanticLabel: context.l10n.deckActionsSemanticLabel,
            onPressed: onActions,
          ),
        ],
      ),
    );
  }
}

/// The height a progress track occupies, reserved on decks that have none.
///
/// **Read from the component, not copied.** It was a literal 4, and the moment
/// `MxProgressBarSize.sm` went to 6 the decks with no cards were two pixels
/// shorter than the rest — a rhythm that had been fixed on purpose, broken by a
/// number that had stopped being the same number.

/// The card's lower bands: what you can do about the deck, then how far through
/// it is.
///
/// **The verbs get a row of their own.** The kit's card ends in a foot holding
/// the due state, a Study pill and the row menu; folding the bar and the chip
/// onto one line left the second verb nowhere to go. The menu moved up to sit
/// with the deck's identity, so this row carries only what a user *does*.
///
/// **The track sits on the card's bottom edge, not between the counts and the
/// verbs.** In the middle it cut the card in two; on the edge it is a base the
/// card stands on. It is the one element that ignores the side padding, and it
/// is drawn `flush` so the card's corner is the only rounding.
class _DeckStateRegion extends StatelessWidget {
  const _DeckStateRegion({required this.summary});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          // `lg` under the row: the track below it is 4px of colour on the very
          // edge, so it adds no breathing room of its own the way a margin
          // would.
          // **`sm` below, against `lg` above the card's first row — and that is
          // what makes them look equal.** The row is the 48 touch-target floor
          // but the Study pill paints 32, so it already sits 8 clear of the row's
          // bottom edge; `lg` here put 24 of visible space under it against 16
          // over the well at the top. 8 + 8 is the 16 the top has. The chip and
          // the figure are shorter than the pill and end up with a little more,
          // which is what a small mark needs to sit level with a filled one.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          // **Fixed to the touch-target floor.** The Study pill paints 32 but its
          // hit area is 48, so a card with something due grew 24px taller than
          // one without and the column stepped. The row is the floor's height on
          // every card, whatever is standing in it.
          child: SizedBox(
            height: AppSpacing.minimumTouchTarget,
            child: Row(
              children: <Widget>[
                Expanded(child: DeckDueStateWidget(summary: summary)),
                // **The slot Study will take, and what stands in it until then.**
                // A deck with nothing waiting has no verb to offer and the row
                // read as a card missing a piece; the figure is what is true
                // instead. Not a *disabled* Study button — BR-29 makes "nothing
                // due" good news, and a greyed control says you cannot do the
                // thing when the truth is there is nothing to do.
                if (summary.hasDueCards)
                  DeckStudyButtonWidget(
                    deckId: summary.deck.id,
                    dueCardCount: summary.dueCardCount,
                  )
                else if (summary.totalCardCount > 0)
                  Text(
                    context.l10n.deckLearnedPercentLabel(
                      (summary.learnedFraction * 100).round(),
                    ),
                    style: context.texts.labelMedium?.copyWith(
                      color: summary.isFullyLearned
                          ? context.semanticColors.success
                          : context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
        ),
        // A deck with no cards has no progress to draw — an empty track would be
        // a measurement of nothing — but it still reserves the height, so a list
        // mixing filled and empty decks keeps one rhythm. Reserving space claims
        // nothing; drawing a 0% track would.
        if (summary.totalCardCount == 0)
          // Not `const`: an enum field is not a constant expression, and reading
          // the real height beats a literal that can fall out of step.
          SizedBox(height: MxProgressBarSize.sm.trackHeight)
        else
          // No clip here: `MxCard` clips its own content, and a `ClipRRect`
          // around the bar would clamp the card's 16 radius down to the bar's
          // own height and cut the wrong shape — the bug this replaced.
          Semantics(
            label: context.l10n.deckLearnedProgressLabel(
              summary.learnedCardCount,
              summary.totalCardCount,
            ),
            value: context.l10n.deckLearnedPercentLabel(
              (summary.learnedFraction * 100).round(),
            ),
            child: MxProgressBar(
              size: MxProgressBarSize.sm,
              shape: MxProgressBarShape.flush,
              value: summary.learnedFraction,
            ),
          ),
      ],
    );
  }
}

/// Card total and due state on one line, with only the state in colour.
///
/// `Text.rich` rather than a `Row` of chips: the whole line has to wrap and
/// ellipsise as one piece of text at `textScaler` 2.0 on a 320-wide screen. A row
/// of chips would either overflow or push the trailing action off the card, which
/// is the failure M4.8b already paid for once.
///
/// **The scheduler came back into this line at M4.10e, and the card went from
/// three lines to two.** It was moved out at M4.12 because
/// `46 cards · 5 cards due · Eight boxes` wrapped on every card at 390 wide. The
/// fix then was a third line; the fix now is shorter copy — `46 cards · 5 due ·
/// 8 boxes` fits, so the line that was added to solve a wrap is gone and the card
/// has one title and one summary instead of three competing rows.
///
/// **Only the due state carries colour, and only when it is due.** "Nothing due"
/// was `success` green at `w600`, which put the loudest thing on the card on the
/// one fact that asks for no action — a list of finished decks read as a list of
/// alerts. It is now the same quiet grey as the counts beside it. Colour and
/// weight are spent on the state that wants a tap, and nowhere else.
///
/// This does not weaken the "never colour alone" rule (UC-06 step 3): the due
/// state is still carried by an icon, by words *and* by colour. What changed is
/// that the *absence* of that state stopped being decorated.
class _DeckMetaLine extends StatelessWidget {
  const _DeckMetaLine({required this.summary});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final quiet = context.texts.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );

    return Text.rich(
      TextSpan(
        style: quiet,
        children: <InlineSpan>[
          // Only when there are any. A row that reads "0 sub-decks · 12 cards"
          // spends its first fact saying nothing happened.
          if (summary.subDeckCount > 0) ...<InlineSpan>[
            TextSpan(
              text: context.l10n.deckSubDeckCountLabel(summary.subDeckCount),
            ),
            const TextSpan(text: ' · '),
          ],
          TextSpan(
            text: context.l10n.deckCardCountLabel(summary.totalCardCount),
          ),
          // **The due count left this line at M4.10s.** It now has its own chip
          // in the card's foot, where it can be a filled pill rather than a
          // coloured run of text inside a quiet sentence. Keeping it here as
          // well would state the same fact twice on one card.
          const TextSpan(text: ' · '),
          TextSpan(
            // `summary.schedulerType`, not `summary.deck.schedulerType`. Only a
            // root carries the column (BR-06), so the entity's own field is null
            // on every deck below the first level — the query resolves it through
            // `root_deck_id` and the summary carries the answer.
            text: context.schedulerShortLabel(summary.schedulerType),
          ),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
