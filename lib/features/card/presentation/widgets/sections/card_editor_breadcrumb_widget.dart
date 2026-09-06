import 'package:flutter/material.dart';

import '../../../../../l10n/l10n_extension.dart';
import '../../../../../shared/widgets/mx_breadcrumb.dart';
import '../../../domain/models/deck_context_model.dart';
import '../overlays/card_ancestors_widget.dart';

/// The editor's path: the card list's trail with one more step — `Edit`, where
/// the user is.
///
/// **A section of its own because the shell pins it** (SC-C4-03). It used to be
/// the first row of `CardEditorContextWidget`, inside the scroll, so it left
/// the screen the moment the user reached the tags or the Trash card — while
/// the pinned `subheader`, the slot that exists precisely so a path cannot
/// scroll away (`mx_content_shell.dart`), carried a transient flag-write error
/// instead. The two were the wrong way round. The screen now mounts this in
/// `subheader` and keeps the failure line under it, so both are chrome and
/// neither scrolls.
///
/// Built here rather than reusing `CardBreadcrumbWidget` because that one ends
/// at the deck — its last step is the screen it belongs to. Adding a parameter
/// to make its leaf configurable would make two screens share a widget whose
/// whole shape is "the last crumb is me".
class CardEditorBreadcrumbWidget extends StatelessWidget {
  const CardEditorBreadcrumbWidget({
    required this.deckId,
    required this.deck,
    required this.leafLabel,
    required this.onLeave,
    super.key,
  });

  final String deckId;
  final DeckContextModel deck;

  /// The last, untappable step — what this screen *is*.
  ///
  /// A parameter since create started pinning the path too (SC-C9-02): the two
  /// modes share every crumb above the leaf and differ only in the leaf, so a
  /// hardcoded `Edit` was the one thing stopping create from reusing the strip.
  final String leafLabel;

  /// Runs a navigation **through the editor's exit coordinator**.
  ///
  /// **Every crumb is a way out, and they were not guarded.** The screen's
  /// whole contract is that leaving with unsaved work asks first; the back
  /// arrow, Cancel and the system gesture all honoured it while four
  /// `goNamed` calls walked straight past it and dropped the draft without a
  /// word. The callback takes the navigation as a thunk so the guard decides
  /// *whether* it happens, not this widget.
  final void Function(VoidCallback navigate) onLeave;

  @override
  Widget build(BuildContext context) {
    // One grammar with the card list's trail (A20.1 P1-16): tap goes up,
    // long-press reaches any ancestor. Both go through `onLeave`, which asks
    // about unsaved changes first.
    return MxBreadcrumb(
      semanticLabel: context.l10n.deckPathSemanticLabel,
      rootIcon: Icons.home_outlined,
      collapseAfter: 3,
      // **Up is the deck this card is in**, not that deck's parent: the path
      // reads `… / Deck / Edit`, and the strip goes one level up from the
      // screen, which is Edit (A20.1 P1-16, corrective pass). The sheet
      // lists the deck too, last, for the same reason.
      onUp: () => goUpToDeck(context, deckId, onLeave: onLeave),
      onShowAll: () => showCardAncestors(
        context,
        deckContext: deck,
        currentDeck: DeckBreadcrumbSegment(id: deckId, name: deck.deckName),
        onLeave: onLeave,
      ),
      items: <MxBreadcrumbItem>[
        MxBreadcrumbItem(label: context.l10n.deckPathRootLabel),
        for (final DeckBreadcrumbSegment segment in deck.ancestors)
          MxBreadcrumbItem(label: segment.name),
        MxBreadcrumbItem(label: deck.deckName),
        MxBreadcrumbItem(label: leafLabel),
      ],
    );
  }
}
