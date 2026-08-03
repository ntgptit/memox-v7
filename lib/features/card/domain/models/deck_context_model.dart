/// The card list header's view of its deck: the deck's own name and the path of
/// ancestors above it, read in one snapshot so a rename lands on the title and
/// the breadcrumb in the same frame (AD-13).
///
/// **A card-side type on purpose.** The deck feature has its own path segment and
/// list snapshot; reusing them would drag the deck presentation's shape into the
/// card screen. The card feature reads the shared database, never the deck
/// feature's Dart — the same seam `CardDeckContextDao` already draws for
/// `createCard`.
class DeckContextModel {
  const DeckContextModel({required this.deckName, required this.ancestors});

  /// The deck the card list belongs to, named as it stood in this same read.
  final String deckName;

  /// Root first, and **excluding the deck itself** — that one is [deckName], and
  /// carrying it in both places would let the title and the last crumb disagree.
  final List<DeckBreadcrumbSegment> ancestors;
}

/// One step on the path from the root down to the deck the card list is in.
///
/// Two fields, because an ancestor is read for exactly two reasons — to be named
/// and to be navigated to. Mirrors the deck feature's `DeckPathSegment` without
/// importing it (AD-13); the shared `MxBreadcrumb` speaks neither type, only a
/// label and a tap.
class DeckBreadcrumbSegment {
  const DeckBreadcrumbSegment({required this.id, required this.name});

  final String id;
  final String name;
}
