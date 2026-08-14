import 'package:freezed_annotation/freezed_annotation.dart';

part 'tag_catalog_entry_model.freezed.dart';

/// One row of the tag catalog: a tag and how many cards carry it (BR-182).
///
/// **A read model, not [TagEntity] with a number bolted on.** `TagEntity` is
/// what a chip renders — an id and a name — and it travels on the card editor's
/// stream where a count would be dead weight read on every keystroke. The
/// catalog is the one surface where the count *is* the content: it is what
/// decides whether a tag is worth renaming or safe to delete, and it is the
/// number BR-187's confirmation has to say out loud.
///
/// [cardCount] is **active** cards (BR-182, BR-189). Today every stored card is
/// active because there is no Trash; when there is one, the definition changes
/// in the statement behind this field and nowhere else.
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
  }) = _TagCatalogEntry;
}
