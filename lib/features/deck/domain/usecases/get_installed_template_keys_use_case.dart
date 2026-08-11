import '../repositories/deck_template_repository.dart';

/// Which starter templates the library already holds a copy of (BR-37).
///
/// Thin, and that is the accepted cost of the uniform layer (AD-12): the
/// starter screen composes this with the *asset* catalog, which is not behind a
/// repository because it cannot be — it is the build's own bundle. The two
/// sources cannot produce the split-snapshot bug AD-13 guards against, because
/// the catalog is immutable for the life of the process.
final class GetInstalledTemplateKeysUseCase {
  const GetInstalledTemplateKeysUseCase(this._repository);

  final DeckTemplateRepository _repository;

  Future<Set<({String templateId, int version})>> call() =>
      _repository.installedTemplateKeys();
}
