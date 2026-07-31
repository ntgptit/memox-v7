import 'package:flutter/material.dart';

import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_elevation.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_card.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../../../shared/widgets/mx_progress_bar.dart';
import '../../domain/models/deck_content_type_model.dart';
import '../../domain/models/deck_summary_model.dart';
import 'deck_due_state_widget.dart';
import 'deck_labels_widget.dart';

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
    // **Flat, and padded by its regions rather than as a whole.** The design's
    // `.mx-deck` carries a hairline and no shadow -- two competing depths in one
    // scrolling column is what makes a list read as busy, and the card no longer
    // needs a shadow to separate from the page now that it has three bands of
    // its own. The padding moves inside so the open region's ink covers the
    // whole of what it opens, edge to edge.
    return MxCard(
      elevation: AppElevation.none,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DeckOpenRegion(summary: summary, onTap: onTap),
          if (summary.totalCardCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: MxProgressBar(
                size: MxProgressBarSize.sm,
                value: summary.learnedFraction,
                label: context.l10n.deckLearnedProgressLabel(
                  summary.learnedCardCount,
                  summary.totalCardCount,
                ),
                valueLabel: context.l10n.deckLearnedPercentLabel(
                  (summary.learnedFraction * 100).round(),
                ),
              ),
            ),
          _DeckFootRegion(summary: summary, onActions: onActions),
        ],
      ),
    );
  }
}

/// The part of the card that opens the deck: the well, the name, the counts.
///
/// **Its own target, not the whole card.** The card used to be one button with
/// the overflow menu nested inside it, which works but makes the menu a hole in
/// the middle of a large target and gives the ripple no relationship to what it
/// opens. Splitting it is the design's arrangement and it is also what leaves
/// room for a study action here later, when there is a session to start.
class _DeckOpenRegion extends StatelessWidget {
  const _DeckOpenRegion({required this.summary, required this.onTap});

  final DeckSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A deck fixed to cards holds no sub-decks (BR-63), so it is the one row
    // that opens onto something other than a list -- and the one that gets the
    // card glyph rather than the folder. A completed deck outranks both: at
    // 100% learned, what the row is *made of* matters less than that it is done.
    final isComplete = summary.isFullyLearned;
    final holdsCards = summary.deck.contentType == DeckContentType.card;

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          // Only the top corners: the region is the top band of the card, and a
          // ripple rounded on all four would leave two notches mid-card.
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              // Top, not centre. Once the name wraps -- a long deck title, or
              // any title at `textScaler` 2.0 -- a centred glyph floats halfway
              // down the card with nothing beside it, and the row stops reading
              // left to right.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DeckIconArea(
                  icon: isComplete
                      ? Icons.check_circle
                      : holdsCards
                      ? Icons.style_outlined
                      : Icons.folder_outlined,
                  // Semantics only on the state-carrying glyph. Folder and card
                  // are decoration -- the meta line under them says the same
                  // thing in words -- and announcing "folder" on every row is
                  // noise a screen-reader user has to sit through.
                  semanticLabel: isComplete
                      ? context.l10n.deckFullyLearnedSemanticLabel
                      : null,
                  tint: isComplete
                      ? context.semanticColors.success
                      : context.colors.onPrimaryContainer,
                  // A finished deck steps off the brand container onto the
                  // neutral one. The design does the same, and the reason shows
                  // in a list: every well is indigo, so a green tick inside an
                  // indigo square still reads as "one of the indigo ones" until
                  // you look at it. On the muted surface it reads as done from
                  // across the column.
                  wellColor: isComplete
                      ? context.semanticColors.surfaceMuted
                      : null,
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
                // Only where it opens onto another level. On a deck fixed to
                // cards it would promise a list that BR-63 says cannot exist.
                if (!holdsCards) ...<Widget>[
                  const SizedBox(width: AppSpacing.sm),
                  ExcludeSemantics(
                    child: Icon(
                      Icons.chevron_right,
                      size: AppIconSize.sm,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The bottom band: what is waiting, and the row's menu.
class _DeckFootRegion extends StatelessWidget {
  const _DeckFootRegion({required this.summary, required this.onActions});

  final DeckSummary summary;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: DeckDueStateWidget(summary: summary)),
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

/// The card's leading glyph, in a tinted well.
///
/// Feature-local rather than shared: it exists to give the deck list a scannable
/// left column, and nothing else in the app has asked for one. Promoting it on the
/// first caller would be guessing at what varies — the second caller is what shows
/// whether the tint, the size or the shape is the part worth parameterising.
///
/// Sized to [AppSpacing.minimumTouchTarget] even though it is not a target: it is
/// the one square in the row, and reusing the number the row's real controls use
/// keeps the icon, the title and the action optically aligned.
///
/// **The well is `primaryContainer` and the default glyph is
/// `onPrimaryContainer`** — a Material 3 container pair, chosen because the pair
/// is what carries a contrast guarantee. The first version used `surfaceMuted`
/// with a `primary` glyph, which looked right in light and failed the strict
/// audit in dark at **2.31:1** against a 3.0 floor: `primary` is a fill colour,
/// and nothing promises it is legible *on* another surface. The audit is what
/// caught it, on a screen that had already been looked at.
class DeckIconArea extends StatelessWidget {
  const DeckIconArea({
    required this.icon,
    required this.tint,
    this.semanticLabel,
    this.wellColor,
    super.key,
  });

  final IconData icon;
  final Color tint;
  final String? semanticLabel;

  /// Null keeps the brand container. Pass one only to say the row is in a state
  /// the brand colour would talk over.
  final Color? wellColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: wellColor ?? context.colors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: SizedBox.square(
        dimension: AppSpacing.minimumTouchTarget,
        child: Center(
          child: Icon(
            icon,
            size: AppIconSize.md,
            color: tint,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
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

/// A short banner explaining why an action is not available in this build.
///
/// Used for the card handoff to M4.11. It is a statement, not a control: an
/// enabled-looking button that does nothing is worse than no button, and hiding
/// the fact entirely would leave an `unset` deck looking as though it could only
/// ever hold decks — which contradicts BR-61.
class DeckNoticeWidget extends StatelessWidget {
  const DeckNoticeWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: AppIconSize.sm,
            color: context.semanticColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
