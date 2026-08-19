import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_list_tile.dart';
import '../../../domain/models/tag_catalog_entry_model.dart';

/// One catalog row: the tag's name, how many cards carry it, and its menu
/// (UC-18, wireframe M4.14 W2).
///
/// **The count sits under the name, not opposite it** (M4.14 G3). A number
/// right-aligned across from a name of arbitrary length leaves a band of white
/// that reads as an empty column, and at textScale 2.0 the two collide. Under
/// the name it is a subtitle, which is also what a screen reader announces
/// second — the order a person asks the two questions in.
///
/// **No chip, no colour, no card preview** (M4.14 T9). A tag is a text
/// identifier in v1; the only fact worth showing beside the name is the one that
/// decides whether to rename it or delete it.
class TagCatalogRowWidget extends StatelessWidget {
  const TagCatalogRowWidget({
    required this.entry,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  final TagCatalogEntry entry;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return MxListTile(
      title: entry.name,
      // ICU plural, both locales — `1 card` / `12 cards` / `No cards`. A hand
      // built `'$n cards'` is correct in exactly one language and wrong in the
      // singular of that one.
      subtitle: context.l10n.tagCardCount(entry.cardCount),
      trailing: PopupMenuButton<void>(
        icon: const Icon(Icons.more_vert),
        // Named for the tag, so a reader moving through a long list hears which
        // row's menu it is rather than "more options" fifteen times.
        tooltip: context.l10n.tagRowMenuSemantics(entry.name),
        itemBuilder: (menuContext) => <PopupMenuEntry<void>>[
          PopupMenuItem<void>(
            onTap: onRename,
            child: _MenuRow(
              icon: Icons.edit_outlined,
              label: menuContext.l10n.tagRenameAction,
            ),
          ),
          PopupMenuItem<void>(
            onTap: onDelete,
            child: _MenuRow(
              icon: Icons.delete_outline,
              // `Delete tag`, never a bare `Delete` — in an app full of cards
              // the noun is what keeps the two apart (M4.14 T8, BR-235).
              label: menuContext.l10n.tagDeleteAction,
            ),
          ),
        ],
      ),
    );
  }
}

/// One menu row: a muted glyph and the action's words.
///
/// The same shape the card list's overflow menu uses. Private here rather than
/// shared with it: the two menus are in different features' surfaces of the same
/// feature, and hoisting a four-line `Row` into `shared/` buys a dependency
/// instead of a component.
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
