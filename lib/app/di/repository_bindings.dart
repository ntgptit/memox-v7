import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/database/app_database_provider.dart';
import '../../core/time/clock_provider.dart';
import '../../features/card/data/repositories/card_repository_impl.dart';
import '../../features/card/domain/repositories/card_repository.dart';
import '../../features/deck/data/datasources/deck_dao.dart';
import '../../features/deck/data/datasources/deck_template_dao.dart';
import '../../features/deck/data/repositories/deck_repository_impl.dart';
import '../../features/deck/data/repositories/deck_template_repository_impl.dart';
import '../../features/deck/domain/repositories/deck_repository.dart';
import '../../features/deck/domain/repositories/deck_template_repository.dart';

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

/// **The database itself, not a DAO — and the difference is the point of this
/// file.** `CardRepositoryImpl` builds both of its adapters internally so that
/// the BR-62 content lock and the card insert cannot end up in two
/// transactions; an API taking two ready-made DAOs would let this root hand it
/// instances from two databases, and the lock would then sit outside the
/// transaction that rolls the card back. The binding absorbs that difference,
/// which is what a composition root is for: the two contracts look the same to
/// the features that declare them, and only this file knows they are wired
/// differently.
CardRepository cardRepositoryBinding(Ref ref) => CardRepositoryImpl(
  ref.watch(appDatabaseProvider),
  clock: ref.watch(clockProvider),
);

/// The template-copy path (AD-07). Its own DAO, for the reason stated on
/// `DeckTemplateDao`: it writes decks, cards and study states in one
/// transaction, which is a different job from the reads a deck list rebuild
/// runs constantly.
DeckTemplateRepository deckTemplateRepositoryBinding(Ref ref) =>
    DeckTemplateRepositoryImpl(
      DeckTemplateDao(ref.watch(appDatabaseProvider)),
      clock: ref.watch(clockProvider),
    );
