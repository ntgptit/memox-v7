import '../repositories/tag_catalog_repository.dart';

/// Removes a tag from every card and deletes it (UC-18 A3, BR-235).
///
/// Thin, and there is deliberately nothing here to make it thicker: the count
/// the confirmation quotes comes from the catalog row the user is looking at,
/// and re-reading it here would be a second snapshot of the number the dialog
/// already showed. The unlink-then-delete pair is one transaction in the
/// repository, because "how many links are there" and "remove them" have to be
/// one step.
///
/// **No card is deleted, and the type system cannot say so** — only the
/// repository's statements can. That is why BR-235 is pinned by a real-SQLite
/// test that counts cards before and after, rather than by this signature.
class DeleteTagUseCase {
  const DeleteTagUseCase(this._repository);

  final TagCatalogRepository _repository;

  Future<void> call(String tagId) => _repository.deleteTag(tagId);
}
