import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/library_search_repository.dart';

part 'library_search_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root — the shape `deckRepositoryProvider` explains at length.
///
/// **The body throws, and that is the design.** `presentation/` may not import
/// `data/`, so this layer can state the requirement and nothing more.
/// `librarySearchRepositoryBinding` in `app/di/repository_bindings.dart` is what
/// satisfies it.
///
/// **`di/`, not `presentation/providers/`**: `provider_convention_test.dart`
/// refuses `keepAlive` under `presentation/`, and a search repository rebuilt on
/// every navigation would re-open its first query for nothing.
@Riverpod(keepAlive: true)
LibrarySearchRepository librarySearchRepository(Ref ref) => throw StateError(
  'librarySearchRepositoryProvider was read without an override. The '
  'composition root binds it — see librarySearchRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);
