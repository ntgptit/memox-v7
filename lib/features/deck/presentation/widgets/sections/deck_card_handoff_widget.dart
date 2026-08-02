import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/navigation/route_names.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_empty_state.dart';

/// The body a `card` deck shows: not a deck list, but a way into its cards.
///
/// **The card list lives on the card screen, which the card feature owns, and
/// the deck feature must not import it (AD-13).** A card deck holds no sub-decks
/// (BR-63), so this level has nothing of its own to render — it hands off. The
/// hop is one tap; an automatic forward on entry needs an async content-type
/// redirect the router does not do yet, and that refinement waits for it.
///
/// Its own file rather than a branch inside `deck_list_screen.dart`: that screen
/// sits on the size guard, and a card deck's body is a section of its own — the
/// same reason the summary and the toolbar are sections.
class DeckCardHandoffWidget extends StatelessWidget {
  const DeckCardHandoffWidget({required this.deckId, super.key});

  final String deckId;

  @override
  Widget build(BuildContext context) {
    return MxEmptyState(
      icon: Icons.style_outlined,
      title: context.l10n.deckDetailEmptyCardTitle,
      message: context.l10n.deckDetailOpenCardsMessage,
      actionLabel: context.l10n.deckDetailOpenCardsAction,
      onAction: () => context.goNamed(
        RouteNames.cardList,
        pathParameters: <String, String>{RoutePathParams.deckId: deckId},
      ),
    );
  }
}
