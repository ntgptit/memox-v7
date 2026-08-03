import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_context_model.dart';

/// Where the card list sits in the deck tree (W1).
///
/// The card mirror of `deck_path_widget.dart`, built from the card feature's own
/// [DeckContextModel] rather than the deck feature's snapshot (AD-13). The shared
/// [MxBreadcrumb] speaks neither type — only a label and a tap — so nothing here
/// drags a deck entity into the card side.
///
/// The strip is literal, matching the deck screen: the deck list, every ancestor,
/// then the deck the cards belong to as a quiet last step. That last step
/// duplicates the app-bar title on purpose — the same accepted cost the deck path
/// carries, bought back by the breadcrumb always having the same shape in the
/// same place.
///
/// Navigation goes by route name and path-parameter constant, like every jump in
/// this feature — a literal `/decks/$id` would break silently the first time the
/// route moves.
class CardBreadcrumbWidget extends StatelessWidget {
  const CardBreadcrumbWidget({required this.deckContext, super.key});

  /// The deck this card list belongs to: its name and the ancestors above it.
  final DeckContextModel deckContext;

  @override
  Widget build(BuildContext context) {
    return MxBreadcrumb(
      // Shared copy with the deck path: this walks the same tree.
      semanticLabel: context.l10n.deckPathSemanticLabel,
      rootIcon: Icons.home_outlined,
      items: <MxBreadcrumbItem>[
        // The top of the tree; always tappable here, because the card list is
        // never the root (a root holds decks, not cards — BR-58).
        MxBreadcrumbItem(
          label: context.l10n.deckPathRootLabel,
          onTap: () => context.goNamed(RouteNames.decks),
        ),
        for (final DeckBreadcrumbSegment segment in deckContext.ancestors)
          MxBreadcrumbItem(
            label: segment.name,
            onTap: () => context.goNamed(
              RouteNames.deckDetail,
              pathParameters: <String, String>{
                RoutePathParams.deckId: segment.id,
              },
            ),
          ),
        // No `onTap`: this is the deck the user is already in.
        MxBreadcrumbItem(label: deckContext.deckName),
      ],
    );
  }
}
