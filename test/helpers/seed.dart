import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/datasources/deck_template_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_template_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_template_repository_impl.dart';
import 'package:memox/features/deck/domain/usecases/install_deck_templates_use_case.dart';

/// Puts the app's shipped fixture decks into [db], through the real path.
///
/// **The real loader and the real repository, not a hand-written INSERT.** A
/// seed helper that writes rows directly is a second definition of what a
/// correct deck tree looks like, and it is the one that never gets fixed when
/// the rules change — the tests using it keep passing while the app they stand
/// in for has moved on. This one reads the same assets the app reads and writes
/// through the same transaction, so a template the app could not install is a
/// template this cannot install either.
///
/// [clock] is required for the same reason the repositories require it: nothing
/// in a test may read the wall clock, or the row it writes differs between runs.
///
/// Returns what each template did, so a caller can assert the second call was a
/// no-op (BR-37) rather than assuming it.
Future<DeckTemplateInstallReport> seedFixtureDecks(
  AppDatabase db, {
  required DateTime Function() clock,
  String Function()? idGenerator,
  DeckTemplateDataSource loader = const DeckTemplateDataSource(),
}) async {
  final repository = DeckTemplateRepositoryImpl(
    DeckTemplateDao(db),
    clock: clock,
    idGenerator: idGenerator,
  );

  return InstallDeckTemplatesUseCase(repository)(await loader.loadAll());
}
