import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/deck_deletion_impact_model.dart';
import '../providers/deck_use_case_provider.dart';

part 'deck_deletion_impact_controller.g.dart';

/// What deleting a deck would take with it (BR-04).
///
/// A future, not a stream: the confirmation dialog is a snapshot of a decision
/// the user is about to make, and a count that changed while they read it would
/// be worse than one taken at the moment it opened. The repository is still what
/// refuses a delete that has become impossible.
///
/// It lived on `deck_detail_controller.dart` until the two deck-list screens
/// became one. It has nothing to do with watching a level — the delete dialog is
/// reachable from every level — so it kept its own file rather than being folded
/// into `DeckList`, where it would have been a second responsibility on a
/// notifier whose whole point is that it is the only one.
@Riverpod(retry: noAutomaticRetry)
Future<DeckDeletionImpact> deckDeletionImpact(Ref ref, String deckId) =>
    ref.watch(getDeckDeletionImpactUseCaseProvider)(deckId);
