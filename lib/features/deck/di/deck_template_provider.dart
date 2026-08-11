import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/deck_template_repository.dart';
import '../domain/models/deck_template_model.dart';
import '../domain/usecases/install_deck_template_use_case.dart';
import '../domain/usecases/install_deck_templates_use_case.dart';

part 'deck_template_provider.g.dart';

/// The template-copy contract, declared here and bound at the composition root
/// — the same shape `deckRepositoryProvider` uses, and for the same reasons.
///
/// The body throws because there is no default: `presentation/` and `domain/`
/// may not name `DeckTemplateRepositoryImpl`. `deckTemplateRepositoryBinding` in
/// `app/di/repository_bindings.dart` satisfies it.
@Riverpod(keepAlive: true)
DeckTemplateRepository deckTemplateRepository(Ref ref) => throw StateError(
  'deckTemplateRepositoryProvider was read without an override. The '
  'composition root binds it — see deckTemplateRepositoryBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);

/// The use case startup calls. Built from the contract, never from the impl.
@Riverpod(keepAlive: true)
InstallDeckTemplatesUseCase installDeckTemplatesUseCase(Ref ref) =>
    InstallDeckTemplatesUseCase(ref.watch(deckTemplateRepositoryProvider));

/// The published starter catalog, as domain models (UC-01, BR-32).
///
/// Declared here and bound at the composition root, like the repository above:
/// the catalog is read from the app's asset bundle by a `data/` source, and
/// `presentation/` may not name that class. The binding is one line in
/// `app/di/repository_bindings.dart`.
///
/// `keepAlive` because the catalog is the build's shipped assets — it cannot
/// change while the process lives, so re-reading it on every screen visit
/// would be decoding the same JSON for the same answer.
@Riverpod(keepAlive: true)
Future<List<DeckTemplate>> deckTemplateCatalog(Ref ref) => throw StateError(
  'deckTemplateCatalogProvider was read without an override. The composition '
  'root binds it — see deckTemplateCatalogBinding in '
  'app/di/repository_bindings.dart. A test must override it with a fake.',
);

/// The single-template install the starter screen calls (AD-12).
@Riverpod(keepAlive: true)
InstallDeckTemplateUseCase installDeckTemplateUseCase(Ref ref) =>
    InstallDeckTemplateUseCase(ref.watch(deckTemplateRepositoryProvider));
