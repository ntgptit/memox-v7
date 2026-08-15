import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import 'card_export_sheet_widget.dart';

/// The card list's overflow menu: import, export and the tag catalog.
///
/// **In `overlays/` because it opens one** (AD-15). A `PopupMenuButton` pushes a
/// menu route, and every one of its items opens something else — a pushed
/// wizard, a modal sheet, another screen.
///
/// **Extracted when the third item arrived** (M99.30). It was written inline in
/// `card_list_screen.dart`, which then crossed the 400-line guard; the seam is
/// honest rather than arbitrary, because the menu is the one part of the app bar
/// that is a list of destinations instead of a control the screen's own state
/// drives.
class CardListMenuWidget extends StatelessWidget {
  const CardListMenuWidget({
    required this.deckId,
    required this.deckTotal,
    required this.onImport,
    super.key,
  });

  final String deckId;

  /// How many cards the deck holds. Only export reads it — see below.
  final int deckTotal;

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      icon: const Icon(Icons.more_vert),
      tooltip: context.l10n.cardSelectionMoreLabel,
      itemBuilder: (menuContext) => <PopupMenuEntry<void>>[
        // Import lives in the overflow, not as a third icon (M4.12 W6): the bar
        // already carries Select and Add at 320px, and bulk input is an
        // occasional action.
        PopupMenuItem<void>(
          onTap: onImport,
          child: _MenuRow(
            icon: Icons.upload_file_outlined,
            label: menuContext.l10n.cardImportEntryAction,
          ),
        ),
        // Export is offered only when there is something to export (M4.13 W1):
        // an empty deck has no export path at all, not a greyed one — and a
        // `deck`-type or root deck never reaches this screen, because neither
        // holds cards directly.
        if (deckTotal > 0)
          PopupMenuItem<void>(
            onTap: () => exportDeckCards(
              context,
              deckId: deckId,
              deckCardCount: deckTotal,
            ),
            child: _MenuRow(
              icon: Icons.ios_share,
              label: menuContext.l10n.cardExportEntryAction,
            ),
          ),
        // The catalog is library-level, so its main door is on the deck list
        // (M4.14 T2). It is offered here too because the card list is where a
        // user *notices* a misspelt tag — and by route name, so no feature
        // imports another's screen (AD-13). Shown even on an empty deck: the
        // catalog is about every deck's tags, not this one's cards.
        //
        // **Pushed, not gone-to — the same rule Import states two files away.**
        // `/tags` is a child of `/`, so a `go` rebuilds the branch stack from
        // the URL and lands on `[deck list root, catalog]`: Back then leaves
        // the user at the root instead of the card list they came from (M4.14
        // T1), and the card list's autoDispose state — the applied tag filter,
        // the selection, the grown window — is destroyed on the way.
        PopupMenuItem<void>(
          onTap: () => context.pushNamed(RouteNames.tagCatalog),
          child: _MenuRow(
            icon: Icons.sell_outlined,
            label: menuContext.l10n.tagCatalogEntryAction,
          ),
        ),
      ],
    );
  }
}

/// One overflow-menu row: a muted glyph and the action's words.
///
/// Extracted when Export joined Import — two hand-built `Row`s were already one
/// copy apart, and the third would have been the one that drifted.
class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: context.colors.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Text(label, style: context.texts.bodyMedium),
      ],
    );
  }
}
