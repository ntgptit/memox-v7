import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/di/deck_repository_provider.dart';
import '../../../../core/state/retry_policy.dart';
import '../../domain/models/deck_move_target_model.dart';

part 'deck_move_targets_controller.g.dart';

/// The candidate parents for moving one deck (UC-09).
///
/// Built from a single `watchAllDecks()` stream and the pure
/// `buildDeckMoveTargets`. One query, whatever the shape of the tree: the
/// picker has to show every tree by definition, so asking per root would be N+1
/// in the number of roots.
///
/// Eligibility is computed, not fetched — the rules are arithmetic over parent
/// pointers (BR-55, BR-64, BR-70, BR-74) and belong in a function that can be
/// unit-tested without a database. `MoveDeckController` still submits to
/// `moveDeck`, which re-checks all of it inside the transaction.
///
/// A root deck yields an empty list: moving a root is out of MVP scope (UC-09
/// A2), because the deck would need a scheduler of its own and that is a new
/// decision rather than a move.
@Riverpod(retry: noAutomaticRetry)
Stream<List<DeckMoveTarget>> deckMoveTargets(Ref ref, String deckId) {
  final repository = ref.watch(deckRepositoryProvider);

  return repository.watchAllDecks().asyncMap(
    (decks) async => buildDeckMoveTargets(
      source: await repository.getDeckById(deckId),
      allDecks: decks,
    ),
  );
}
