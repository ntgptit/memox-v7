import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/search_result_model.dart';
import '../support/search_labels_widget.dart';
import 'search_result_shell_widget.dart';

/// One card the search found.
///
/// Three lines, in the order a reader needs them: **where it is**, then the
/// front, then one line of the back. The path leads for the same reason it does
/// on a deck row — a library holds many cards whose fronts are one word.
///
/// **The back is clamped to one line, and the full text still reaches a screen
/// reader** through the row's semantic label. An ellipsis is a layout decision;
/// dropping the content from the accessibility tree would be a different one
/// nobody made.
///
/// **The matched tag is shown only when it is the reason the row is here.** A
/// card whose front and back say nothing the user typed otherwise appears with
/// no visible cause, which reads as a broken search rather than as a tag doing
/// its job (BR-252).
class CardResultTileWidget extends StatelessWidget {
  const CardResultTileWidget({
    required this.hit,
    required this.onOpen,
    super.key,
  });

  final CardSearchHit hit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    // A card's path always names at least the deck it lives in: the row is
    // built from `deck_id`, which is a foreign key, so the deck is in the
    // snapshot by construction.
    final String path = context.mxDeckPathLine(hit.deckPath);
    final String? tag = hit.matchedTagName;

    return SearchResultShellWidget(
      icon: Icons.article_outlined,
      // **The tag goes into the label, not only onto the visible line.** The
      // "Nhãn:"/"Tag:" text sits inside the row's `ExcludeSemantics`, so a screen-reader user otherwise
      // hears a front and a back containing nothing they typed and is given no
      // reason at all — and match highlighting, the other possible reason, is
      // deliberately absent (wireframe S6).
      semanticLabel: tag == null
          ? context.l10n.librarySearchCardResultSemantic(
              hit.front,
              hit.back,
              path,
            )
          : context.l10n.librarySearchCardResultTaggedSemantic(
              hit.front,
              hit.back,
              path,
              tag,
            ),
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (path.isNotEmpty)
            Text(
              path,
              style: context.texts.labelSmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            hit.front,
            style: context.texts.bodyLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            hit.back,
            style: context.texts.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (tag != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                context.l10n.librarySearchMatchedTagLabel(tag),
                style: context.texts.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}
