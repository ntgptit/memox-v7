import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/study_repository.dart';

part 'study_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root.
///
/// The same shape `deckRepositoryProvider` has, and for the same reason:
/// `features/` may never import `app/` (AD-13), so the feature states what it
/// requires and `app/di/repository_bindings.dart` decides what satisfies it.
///
/// **The body throws, and that is the design.** `presentation/` may not name
/// `StudyRepositoryImpl` — it may not import `data/` at all — so this layer can
/// state the requirement and nothing more. A missing binding is therefore a
/// `StateError` on first read rather than a compile error; it is bounded,
/// because the first read happens as the study entry mounts.
@Riverpod(keepAlive: true)
StudyRepository studyRepository(Ref ref) => throw StateError(
  'studyRepositoryProvider must be overridden at the composition root',
);
