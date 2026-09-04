import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_context_model.dart';
import '../overlays/card_ancestors_widget.dart';

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
    // **The deck list's grammar, adopted** (A20.1 P1-16): the strip is one
    // wide target that goes up a level, long-press reaches any ancestor
    // through a sheet, and the steps are a sentence rather than four small
    // controls — the model the owner chose for the deck path (2026-08-21).
    // Until now this trail was the other grammar, per-step taps, one tap
    // away from a screen that answered the same gesture differently.
    // **The deck list's grammar, adopted** (A20.1 P1-16): the strip is one
    // wide target that goes up a level, long-press reaches any ancestor
    // through a sheet, and the steps are a sentence rather than four small
    // controls — the model the owner chose for the deck path (2026-08-21).
    // Until now this trail was the other grammar, per-step taps, one tap
    // away from a screen that answered the same gesture differently.
    return MxBreadcrumb(
      // Shared copy with the deck path: this walks the same tree.
      semanticLabel: context.l10n.deckPathSemanticLabel,
      rootIcon: Icons.home_outlined,
      // Fold a step sooner than the deck list. This screen is always at phone
      // width and stacks the path over the filter pills, so a four-level chain
      // folds to `Root · … · parent · here` rather than filling the strip; the
      // ellipsis still expands. The deck list keeps the full path on purpose.
      collapseAfter: 3,
      onUp: () => goUpFromCardContext(context, deckContext),
      onShowAll: () => showCardAncestors(context, deckContext: deckContext),
      items: <MxBreadcrumbItem>[
        MxBreadcrumbItem(label: context.l10n.deckPathRootLabel),
        for (final DeckBreadcrumbSegment segment in deckContext.ancestors)
          MxBreadcrumbItem(label: segment.name),
        MxBreadcrumbItem(label: deckContext.deckName),
      ],
    );
  }
}
