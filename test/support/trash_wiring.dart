import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_dao.dart';
import 'package:memox/features/study/data/repositories/study_repository_impl.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';
import 'package:memox/features/trash/data/repositories/content_trash_repository_impl.dart';
import 'package:memox/features/trash/domain/repositories/content_trash_repository.dart';

/// The batch half of a soft delete, wired the way the composition root wires it
/// (BR-256).
///
/// **The real implementation, not a fake, and that is the point.** Every test
/// that builds a `DeckRepositoryImpl` or `CardRepositoryImpl` against a real
/// database is testing a delete path that now creates a batch, closes sessions
/// and marks a subtree — inside the caller's transaction. A stub here would
/// leave all of that untested in exactly the tests that own the delete rules.
///
/// One function rather than a line at each call site, because the wiring is a
/// fact about the app (`contentTrashRepositoryBinding`), and six copies of it
/// are six places to forget the `study` argument the day BR-259 changes.
ContentTrashRepository contentTrashForTest(
  AppDatabase db, {
  required DateTime Function() clock,
  String Function()? idGenerator,
}) => ContentTrashRepositoryImpl(
  TrashDao(db),
  clock: clock,
  study: StudyRepositoryImpl(StudyDao(db)),
  idGenerator: idGenerator,
);
