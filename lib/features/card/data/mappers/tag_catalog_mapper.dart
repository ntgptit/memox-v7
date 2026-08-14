import '../../../../core/database/app_database.dart';
import '../../domain/models/tag_catalog_entry_model.dart';

/// One catalog row, Drift → domain (BR-182).
///
/// A mapper per row shape, like every other one here: `TagCatalogResult` is the
/// count-carrying row and `Tag` is the plain one, so `tag_mapper.dart` keeps
/// serving the chip strip untouched.
///
/// `name_folded` deliberately does **not** cross: it is an identity the database
/// compares on, and nothing above the repository compares tags by hand —
/// `TagName.collidesWith` owns that (see `tag_entity.dart`).
TagCatalogEntry tagCatalogEntryFromRow(TagCatalogResult row) =>
    TagCatalogEntry(id: row.id, name: row.name, cardCount: row.cardCount);
