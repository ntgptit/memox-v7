import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/foundations/app_radius.dart';
import '../../../../../core/theme/foundations/app_spacing.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_icon.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_context_model.dart';
import '../../controllers/card_list_filter_controller.dart';
import '../../controllers/deck_context_controller.dart';
import '../overlays/card_ancestors_widget.dart';

/// The wizard's header band (wireframe W1): the deck path with a
/// non-tappable `Import` tail, then the stepper, then the chip naming the
/// target deck with its current card count — the concept's order, where the
/// stepper sits directly under the path and the chip introduces the content.
///
/// **The path is a control, in the app's one up-navigation grammar**
/// (SC-C4-07). It used to pass neither `onUp` nor `onShowAll`, which dropped
/// `MxBreadcrumb` into its legacy per-step strip: the whole line did nothing,
/// and the fold turned into an interactive `more_horiz` that expanded in
/// place. So two screens one tap apart answered "where am I" with two
/// grammars. The card list and the editor both pass the pair — tap goes up a
/// level, long-press opens the ancestor sheet — and "the draft blocks
/// navigation" was never the reason this one did not: the editor has the same
/// unsaved-work problem and routes the strip through its guard.
///
/// The same one-read seam the card list header uses — `deckContextProvider` —
/// so a rename mid-import lands here on the next frame, and the deck
/// feature's Dart is never imported (AD-13).
class CardImportContextWidget extends ConsumerWidget {
  const CardImportContextWidget({
    required this.deckId,
    required this.stepper,
    required this.onLeave,
    super.key,
  });

  final String deckId;

  /// Runs a navigation **through the wizard's exit coordinator**.
  ///
  /// The strip leaves the wizard, so it asks what `✕` asks and is inert for
  /// the same reason `✕` is: a commit in flight cannot be cancelled. The
  /// navigation arrives as a thunk so the screen decides whether it happens.
  final void Function(VoidCallback navigate) onLeave;

  /// The three-step indicator, slotted between breadcrumb and chip so the
  /// screen keeps owning which steps are completed.
  final Widget stepper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckContext = ref.watch(deckContextProvider(deckId)).value;
    final cardCount = ref.watch(cardAllCountProvider(deckId)).value ?? 0;
    if (deckContext == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MxBreadcrumb(
          semanticLabel: context.l10n.deckPathSemanticLabel,
          rootIcon: Icons.home_outlined,
          upIcon: Icons.chevron_left,
          collapseAfter: 3,
          // **Up is the deck this import targets**, not that deck's parent:
          // the path reads `… / Deck / Import`, so one level up from the
          // screen is the deck — the same reading the editor makes of its own
          // `… / Deck / Edit` (A20.1 P1-16, corrective pass). The sheet lists
          // that deck too, last, for the same reason.
          onUp: () => goUpToDeck(context, deckId, onLeave: onLeave),
          onShowAll: () => showCardAncestors(
            context,
            deckContext: deckContext,
            currentDeck: DeckBreadcrumbSegment(
              id: deckId,
              name: deckContext.deckName,
            ),
            onLeave: onLeave,
          ),
          items: <MxBreadcrumbItem>[
            MxBreadcrumbItem(label: context.l10n.deckPathRootLabel),
            for (final segment in deckContext.ancestors)
              MxBreadcrumbItem(label: segment.name),
            MxBreadcrumbItem(label: deckContext.deckName),
            // The wizard itself — the last step is where the user is. No step
            // is a control of its own now that the strip is one target
            // (`MxBreadcrumb` ignores every item's `onTap` when `onUp` is
            // set), so this reads as the end of a sentence, which is what W1
            // asked for.
            MxBreadcrumbItem(label: context.l10n.cardImportBreadcrumbLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        stepper,
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const MxIcon(Icons.style_outlined, size: MxIconSize.sm),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    context.l10n.cardImportDeckContextLabel(
                      deckContext.deckName,
                      cardCount,
                    ),
                    style: context.texts.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
