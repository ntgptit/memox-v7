import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/deck_template_repository.dart';
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
