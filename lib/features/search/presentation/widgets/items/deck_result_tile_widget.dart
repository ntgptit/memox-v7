import 'package:flutter/material.dart';

import '../../../../../core/theme/extensions/app_ink.dart';
import '../../../../../core/theme/extensions/theme_context_extension.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/models/search_result_model.dart';
import '../support/search_labels_widget.dart';
import 'search_result_shell_widget.dart';

/// One deck the search found.
///
/// **The path is above the name, not after it.** Three sub-decks in one library
/// can all be called "Nouns"; a list of bare names is a list of identical rows
/// the user has to open one at a time to tell apart.
class DeckResultTileWidget extends StatelessWidget {
  const DeckResultTileWidget({
    required this.hit,
    required this.onOpen,
    super.key,
  });

  final DeckSearchHit hit;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final String path = context.mxDeckPathLine(hit.deckPath);

    return SearchResultShellWidget(
      // The one thing a result row needs from `content_type`: a deck of cards
      // and a deck of decks open onto different things (BR-63).
      icon: hit.isCardDeck ? Icons.style_outlined : Icons.folder_outlined,
      semanticLabel: path.isEmpty
          ? context.l10n.librarySearchDeckResultSemantic(hit.name)
          : context.l10n.librarySearchDeckResultInPathSemantic(hit.name, path),
      onOpen: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (path.isNotEmpty)
            Text(
              path,
              style: context.texts.labelSmall!.inked(context, AppInk.quiet),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            hit.name,
            style: context.texts.bodyLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
