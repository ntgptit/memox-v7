import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// A `CardRepository` a presentation test drives by hand.
///
/// The list and count are `StreamController`s the test pushes into, so a test
/// can move the screen through loading → loaded → empty by emitting; `createCard`
/// records its arguments and either returns or throws, so a controller test can
/// check the double-submit guard and the keep-input-on-failure path without a
/// database.
final class FakeCardRepository implements CardRepository {
  FakeCardRepository();

  /// A repository whose list and count are already loaded, for a visual audit
  /// that needs the loaded frame without pumping a stream event.
  factory FakeCardRepository.loaded(List<CardEntity> cards, {int? total}) {
    final repository = FakeCardRepository();
    repository._seededCards = cards;
    repository._seededCount = total ?? cards.length;

    return repository;
  }

  List<CardEntity>? _seededCards;
  int? _seededCount;

  final StreamController<List<CardEntity>> _cards =
      StreamController<List<CardEntity>>.broadcast();
  final StreamController<int> _count = StreamController<int>.broadcast();

  /// Every `watchCardsByDeck` limit asked for, in order — so a test can prove a
  /// load-more grew the window.
  final List<int> requestedLimits = <int>[];

  /// Recorded create calls: (front, back). A double-submit guard is proven by
  /// this staying length 1.
  final List<({String front, String back})> creates =
      <({String front, String back})>[];

  /// When set, the next `createCard` throws it instead of returning.
  Failure? nextCreateFailure;

  /// A gate that holds `createCard` open until released, so a test can assert
  /// the in-flight state and fire a second submit while the first is pending.
  Completer<void>? createGate;

  void emitCards(List<CardEntity> cards) => _cards.add(cards);

  void emitCount(int count) => _count.add(count);

  void emitError(Object error) => _cards.addError(error);

  CardEntity card(
    String id, {
    String front = 'front',
    String back = 'back',
    bool isFlagged = false,
  }) => CardEntity(
    id: id,
    deckId: 'deck-1',
    front: front,
    back: back,
    isFlagged: isFlagged,
    example: null,
    hint: null,
    pronunciation: null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) {
    requestedLimits.add(limit);
    final seeded = _seededCards;
    if (seeded != null) {
      return Stream<List<CardEntity>>.value(seeded);
    }

    return _cards.stream;
  }

  @override
  Stream<int> watchCardCountByDeck(String deckId) {
    final seeded = _seededCount;
    if (seeded != null) return Stream<int>.value(seeded);

    return _count.stream;
  }

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
  }) async {
    creates.add((front: front.value, back: back.value));
    if (createGate != null) await createGate!.future;
    final failure = nextCreateFailure;
    if (failure != null) throw failure;

    return card('created', front: front.value, back: back.value);
  }

  /// The card the editor loads in edit mode; set by a test opening the editor.
  CardEntity? cardToGet;

  /// Recorded update calls: (cardId, front, back).
  final List<({String id, String front, String back})> updates =
      <({String id, String front, String back})>[];

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
  }) async {
    updates.add((id: cardId, front: front.value, back: back.value));
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

  /// Recorded flag writes: (cardId, isFlagged).
  final List<({String id, bool isFlagged})> flagWrites =
      <({String id, bool isFlagged})>[];

  /// When set, the next `setCardFlag` throws it — the optimistic-revert path.
  Failure? nextFlagFailure;

  @override
  Future<void> setCardFlag({
    required String cardId,
    required bool isFlagged,
  }) async {
    final failure = nextFlagFailure;
    if (failure != null) throw failure;
    flagWrites.add((id: cardId, isFlagged: isFlagged));
  }

  void dispose() {
    unawaited(_cards.close());
    unawaited(_count.close());
  }
}
