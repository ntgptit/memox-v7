import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database_provider.dart';
import '../../core/time/clock_provider.dart';
import '../../features/deck/data/datasources/deck_dao.dart';
import '../../features/deck/data/repositories/deck_repository_impl.dart';
import '../../features/deck/domain/repositories/deck_repository.dart';

/// Where each repository contract is bound to its implementation.
///
/// **The only place an implementation is named outside its own layer.** A feature
/// declares what it needs — `deckRepositoryProvider`, typed as the domain contract
/// — and this file decides what satisfies it. `buildRootWidget` installs the
/// bindings; nothing else may.
///
/// The direction matters more than the location. `app/` importing `features/` is
/// the composition root doing its job; the reverse would make a feature depend on
/// the shell, and that is what
/// `test/app/architecture_boundary_test.dart` forbids.
///
/// **Factory functions, not a list of `Override`s.** Riverpod's `Override` is a
/// sealed type in `src/`, not part of `flutter_riverpod`'s public API, so a
/// function cannot be declared to return one. The call site writes
/// `deckRepositoryProvider.overrideWith(deckRepositoryBinding)` instead, which
/// names only public types and keeps the construction here.
///
/// Adding a feature adds one function here and one line at the root. That is the
/// whole cost, and it is deliberately not zero: a repository whose implementation
/// nobody had to choose is a repository nobody can substitute.
DeckRepository deckRepositoryBinding(Ref ref) => DeckRepositoryImpl(
  DeckDao(ref.watch(appDatabaseProvider)),
  // From `clockProvider` rather than a default inside the repository, so "now"
  // has one owner the whole tree can override.
  clock: ref.watch(clockProvider),
);
