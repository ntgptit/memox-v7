import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/deck_repository.dart';

part 'deck_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root.
///
/// **Why the feature declares it and the app supplies it.** This provider used to
/// live in `lib/app/di/`, which meant `features/deck/presentation/` imported
/// `app/` — a feature depending on the shell it happens to be mounted in. Two
/// concrete costs, not a style objection:
///
/// * the deck feature could not be lifted out or reasoned about alone, because
///   part of its wiring was somewhere else;
/// * cloning the feature meant editing `app/di/` too, and forgetting to would
///   surface as a compile error inside the *new feature* rather than at the root
///   where the omission actually was.
///
/// Now the direction is one-way: `app/` may see `features/`, never the reverse,
/// and `test/app/architecture_boundary_test.dart` enforces it.
///
/// **The body throws, and that is the design.** There is no default: the whole
/// point is that `presentation/` may not name `DeckRepositoryImpl` — it may not
/// import `data/` — so this layer can state the requirement and nothing more.
/// `deckRepositoryBinding` in `app/di/repository_bindings.dart` is what satisfies
/// it, from `buildRootWidget`.
///
/// A missing override is therefore a `StateError` on first read rather than a
/// compile error, which is the one thing this shape gives up. It is bounded: the
/// first read happens as the deck list mounts, so a forgotten binding fails
/// immediately on launch and in every widget test, and
/// `bootstrap_test.dart` asserts the real root supplies it.
///
/// **Why `di/` and not `presentation/providers/`.** It was in
/// `presentation/providers/` first, and `provider_convention_test.dart` rejected
/// it: nothing under `features/*/presentation/` may be `keepAlive`, because state
/// that outlives a screen is state that shows the user something stale. That rule
/// is right and this provider is not presentation — it is the feature's dependency
/// seam, so it gets its own layer beside `domain/`, `data/` and `presentation/`.
/// The alternative was making it `autoDispose`, which would rebuild the repository
/// on every navigation and re-run each screen's first query for nothing.
///
/// `keepAlive` then matches `appDatabaseProvider`: a repository is a thin wrapper
/// over a DAO, and there is exactly one of it.
@Riverpod(keepAlive: true)
DeckRepository deckRepository(Ref ref) => throw StateError(
  'deckRepositoryProvider was read without an override. The composition root '
  'binds it — see deckRepositoryBinding in app/di/repository_bindings.dart. A '
  'test must override it with a fake.',
);
