import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';

/// The bulk half of the card fake (BR-165, BR-166, BR-167).
///
/// **A base class, not a part.** The methods are interface implementations, so
/// they have to live on the type; a `part` cannot add members to a class. The
/// split is at the file-size guard and the seam is honest: everything here
/// serves a selection, while the subclass serves one card at a time.
///
/// No `@override` here: this class does not itself implement `CardRepository`,
/// so the annotation would be a claim the analyzer rejects. The subclass is
/// where the contract is declared, and it is what checks these signatures.
abstract class FakeCardBulkRepository {
  /// Recorded bulk moves: (cardIds, targetDeckId).
  final List<({List<String> cardIds, String targetDeckId})> moves =
      <({List<String> cardIds, String targetDeckId})>[];

  /// Recorded bulk deletes, flag writes and tag adds.
  final List<List<String>> bulkDeletes = <List<String>>[];
  final List<({List<String> cardIds, bool isFlagged})> bulkFlags =
      <({List<String> cardIds, bool isFlagged})>[];
  final List<({List<String> cardIds, String name})> bulkTags =
      <({List<String> cardIds, String name})>[];

  /// Thrown by the next bulk mutation, so a test can drive the failure path.
  Failure? nextBulkFailure;

  /// What `readCardIdsMatching` answers: deliberately larger than the loaded
  /// window in the tests that matter (BR-167).
  List<String> idsMatching = <String>[];

  /// Every `readCardIdsMatching` call — Select all's proof that it used the
  /// live filter and search rather than the loaded rows.
  final List<
    ({String deckId, CardListFilter filter, String? searchTerm, TagFilter tags})
  >
  idsMatchingCalls =
      <
        ({
          String deckId,
          CardListFilter filter,
          String? searchTerm,
          TagFilter tags,
        })
      >[];

  void _failBulkIfAsked() {
    final failure = nextBulkFailure;
    if (failure != null) throw failure;
  }

  Future<void> moveCards({
    required List<String> cardIds,
    required String targetDeckId,
  }) async {
    moves.add((cardIds: cardIds, targetDeckId: targetDeckId));
    _failBulkIfAsked();
  }

  Future<void> deleteCards(List<String> cardIds) async {
    bulkDeletes.add(cardIds);
    _failBulkIfAsked();
  }

  Future<void> setCardsFlag({
    required List<String> cardIds,
    required bool isFlagged,
  }) async {
    bulkFlags.add((cardIds: cardIds, isFlagged: isFlagged));
    _failBulkIfAsked();
  }

  Future<void> addTagToCards({
    required List<String> cardIds,
    required TagName name,
  }) async {
    bulkTags.add((cardIds: cardIds, name: name.value));
    _failBulkIfAsked();
  }

  Future<List<String>> readCardIdsMatching(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) async {
    idsMatchingCalls.add((
      deckId: deckId,
      filter: filter,
      searchTerm: searchTerm,
      tags: tags,
    ));

    return idsMatching;
  }

  /// The move targets the picker will show (BR-165).
  List<CardMoveTarget> moveTargets = <CardMoveTarget>[];

  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) =>
      Stream<List<CardMoveTarget>>.value(moveTargets);
}
