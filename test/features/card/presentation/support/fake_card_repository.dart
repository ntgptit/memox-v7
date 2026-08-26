import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/tag_entity.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_list_sort_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

import 'card_fixtures.dart';
import 'fake_card_bulk_repository.dart';

/// A `CardRepository` a presentation test drives by hand.
///
/// The list and count are `StreamController`s the test pushes into, so a test
/// can move the screen through loading → loaded → empty by emitting; `createCard`
/// records its arguments and either returns or throws, so a controller test can
/// check the double-submit guard and the keep-input-on-failure path without a
/// database.
final class FakeCardRepository extends FakeCardBulkRepository
    with CardFixtures
    implements CardRepository {
  FakeCardRepository();

  /// A repository whose list and count are already loaded, for a visual audit
  /// that needs the loaded frame without pumping a stream event.
  factory FakeCardRepository.loaded(
    List<CardListItemModel> items, {
    int? total,
  }) {
    final repository = FakeCardRepository();
    repository._seededItems = items;
    repository._seededCount = total ?? items.length;

    return repository;
  }

  List<CardListItemModel>? _seededItems;
  int? _seededCount;

  final StreamController<List<CardEntity>> _cards =
      StreamController<List<CardEntity>>.broadcast();
  final StreamController<List<CardListItemModel>> _items =
      StreamController<List<CardListItemModel>>.broadcast();
  final StreamController<int> _count = StreamController<int>.broadcast();

  /// Every `watchCardsByDeck` limit asked for, in order — so a test can prove a
  /// load-more grew the window.
  final List<int> requestedLimits = <int>[];

  /// Number of subscriptions to the total-count stream.
  int cardCountWatchCount = 0;

  /// Recorded create calls: (front, back, example). A double-submit guard is
  /// proven by this staying length 1.
  final List<({String front, String back, String? example})> creates =
      <({String front, String back, String? example})>[];

  /// When set, the next `createCard` throws it instead of returning.
  Failure? nextCreateFailure;

  /// A gate that holds `createCard` open until released, so a test can assert
  /// the in-flight state and fire a second submit while the first is pending.
  Completer<void>? createGate;

  /// The same, for `updateCard`.
  ///
  /// Added when the editor grew an exit guard and two Save affordances:
  /// "leaving is inert while a save is in flight" and "only the footer shows a
  /// spinner" both need a save that stays in flight, and the missing gate is
  /// why neither had a test.
  Completer<void>? updateGate;

  void emitCards(List<CardEntity> cards) => _cards.add(cards);

  /// Pushes a list frame into the management-list stream (the read the list
  /// screen actually subscribes to).
  void emitItems(List<CardListItemModel> items) => _items.add(items);

  void emitCount(int count) => _count.add(count);

  /// Errors the management-list stream — the list screen's error path.
  void emitError(Object error) => _items.addError(error);

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) {
    requestedLimits.add(limit);
    return _cards.stream;
  }

  /// Every filter the list read was asked for, in order — so a test can prove a
  /// pill selection changed the query.
  final List<CardListFilter> requestedFilters = <CardListFilter>[];

  /// Per-filter pill counts a test can set; all-filter uses the count stream.
  final Map<CardListFilter, int> filterCounts = <CardListFilter, int>{};

  /// What a tag-filtered count answers, keyed by how many tags are selected.
  ///
  /// **Present so a render can be honest about it.** Without it the fake
  /// returns the deck total whatever the tag selection is, so a golden staged
  /// to show "Apply · N cards" (M4.14 T6) shows the deck's 128 and proves
  /// nothing about the feature it was made to illustrate.
  final Map<int, int> tagFilterCounts = <int, int>{};

  /// Every sort the list read was asked for, in order — so a test can prove the
  /// sort control changed the query.
  final List<CardListSort> requestedSorts = <CardListSort>[];

  /// Every search term the list read was asked for — the parameter a use case
  /// once accepted and silently dropped, which is why it is recorded here.
  final List<String?> requestedSearchTerms = <String?>[];

  /// Every tag selection the list read was asked for — recorded for the same
  /// reason the search term is: a parameter that reaches the repository is the
  /// only proof the screen's filter actually narrows the read (BR-231).
  final List<TagFilter> requestedTagFilters = <TagFilter>[];

  /// The tag selections the **count** read was asked for. Kept apart from the
  /// list's: the two are separate statements, and the defect worth catching is
  /// exactly one of them being told about the filter.
  final List<TagFilter> requestedCountTagFilters = <TagFilter>[];

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
    requestedLimits.add(limit);
    requestedFilters.add(filter);
    requestedSorts.add(sort);
    requestedSearchTerms.add(searchTerm);
    requestedTagFilters.add(tags);
    final seeded = _seededItems;
    if (seeded != null) {
      return Stream<List<CardListItemModel>>.value(seeded);
    }

    return _items.stream;
  }

  @override
  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    requestedCountTagFilters.add(tags);
    final tagged = tagFilterCounts[tags.length];
    if (tags.isActive && tagged != null) return Stream<int>.value(tagged);
    if (filter == CardListFilter.all) return watchCardCountByDeck(deckId);

    return Stream<int>.value(filterCounts[filter] ?? 0);
  }

  @override
  Stream<int> watchCardCountByDeck(String deckId) {
    cardCountWatchCount++;
    final seeded = _seededCount;
    if (seeded != null) return Stream<int>.value(seeded);

    return _count.stream;
  }

  /// The deck distribution the progress panel shows; null renders no panel.
  CardStateDistributionModel? distributionToShow;

  @override
  Stream<CardStateDistributionModel> watchCardStateDistribution(String deckId) {
    final seeded = distributionToShow;
    if (seeded == null) {
      return const Stream<CardStateDistributionModel>.empty();
    }

    return Stream<CardStateDistributionModel>.value(seeded);
  }

  /// The deck context the header shows; null emits nothing so the title falls
  /// back to the generic label.
  DeckContextModel? deckContextToShow;

  /// What the router's auto-forward reads; a test sets it to prove the redirect.
  bool holdsCards = false;

  @override
  Stream<DeckContextModel> watchDeckContext(String deckId) {
    final seeded = deckContextToShow;
    if (seeded == null) return const Stream<DeckContextModel>.empty();

    return Stream<DeckContextModel>.value(seeded);
  }

  @override
  Future<bool> readDeckHoldsCards(String deckId) async => holdsCards;

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) async {
    creates.add((
      front: front.value,
      back: back.value,
      example: example?.value,
    ));
    if (createGate != null) await createGate!.future;
    final failure = nextCreateFailure;
    if (failure != null) throw failure;

    return card('created', front: front.value, back: back.value);
  }

  /// The card the editor loads in edit mode; set by a test opening the editor.
  CardEntity? cardToGet;

  /// Recorded update calls: (cardId, front, back, example).
  final List<({String id, String front, String back, String? example})>
  updates = <({String id, String front, String back, String? example})>[];

  /// Recorded deletes.
  final List<String> deletes = <String>[];

  /// When set, the next `getCard` throws it — the edit prefill's failure path.
  Failure? nextGetFailure;

  @override
  Future<CardEntity> getCard(String cardId) async {
    final failure = nextGetFailure;
    if (failure != null) throw failure;
    final seeded = cardToGet;
    if (seeded != null) return seeded;

    return card(cardId);
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
    updates.add((
      id: cardId,
      front: front.value,
      back: back.value,
      example: example?.value,
    ));
    if (updateGate != null) await updateGate!.future;
    final failure = nextCreateFailure;
    if (failure != null) throw failure;

    return card(cardId, front: front.value, back: back.value);
  }

  @override
  Future<void> deleteCard(String cardId) async {
    deletes.add(cardId);
    final failure = nextCreateFailure;
    if (failure != null) throw failure;
  }

  /// Batch ids handed back by the Undo-aware delete, one per card (BR-256).
  /// Derived from the id so a test can assert which card a batch belongs to
  /// without the fake keeping a second map in step with `deletes`.
  @override
  Future<String> deleteCardForUndo(String cardId) async {
    await deleteCard(cardId);

    return 'batch-$cardId';
  }

  @override
  Future<List<String>> deleteCardsForUndo(List<String> cardIds) async {
    final batchIds = <String>[];
    for (final cardId in cardIds) {
      batchIds.add(await deleteCardForUndo(cardId));
    }

    return batchIds;
  }

  /// Recorded flag writes: (cardId, isFlagged).
  final List<({String id, bool isFlagged})> flagWrites =
      <({String id, bool isFlagged})>[];

  /// When set, the next `setCardFlag` throws it — the optimistic-revert path.
  Failure? nextFlagFailure;

  final StreamController<bool> _flag = StreamController<bool>.broadcast();
  bool? _currentFlag;

  @override
  Stream<bool> watchCardFlag(String cardId) async* {
    // The current mark first (from the seeded card, if any), then every change.
    yield _currentFlag ?? cardToGet?.isFlagged ?? false;
    yield* _flag.stream;
  }

  @override
  Future<void> setCardFlag({
    required String cardId,
    required bool isFlagged,
  }) async {
    final failure = nextFlagFailure;
    if (failure != null) throw failure;
    flagWrites.add((id: cardId, isFlagged: isFlagged));
    _currentFlag = isFlagged;
    _flag.add(isFlagged);
  }

  // ---- tags --------------------------------------------------------------

  final StreamController<List<TagEntity>> _tags =
      StreamController<List<TagEntity>>.broadcast();

  /// Recorded add-tag calls: (cardId, rawName). The use case has already parsed,
  /// so this holds the display value.
  final List<({String id, String name})> tagAdds =
      <({String id, String name})>[];

  /// Recorded remove-tag calls: (cardId, tagId).
  final List<({String id, String tagId})> tagRemoves =
      <({String id, String tagId})>[];

  /// When set, the next `addCardTag` throws it — e.g. the BR-94 tooManyTags path.
  Failure? nextTagFailure;

  /// When set, the next `removeCardTag` throws it.
  Failure? nextRemoveTagFailure;

  void emitTags(List<TagEntity> tags) => _tags.add(tags);

  TagEntity tag(String id, {required String name}) =>
      TagEntity(id: id, name: name);

  @override
  Stream<List<TagEntity>> watchCardTags(String cardId) => _tags.stream;

  @override
  Future<void> addCardTag({
    required String cardId,
    required TagName name,
  }) async {
    final failure = nextTagFailure;
    if (failure != null) throw failure;
    tagAdds.add((id: cardId, name: name.value));
  }

  @override
  Future<void> removeCardTag({
    required String cardId,
    required String tagId,
  }) async {
    final failure = nextRemoveTagFailure;
    if (failure != null) throw failure;
    tagRemoves.add((id: cardId, tagId: tagId));
  }

  void dispose() {
    unawaited(_cards.close());
    unawaited(_items.close());
    unawaited(_count.close());
    unawaited(_tags.close());
    unawaited(_flag.close());
  }
}
