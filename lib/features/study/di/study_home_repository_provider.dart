import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/study_home_repository.dart';

part 'study_home_repository_provider.g.dart';

/// The Study tab's read contract, declared here and bound at the composition
/// root — the shape every repository in this project has (AD-13).
///
/// **Its own provider rather than a second role for `studyRepositoryProvider`.**
/// A screen holding only this cannot open a session, which is what turns
/// "entering the Study tab writes nothing" (BR-182) into something the type
/// system enforces rather than something a reviewer has to notice.
///
/// The body throws for the reason the others do: `presentation/` may not name an
/// implementation, so this layer states the requirement and nothing more. A
/// missing binding is a `StateError` on first read, and the first read happens
/// as the tab mounts.
@Riverpod(keepAlive: true)
StudyHomeRepository studyHomeRepository(Ref ref) => throw StateError(
  'studyHomeRepositoryProvider must be overridden at the composition root',
);
