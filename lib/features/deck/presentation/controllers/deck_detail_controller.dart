import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/state/retry_policy.dart';
import '../../domain/models/deck_deletion_impact_model.dart';
import '../../domain/models/deck_detail_model.dart';
import '../providers/deck_use_case_provider.dart';

part 'deck_detail_controller.g.dart';

/// What deleting a deck would take with it (BR-04).
///
/// A future, not a stream: the confirmation dialog is a snapshot of a decision
/// the user is about to make, and a count that changed while they read it would
/// be worse than one taken at the moment it opened. The repository is still what
/// refuses a delete that has become impossible.
@Riverpod(retry: noAutomaticRetry)
Future<DeckDeletionImpact> deckDeletionImpact(Ref ref, String deckId) =>
    ref.watch(getDeckDeletionImpactUseCaseProvider)(deckId);

/// Watches one deck and its direct children.
///
/// **One use case, one read, one snapshot.** This provider used to compose two
/// use cases — watch the children, then ask for the deck per emission — and a
/// comment here claimed the two facts "arrive together". They did not: they were
/// two statements against two snapshots, so the screen could show a deck read
/// before a rename beside a child list read after it. `watchDeckDetail` is one
/// contract method backed by one statement, and the composition is gone rather
/// than moved.
///
/// `family` on the deck id, so opening a second deck does not disturb the first
/// — which matters because the shell keeps the branch alive behind a pushed
/// route.
///
/// A `NotFoundFailure` from the repository surfaces as the provider's error, and
/// the screen renders a not-found state from it rather than a database message
/// (UC-03 E1: a deck deleted on another screen must not crash this one).
@Riverpod(retry: noAutomaticRetry)
Stream<DeckDetail> deckDetail(Ref ref, String deckId) =>
    ref.watch(watchDeckDetailUseCaseProvider)(deckId);
