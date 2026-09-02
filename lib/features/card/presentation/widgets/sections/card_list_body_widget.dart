import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_text_button.dart';
import '../../../domain/models/card_list_item_model.dart';
import '../../controllers/card_list_now_controller.dart';
import '../../controllers/card_list_window_controller.dart';
import '../../controllers/card_selection_controller.dart';
import '../items/card_tile_widget.dart';
import '../support/card_sort_control_widget.dart';
import 'card_progress_panel_widget.dart';

/// Grows the read window by one step (W1b).
///
/// A free function, not a closure in `build()`: `ref.read` inside a build reads
/// without subscribing and is almost always the bug the guard forbids, so a
/// command is written where the guard can tell it apart — the same shape
/// `deck_list_toolbar_widget.dart` uses for its filter and sort.
void _growWindow(WidgetRef ref, String deckId) =>
    ref.read(cardListWindowProvider(deckId).notifier).grow();

class CardListBodyWidget extends ConsumerWidget {
  const CardListBodyWidget({
    required this.deckId,
    required this.items,
    required this.total,
    required this.onOpen,
    super.key,
  });

  final String deckId;
  final List<CardListItemModel> items;
  final int total;
  final void Function(CardListItemModel item) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMore = items.length < total;
    final selection = ref.watch(cardSelectionProvider(deckId));
    // One "now" for the whole list, from the composition root — every badge is
    // measured against the same instant, and the tile never reads the clock.
    final now = ref.watch(cardListNowProvider);

    // Two header rows scroll above the cards: the progress panel (D5) and the
    // "showing N of M" line. The filter pills pin in the subheader instead, so
    // they stay reachable while the panel scrolls away.
    const headerCount = 2;

    return ListView.separated(
      // `xl` on top, not `md`: with the shell no longer padding this scroll view
      // the only space above the panel would be the subheader's `xs`, and the
      // panel would sit tighter under the pills than it did before the double
      // gutter was removed. `xl` under the strip's `xs` is the 28 the deck
      // list's first section already stands at.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: items.length + headerCount + 1,
      // A plain gap between everything: each card row is now its own bordered
      // surface (MxCard, like the deck list), so the separation is the space
      // between cards, not a hairline drawn through one dense block.
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        if (index == 0) {
          return CardProgressPanelWidget(deckId: deckId);
        }
        if (index == 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.l10n.cardListShowing(items.length, total),
                    // The 1.1 was `sectionLabelTracking` spelled as a bare
                    // number; the role names it.
                    style: context.textStyles.sectionLabelSmall.inked(
                      context,
                      AppInk.quiet,
                    ),
                  ),
                ),
                CardSortControlWidget(deckId: deckId),
              ],
            ),
          );
        }
        final cardIndex = index - headerCount;
        if (cardIndex < items.length) {
          final item = items[cardIndex];
          final controller = ref.read(cardSelectionProvider(deckId).notifier);

          return CardTileWidget(
            item: item,
            now: now,
            isSelectionMode: selection.isSelecting,
            isSelected: selection.isSelected(item.card.id),
            // Inside the mode a tap toggles; outside it opens the read-only
            // detail screen (M99.31, UC-19) — it used to open the editor, and
            // the sibling comment on `CardTileWidget` said so too. One gesture,
            // two meanings, decided by the mode rather than by the row — which
            // is why the row is told what the mode is.
            onTap: () => selection.isSelecting
                ? controller.toggle(item.card.id)
                : onOpen(item),
            onLongPress: () => controller.beginWith(item.card.id),
          );
        }

        return _Tail(
          deckId: deckId,
          shown: items.length,
          total: total,
          hasMore: hasMore,
        );
      },
    );
  }
}

/// The bottom of the window: a load-more button while rows remain, or the line
/// that says the whole deck is on screen (W1b).
class _Tail extends ConsumerWidget {
  const _Tail({
    required this.deckId,
    required this.shown,
    required this.total,
    required this.hasMore,
  });

  final String deckId;
  final int shown;
  final int total;
  final bool hasMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasMore) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Center(
          child: Text(
            context.l10n.cardListAllShown(total),
            style: context.texts.bodySmall!.inked(context, AppInk.quiet),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Center(
        child: MxTextButton(
          label: context.l10n.cardListLoadMore(kCardWindowSize),
          onPressed: () => _growWindow(ref, deckId),
        ),
      ),
    );
  }
}
