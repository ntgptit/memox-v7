import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../controllers/card_list_filter_controller.dart';
import '../../controllers/deck_context_controller.dart';

/// The wizard's place in the tree, and its target (wireframe W1): the deck
/// path with a non-tappable `Import` tail, and a chip naming the deck with
/// its current card count.
///
/// The same one-read seam the card list header uses — `deckContextProvider` —
/// so a rename mid-import lands here on the next frame, and the deck
/// feature's Dart is never imported (AD-13).
class CardImportContextWidget extends ConsumerWidget {
  const CardImportContextWidget({required this.deckId, super.key});

  final String deckId;

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
          collapseAfter: 3,
          items: <MxBreadcrumbItem>[
            MxBreadcrumbItem(label: context.l10n.deckPathRootLabel),
            for (final segment in deckContext.ancestors)
              MxBreadcrumbItem(label: segment.name),
            MxBreadcrumbItem(label: deckContext.deckName),
            // The wizard itself — the last step is where the user is, so it
            // is never tappable (W1).
            MxBreadcrumbItem(label: context.l10n.cardImportBreadcrumbLabel),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.style_outlined,
                  size: AppSpacing.lg,
                  color: context.colors.onSurfaceVariant,
                ),
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
