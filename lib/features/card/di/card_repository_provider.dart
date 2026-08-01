import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/repositories/card_repository.dart';

part 'card_repository_provider.g.dart';

/// The repository this feature needs, declared as the **contract** and bound at
/// the composition root.
///
/// The shape and the reasoning are `deckRepositoryProvider`'s — read that file
/// for why the feature declares its own seam, why the body throws, and why this
/// is `di/` rather than `presentation/providers/`.
///
/// **What this one adds is that the seam now has a second user.** Until it,
/// `deckRepositoryProvider` was the only contract that had ever gone through
/// `repository_bindings.dart`, so "adding a feature costs one function here and
/// one line at the root" was a claim with a sample size of one. `CardRepository`
/// exercises it: a different implementation shape — `CardRepositoryImpl` takes
/// the `AppDatabase` and builds both of its DAOs itself, because its BR-62
/// content lock and its card insert must share one transaction — and the
/// binding absorbs that difference without the contract or this file changing.
@Riverpod(keepAlive: true)
CardRepository cardRepository(Ref ref) => throw StateError(
  'cardRepositoryProvider was read without an override. The composition root '
  'binds it — see cardRepositoryBinding in app/di/repository_bindings.dart. A '
  'test must override it with a fake.',
);
