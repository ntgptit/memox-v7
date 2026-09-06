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
            // titleMedium, not bodyLarge: the name is the thing the row is
            // about, and at bodyLarge's w400 it sat *lighter* than the w500
            // path caption directly above it — the quietest line on the row
            // carrying the most weight, so the row had no dominant element at
            // all. titleMedium is also what every other `MxCard` row in the app
            // titles at (`deck_tile_widget.dart`, `card_tile_widget.dart`,
            // `progress_deck_row_widget.dart`,
            // `study_home_deck_item_widget.dart`). bodyLarge is the *list tile*
            // family's title rung (`app_list_tile_theme.dart`), and these rows
            // are built on `MxCard.raised`, not on a list tile.
            hit.name,
            style: context.texts.titleMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
