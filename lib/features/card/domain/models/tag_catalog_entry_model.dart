import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_catalog_entry_model.freezed.dart';

/// One row of the tag catalog: a tag and how many cards carry it (BR-230).
///
/// **A read model, not [TagEntity] with a number bolted on.** `TagEntity` is
/// what a chip renders — an id and a name — and it travels on the card editor's
/// stream where a count would be dead weight read on every keystroke. The
/// catalog is the one surface where the count *is* the content: it is what
/// decides whether a tag is worth renaming or safe to delete, and it is the
/// number BR-235's confirmation has to say out loud.
///
/// [cardCount] is **active** cards (BR-230, BR-237), and "active" is load-bearing
/// now that Trash ships: a card hidden in Trash keeps its tag links (BR-259) and
/// MUST NOT count here. The exclusion lives in the statement behind this field
/// and nowhere else — no screen filters it a second time.
@freezed
abstract class TagCatalogEntry with _$TagCatalogEntry {
  const factory TagCatalogEntry({
    required String id,

    /// The canonical spelling, exactly as stored — never the folded form. The
    /// fold is an identity, not a display value (BR-93).
    required String name,

    /// How many cards carry this tag. Zero is a legitimate row: a tag nothing
    /// points at is precisely what a user opens the catalog to remove.
    required int cardCount,

    /// How many cards would lose this tag if it were deleted (BR-235).
    ///
    /// **Not [cardCount], and the difference is the point.** Deleting a tag
    /// removes every `card_tags` row for it, so a card hidden in Trash loses
    /// its link too — it is simply not visible in [cardCount], which BR-230
    /// scopes to active cards. One field cannot answer both questions without
    /// breaking one of the two rules, so there are two.
    required int linkedCardCount,
  }) = _TagCatalogEntry;
}
