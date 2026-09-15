import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_sizing.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_menu_button.dart';
import '../../../domain/models/tag_catalog_entry_model.dart';

/// One catalog row: the tag's name, how many cards carry it, and its menu
/// (UC-18, wireframe M4.14 W2 — visual revision of 2026-08-28).
///
/// **Laid out by hand rather than through `MxListTile`, and the trade is
/// recorded.** The tile's type and insets come from `listTileTheme`, which is
/// the reading-list density; the catalog sits inside one grouped `MxCard` and
/// borrows Card Detail's compact grammar instead — `titleSmall` name,
/// `bodySmall` count, a leading well. A themed tile cannot say any of that
/// without `copyWith`, which is the restyle the guard exists to refuse.
///
/// **The count sits under the name, not opposite it** (M4.14 G3). A number
/// right-aligned across from a name of arbitrary length leaves a band of white
/// that reads as an empty column, and at textScale 2.0 the two collide. Under
/// the name it is a subtitle, which is also what a screen reader announces
/// second — the order a person asks the two questions in.
///
/// **Every row wears the same well, the same glyph, the same tone.** The well
/// exists to give a long catalog a scannable left rhythm the way Card Detail's
/// bands lead with a mark; it carries no per-tag colour and no meaning beyond
/// "this is a tag", because a tag is a text identifier in v1 (M4.14 T9) and a
/// tone that varied would invent a hierarchy BR-230 does not have.
///
/// **No chip, no colour, no card preview** (M4.14 T9). The only fact worth
/// showing beside the name is the one that decides whether to rename it or
/// delete it.
class TagCatalogRowWidget extends StatelessWidget {
  const TagCatalogRowWidget({
    required this.entry,
    required this.onRename,
    required this.onDelete,
    super.key,
  });

  /// The leading well's square, public because the screen derives the
  /// separator's text-column inset from it and the geometry test pins the
  /// two together — one fact, one place, and a change here moves all three.
  static const double wellSize = AppSizing.controlDense;

  final TagCatalogEntry entry;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // `xs` on the trailing side, not `md`: the menu's 48dp anchor carries
      // ~12dp of its own internal inset, so `xs` outside puts the glyph
      // optically where `md` puts the well — and G4 measures the *target*
      // against the row edge, which stays inside it either way.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
      ),
      child: Row(
        children: <Widget>[
          const _TagWell(),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.name,
                  // Two lines before ellipsis, same as W2 declared: a canonical
                  // name is user text and may be long; one line would cut VI
                  // names that wrap at 2.0 into meaninglessness.
                  style: context.texts.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  // ICU plural, both locales — `1 card` / `12 cards` /
                  // `No cards`. A hand-built `'$n cards'` is correct in exactly
                  // one language and wrong in the singular of that one.
                  context.l10n.tagCardCount(entry.cardCount),
                  // Tabular figures: a scanned column of counts only reads as
                  // a column when its digits share a width.
                  style: context.texts.bodySmall!.inked(
                    context,
                    AppInk.quiet,
                    isTabular: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          MxMenuButton(
            // Named for the tag, so a reader moving through a long list hears
            // which row's menu it is rather than "more options" fifteen times.
            tooltip: context.l10n.tagRowMenuSemantics(entry.name),
            actions: <MxMenuAction>[
              MxMenuAction(
                icon: Icons.edit_outlined,
                label: context.l10n.tagRenameAction,
                onSelected: onRename,
              ),
              MxMenuAction(
                icon: Icons.delete_outline,
                // `Delete tag`, never a bare `Delete` — in an app full of
                // cards the noun is what keeps the two apart (M4.14 T8,
                // BR-235).
                label: context.l10n.tagDeleteAction,
                onSelected: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The neutral leading well every row shares.
///
/// [TagCatalogRowWidget.wellSize] (32dp), not the 40 a deck tile leads with: a catalog row is an operational
/// line, one step denser than a navigation tile, and the well is a rhythm
/// mark rather than the row's identity. `surfaceMuted` is the neutral step
/// Card Detail's metric wells stand on — the semantic name for the same
/// pixel `surfaceContainerHigh` carries, chosen so this decision has one
/// spelling wherever it is made.
///
/// The glyph is decorative — the row's text says "tag" better than the icon
/// does — so `MxIcon` unlabeled keeps it out of the semantics tree on its own.
class _TagWell extends StatelessWidget {
  const _TagWell();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: TagCatalogRowWidget.wellSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          // `surfaceMuted`, the spelling Card Detail's metric wells use —
          // the same pixel as `surfaceContainerHigh`, but one decision with
          // one name instead of two names that happen to agree.
          color: context.semanticColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: const Center(
          child: MxIcon(Icons.sell_outlined, size: MxIconSize.sm),
        ),
      ),
    );
  }
}
