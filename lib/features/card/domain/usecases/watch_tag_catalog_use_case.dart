import '../models/tag_catalog_entry_model.dart';
import '../repositories/tag_catalog_repository.dart';

/// Every tag with its card count, narrowed by what the user typed (UC-12,
/// BR-182).
///
/// Thin, and thin on purpose (AD-12): the search term is the screen's input and
/// the fold belongs to the statement, so there is nothing left for this layer to
/// decide. It exists because the uniformity is what makes a controller a clone
/// rather than a judgement call — a controller calls a use case, never a
/// repository.
class WatchTagCatalogUseCase {
  const WatchTagCatalogUseCase(this._repository);

  final TagCatalogRepository _repository;

  Stream<List<TagCatalogEntry>> call({String? searchTerm}) =>
      _repository.watchTagCatalog(searchTerm: searchTerm);
}
