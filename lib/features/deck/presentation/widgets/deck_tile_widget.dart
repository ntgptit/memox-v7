import 'package:flutter/material.dart';

import '../../../../core/theme/app_icon_size.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/widgets/mx_card.dart';
import '../../../../shared/widgets/mx_icon_button.dart';
import '../../domain/models/deck_summary_model.dart';
import 'deck_labels_widget.dart';

/// One deck in a deck list, at any level (UC-06 step 2).
///
/// There used to be a second tile for sub-decks, showing only a name — because
/// the detail screen's query did not load counts for them. The recursive
/// aggregate landed and the reason evaporated: a sub-deck now carries the same
/// three facts a root does, so it gets the same row. Deleting the second tile is
/// the point of the unification, not a tidy-up after it.
///
/// A feature widget, not a shared one: it knows [DeckSummary], and a shared
/// tile that knew a domain type would drag the deck domain into every widget test
/// in the project. It is built **on** `MxCard`, so the surface colour, the corner
/// radius, the border and the ripple still come from one place.
///
/// **It stopped being an `MxListTile` at M4.12.** A `ListTile` puts the leading
/// glyph, the title and the trailing control on one baseline at a fixed height,
/// which reads as a row in a table — every deck the same weight, nothing to scan
/// for. The card gives the name its own line at title weight, the counts a
/// quieter line under it, and the state its own colour, so a list of twenty decks
/// can be read by shape instead of by reading each row.
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
    return MxCard(
      onTap: onTap,
      child: Row(
        // Top, not centre. Once the name wraps — a long deck title, or any title
        // at `textScaler` 2.0 — a centred glyph floats halfway down the card with
        // nothing beside it, and the row stops reading left-to-right. Anchoring
        // both edges to the first line keeps the icon next to the name it labels.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DeckIconArea(
            icon: summary.hasDueCards
                ? Icons.notifications_active
                : Icons.folder_outlined,
            // Semantics only on the state-carrying icon: the folder is
            // decoration, and announcing "folder" on every row is noise a
            // screen-reader user has to sit through.
            semanticLabel: summary.hasDueCards
                ? context.l10n.deckDueSemanticLabel
                : null,
            tint: summary.hasDueCards
                ? context.semanticColors.warning
                : context.colors.onPrimaryContainer,
          ),
          const SizedBox(width: AppSpacing.lg),
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
                const SizedBox(height: AppSpacing.xs),
                // The scheduler on its own line, quietest of the three. It was on
                // the line above and wrapped there on *every* card at 390 wide —
                // so each card was two or three lines tall depending on the
                // deck's name, and the list had no consistent rhythm. It is also
                // the least scannable of the three facts: it changes once, at
                // creation, and never again.
                Text(
                  // `summary.schedulerType`, not `summary.deck.schedulerType`.
                  // Only a root carries the column (BR-06), so the entity's own
                  // field is null on every deck below the first level — the
                  // query resolves it through `root_deck_id` and the summary
                  // carries the answer.
                  context.schedulerLabel(summary.schedulerType),
                  style: context.texts.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
    super.key,
  });

  final IconData icon;
  final Color tint;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.primaryContainer,
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
/// The scheduler used to be a third clause here and now has its own line. Two
/// facts fit the width; three did not, so every card wrapped and no two cards
/// were the same height.
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
          TextSpan(
            text: context.l10n.deckCardCountLabel(summary.totalCardCount),
          ),
          const TextSpan(text: ' · '),
          TextSpan(
            text: summary.hasDueCards
                ? context.l10n.deckDueCountLabel(summary.dueCardCount)
                : context.l10n.deckNoDueLabel,
            style: quiet?.copyWith(
              color: summary.hasDueCards
                  ? context.semanticColors.warning
                  : context.semanticColors.success,
              fontWeight: FontWeight.w600,
            ),
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
