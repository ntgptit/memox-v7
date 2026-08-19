import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/tag_entity.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_list_sort_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// Counts what it was asked to do — nothing else. The card use-case tests are
/// about whether the repository is reached (and with what), not what it returns,
/// so the strongest assertion is a negative one: an invalid form never gets
/// here. Extracted from the test file to keep that file under the size limit.
final class CountingCardRepository implements CardRepository {
  int createCalls = 0;
  int updateCalls = 0;
  int getCalls = 0;
  final List<String> deleteCalls = <String>[];
  final List<String> watchCalls = <String>[];
  final List<int> watchLimits = <int>[];
  final List<String> countCalls = <String>[];
  CardText? lastFront;
  CardText? lastBack;
  CardDetailText? lastExample;
  final List<({String id, bool isFlagged})> flagCalls =
      <({String id, bool isFlagged})>[];
  final List<({String id, String name})> tagAddCalls =
      <({String id, String name})>[];
  final List<({String id, String tagId})> tagRemoveCalls =
      <({String id, String tagId})>[];

  CardEntity _card() => CardEntity(
    id: 'card-1',
    deckId: 'deck-1',
    front: lastFront?.value ?? '',
    back: lastBack?.value ?? '',
    isFlagged: false,
    example: null,
    hint: null,
    pronunciation: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) async {
    createCalls += 1;
    lastFront = front;
    lastBack = back;
    lastExample = example;

    return _card();
  }

  @override
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) async {
    updateCalls += 1;
    lastFront = front;
    lastBack = back;
    lastExample = example;

    return _card();
  }

  @override
  Future<CardEntity> getCard(String cardId) async {
    getCalls += 1;

    return _card();
  }

  @override
  Future<void> deleteCard(String cardId) async => deleteCalls.add(cardId);

  @override
  Future<String> deleteCardForUndo(String cardId) async {
    deleteCalls.add(cardId);

    return 'batch-$cardId';
  }

  @override
  Future<void> setCardFlag({
    required String cardId,
    required bool isFlagged,
  }) async => flagCalls.add((id: cardId, isFlagged: isFlagged));

  @override
  Stream<bool> watchCardFlag(String cardId) => const Stream<bool>.empty();

  @override
  Stream<List<TagEntity>> watchCardTags(String cardId) =>
      const Stream<List<TagEntity>>.empty();

  @override
  Future<void> addCardTag({
    required String cardId,
    required TagName name,
  }) async => tagAddCalls.add((id: cardId, name: name.value));

  @override
  Future<void> removeCardTag({
    required String cardId,
    required String tagId,
  }) async => tagRemoveCalls.add((id: cardId, tagId: tagId));

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) {
    watchCalls.add(deckId);
    watchLimits.add(limit);

    return const Stream<List<CardEntity>>.empty();
  }

  @override
  Stream<List<CardListItemModel>> watchCardListItems(
    String deckId, {
    required int limit,
    CardListFilter filter = CardListFilter.all,
    CardListSort sort = CardListSort.newest,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    watchCalls.add(deckId);
    watchLimits.add(limit);

    return const Stream<List<CardListItemModel>>.empty();
  }

  @override
  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    countCalls.add(deckId);

    return const Stream<int>.empty();
  }

  @override
  Stream<int> watchCardCountByDeck(String deckId) {
    countCalls.add(deckId);

    return const Stream<int>.empty();
  }

  @override
  Stream<CardStateDistributionModel> watchCardStateDistribution(
    String deckId,
  ) => const Stream<CardStateDistributionModel>.empty();

  @override
  Stream<DeckContextModel> watchDeckContext(String deckId) =>
      const Stream<DeckContextModel>.empty();

  @override
  Future<bool> readDeckHoldsCards(String deckId) async => false;

  // ---- bulk (BR-165, BR-166, BR-167) --------------------------------------

  final List<({List<String> cardIds, String targetDeckId})> moveCalls =
      <({List<String> cardIds, String targetDeckId})>[];
  final List<List<String>> bulkDeleteCalls = <List<String>>[];
  final List<({List<String> cardIds, bool isFlagged})> bulkFlagCalls =
      <({List<String> cardIds, bool isFlagged})>[];
  final List<({List<String> cardIds, String name})> bulkTagCalls =
      <({List<String> cardIds, String name})>[];
  final List<({String deckId, CardListFilter filter, String? searchTerm})>
  idsMatchingCalls =
      <({String deckId, CardListFilter filter, String? searchTerm})>[];
  List<String> idsMatching = const <String>[];

  @override
  Future<void> moveCards({
    required List<String> cardIds,
    required String targetDeckId,
  }) async => moveCalls.add((cardIds: cardIds, targetDeckId: targetDeckId));

  @override
  Future<void> deleteCards(List<String> cardIds) async =>
      bulkDeleteCalls.add(cardIds);

  @override
  Future<List<String>> deleteCardsForUndo(List<String> cardIds) async {
    bulkDeleteCalls.add(cardIds);

    return <String>[for (final cardId in cardIds) 'batch-$cardId'];
  }

  @override
  Future<void> setCardsFlag({
    required List<String> cardIds,
    required bool isFlagged,
  }) async => bulkFlagCalls.add((cardIds: cardIds, isFlagged: isFlagged));

  @override
  Future<void> addTagToCards({
    required List<String> cardIds,
    required TagName name,
  }) async => bulkTagCalls.add((cardIds: cardIds, name: name.value));

  @override
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
    ));

    return idsMatching;
  }

  @override
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) =>
      const Stream<List<CardMoveTarget>>.empty();
}

/// A never-read card for `catchError` returns whose type must be `CardEntity`.
CardEntity unreachableCard() => CardEntity(
  id: 'never-read',
  deckId: 'never-read',
  front: '',
  back: '',
  isFlagged: false,
  example: null,
  hint: null,
  pronunciation: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);
