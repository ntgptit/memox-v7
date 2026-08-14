import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/progress_repository.dart';

part 'progress_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root.
///
/// The same shape `deckRepositoryProvider` and `studyRepositoryProvider` have,
/// and for the same reason: `features/` may never import `app/` (AD-13), so the
/// feature states what it requires and `app/di/repository_bindings.dart` decides
/// what satisfies it.
///
/// **The body throws, and that is the design.** A missing binding is a
/// `StateError` on the first read rather than a compile error; it is bounded,
/// because the first read happens as the Progress tab mounts.
@Riverpod(keepAlive: true)
ProgressRepository progressRepository(Ref ref) => throw StateError(
  'progressRepositoryProvider must be overridden at the composition root',
);
