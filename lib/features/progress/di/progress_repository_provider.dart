import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/progress_repository.dart';

part 'progress_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root — the same shape `deckRepositoryProvider` documents at
/// length, and for the same reasons.
///
/// The body throws because there is no default: `presentation/` may not import
/// `data/`, so this layer can state the requirement and nothing more.
/// `progressRepositoryBinding` in `app/di/repository_bindings.dart` satisfies it,
/// and it is in `repositoryBindingOverrides()` so no harness can be written
/// without it — the omission that once broke sixty-six scenarios at once.
///
/// `keepAlive` matches `appDatabaseProvider`: a repository is a thin wrapper over
/// a DAO and there is exactly one of it. An `autoDispose` one would be rebuilt on
/// every navigation and re-run the first query for nothing.
@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) => throw StateError(
  'progressRepositoryProvider was read without an override. The composition '
  'root binds it — see progressRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);
