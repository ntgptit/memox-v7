import 'package:flutter/material.dart';

import '../../../core/theme/app_icon_size.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_context_extension.dart';
import '../../../l10n/l10n_extension.dart';
import '../../../shared/widgets/mx_icon_button.dart';
import '../../../shared/widgets/mx_list_tile.dart';
import '../domain/deck_entity.dart';
import '../domain/root_deck_summary_model.dart';
import 'deck_labels_widget.dart';

/// One row of the root deck list (UC-06 step 2).
///
/// A feature widget, not a shared one: it knows [RootDeckSummary], and a shared
/// tile that knew a domain type would drag the deck domain into every widget
/// test in the project. It is built **on** `MxListTile`, so padding, minimum
/// height and the selected colour still come from one place.
///
/// The due state is carried by an icon **and** words, never by colour alone
/// (UC-06 step 3). "Nothing due" is rendered in the same neutral style as
/// everything else, because finishing your reviews is good news and BR-29
/// forbids dressing it as a problem.
class DeckTileWidget extends StatelessWidget {
  const DeckTileWidget({
    required this.summary,
    required this.onTap,
    required this.onActions,
    super.key,
  });

  final RootDeckSummary summary;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return MxListTile(
      title: summary.deck.name,
      subtitle: _subtitle(context),
      leading: Icon(
        summary.hasDueCards
            ? Icons.notifications_active
            : Icons.folder_outlined,
        size: AppIconSize.md,
        // Semantics only on the state-carrying icon: the folder is decoration,
        // and announcing "folder" on every row is noise a screen-reader user
        // has to sit through.
        semanticLabel: summary.hasDueCards
            ? context.l10n.deckDueSemanticLabel
            : null,
      ),
      trailing: MxIconButton(
        icon: Icons.more_vert,
        semanticLabel: context.l10n.deckActionsSemanticLabel,
        onPressed: onActions,
      ),
      onTap: onTap,
    );
  }

  /// Card total, due state and study mode on one line.
  ///
  /// A single string rather than a `Row` of chips: `MxListTile` gives the
  /// subtitle two lines and an ellipsis, so this degrades predictably at
  /// `textScaler` 2.0 on a 320-wide screen. A row of chips would either overflow
  /// or push the trailing action off the row, which is the failure M4.8b already
  /// paid for once.
  String _subtitle(BuildContext context) {
    final parts = <String>[
      context.l10n.deckCardCountLabel(summary.totalCardCount),
      if (summary.hasDueCards)
        context.l10n.deckDueCountLabel(summary.dueCardCount)
      else
        context.l10n.deckNoDueLabel,
      context.schedulerLabel(summary.deck.schedulerType),
    ];

    return parts.join(' · ');
  }
}

/// One child deck inside a deck detail screen.
///
/// Separate from [DeckTileWidget] because it shows different facts: a sub-deck
/// has no scheduler of its own (BR-06) and no aggregate counts of its own on
/// this screen. Merging the two behind a pile of nullable parameters would make
/// every field optional and the row's meaning unreadable.
class DeckChildTileWidget extends StatelessWidget {
  const DeckChildTileWidget({
    required this.deck,
    required this.onTap,
    required this.onActions,
    super.key,
  });

  final DeckEntity deck;
  final VoidCallback onTap;
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    return MxListTile(
      title: deck.name,
      leading: const Icon(Icons.folder_outlined, size: AppIconSize.md),
      trailing: MxIconButton(
        icon: Icons.more_vert,
        semanticLabel: context.l10n.deckActionsSemanticLabel,
        onPressed: onActions,
      ),
      onTap: onTap,
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
