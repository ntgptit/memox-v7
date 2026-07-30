import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/di/deck_repository_provider.dart';
import '../../../../core/state/retry_policy.dart';
import '../../domain/models/deck_deletion_impact_model.dart';
import '../../domain/entities/deck_entity.dart';

part 'deck_detail_controller.freezed.dart';
part 'deck_detail_controller.g.dart';

/// One deck plus the children it is allowed to show (UC-06 step 4, UC-08).
///
/// Both facts arrive together because every action on the screen needs both: the
/// action set comes from the deck's `content_type`, and whether reset is
/// available comes from the children being empty. Two separate providers would
/// let the screen render an action matrix computed from a deck and a child list
/// captured at different instants.
@freezed
abstract class DeckDetail with _$DeckDetail {
  const factory DeckDetail({
    required DeckEntity deck,
    required List<DeckEntity> childDecks,
  }) = _DeckDetail;

  const DeckDetail._();

  /// Whether the content type can be put back to `unset` (BR-68).
  ///
  /// Direct children only, and only for a sub-deck: a root's content type is
  /// invariant (BR-58). Cards are **not** counted here — this screen does not
  /// read the card feature (M4.11 owns that), so it can only say "no child
  /// decks", and the repository is what refuses a reset on a deck that still
  /// holds cards. That is the right split: the UI offers, the repository
  /// decides.
  bool get mayOfferReset => !deck.isRoot && childDecks.isEmpty;
}

/// Watches one deck and its direct children.
///
/// `family` on the deck id, so opening a second deck does not disturb the first
/// — which matters because the shell keeps the branch alive behind a pushed
/// route.
///
/// A `NotFoundFailure` from the repository surfaces as the provider's error, and
/// the screen renders a not-found state from it rather than a database message
/// (UC-03 E1: a deck deleted on another screen must not crash this one).
/// What deleting a deck would take with it (BR-04).
///
/// A future, not a stream: the confirmation dialog is a snapshot of a decision
/// the user is about to make, and a count that changed while they read it would
/// be worse than one taken at the moment it opened. The repository is still what
/// refuses a delete that has become impossible.
@Riverpod(retry: noAutomaticRetry)
Future<DeckDeletionImpact> deckDeletionImpact(Ref ref, String deckId) =>
    ref.watch(deckRepositoryProvider).getDeletionImpact(deckId);

@Riverpod(retry: noAutomaticRetry)
Stream<DeckDetail> deckDetail(Ref ref, String deckId) {
  final repository = ref.watch(deckRepositoryProvider);

  // The children stream is the one that re-emits on every write in this
  // subtree; the deck itself is re-read on each emission so a rename made
  // elsewhere shows up without a second subscription.
  return repository
      .watchChildDecks(deckId)
      .asyncMap(
        (children) async => DeckDetail(
          deck: await repository.getDeckById(deckId),
          childDecks: children,
        ),
      );
}
