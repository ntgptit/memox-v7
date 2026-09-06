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
/// **Composed exactly as `deck_path_widget.dart` composes it** (SC-C4-06/10):
/// the compact 32dp line of the header, a leading `chevron_left` saying what
/// tapping the strip does, and the open deck left off the end. It used to
/// differ from the deck screen one tap above in all three at once — a 48dp
/// band, no glyph, and the deck's own name as a trailing step — while its doc
/// claimed to match. The trailing step was the loudest of the three: it
/// repeated the app-bar title, and [MxBreadcrumb.onUp] goes to that deck's
/// *parent*, so the last word on the strip was neither where you are going nor
/// a control.
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
    return MxBreadcrumb(
      // Shared copy with the deck path: this walks the same tree.
      semanticLabel: context.l10n.deckPathSemanticLabel,
      rootIcon: Icons.home_outlined,
      // A line of the header, not a band of its own — the deck path's value
      // for the deck path's reason, now that this strip rides the same
      // `MxContentShell.titleSubline` slot.
      lineHeight: MxBreadcrumb.compactLineHeight,
      // **The chevron is what says the strip is a control.** Without it the
      // whole-strip tap was invisible, and the bar drew the platform arrow
      // beside it — two up affordances on a screen the deck level answers
      // with one.
      upIcon: Icons.chevron_left,
      // Kept a step tighter than the deck list's default of 4: this bar
      // carries up to three actions, so the line has less room than the deck
      // list's. It applies to the per-step strip only — with [onUp] set the
      // single-target form folds by measured width instead — so it is the
      // value that takes effect the day this strip stops being one target.
      collapseAfter: 3,
      onUp: () => goUpFromCardContext(context, deckContext),
      onShowAll: () => showCardAncestors(context, deckContext: deckContext),
      items: <MxBreadcrumbItem>[
        MxBreadcrumbItem(label: context.l10n.deckPathRootLabel),
        for (final DeckBreadcrumbSegment segment in deckContext.ancestors)
          MxBreadcrumbItem(label: segment.name),
        // **The open deck is not a step**, the deck path's decision adopted
        // here (owner review, 2026-08-20): its name is the bar's title one
        // line above, and the header's second line is its scarcest space.
      ],
    );
  }
}
