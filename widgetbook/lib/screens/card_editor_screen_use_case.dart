import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
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
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:widgetbook/widgetbook.dart';

/// `CardEditorScreen` in edit mode, mounted whole (UC-04 A1, W6b).
///
/// The scenarios are the faces of the concept a person should *look* at rather
/// than assert: a card with nothing optional, one whose details are already
/// filled so the disclosure opens itself, a card at the tag cap, and a card
/// whose deck path cannot be read.
///
/// **The fake implements the whole `CardRepository` because the screen reaches
/// four of its reads** — the card, the deck path, the tags and the flag — and a
/// narrower seam would mean inventing one for the catalog's benefit. Everything
/// the editor never calls throws, so a scenario that quietly started depending
/// on a fifth read fails loudly here instead of rendering something plausible.
WidgetbookComponent cardEditorScreenComponent() {
  return WidgetbookComponent(
    name: 'CardEditorScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Edit',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<CardEditorScenario>(
            label: 'scenario',
            options: CardEditorScenario.values,
            labelBuilder: (CardEditorScenario value) => value.label,
          );

          return ProviderScope(
            key: ValueKey<Object>(scenario),
            overrides: [
              cardRepositoryProvider.overrideWithValue(
                _EditorFake(scenario: scenario),
              ),
            ],
            child: const CardEditorScreen(deckId: 'deck-1', cardId: 'card-1'),
          );
        },
      ),
    ],
  );
}

/// The faces worth staging.
enum CardEditorScenario {
  plain('a card with no optional detail and no tags'),
  detailed('details filled, so the disclosure opens itself'),
  atCap('ten tags — the add affordance is gone'),
  deadDeck('the deck path cannot be read');

  const CardEditorScenario(this.label);

  final String label;
}

/// Reads what the editor reads, refuses everything else.
class _EditorFake implements CardRepository {
  _EditorFake({required this.scenario});

  final CardEditorScenario scenario;

  static final DateTime _at = DateTime.utc(2026, 8, 27);

  @override
  Future<CardEntity> getCard(String cardId) async => CardEntity(
    id: cardId,
    deckId: 'deck-1',
    front: '연구자',
    back: 'Researcher / Nhà nghiên cứu',
    isFlagged: false,
    example: scenario == CardEditorScenario.detailed
        ? '그는 유명한 언어학 연구자이다.'
        : null,
    hint: scenario == CardEditorScenario.detailed
        ? '연구 = research · 자 = person'
        : null,
    pronunciation: scenario == CardEditorScenario.detailed
        ? 'yeon-gu-ja'
        : null,
    createdAt: _at,
    updatedAt: _at,
  );

  @override
  Stream<DeckContextModel> watchDeckContext(String deckId) {
    if (scenario == CardEditorScenario.deadDeck) {
      return Stream<DeckContextModel>.error(StateError('deck is gone'));
    }

    return Stream<DeckContextModel>.value(
      const DeckContextModel(
        deckName: 'TOPIK II — Vocab',
        ancestors: <DeckBreadcrumbSegment>[
          DeckBreadcrumbSegment(id: 'korean', name: 'Korean'),
        ],
      ),
    );
  }

  @override
  Stream<List<TagEntity>> watchCardTags(String cardId) =>
      Stream<List<TagEntity>>.value(switch (scenario) {
        CardEditorScenario.atCap => <TagEntity>[
          for (int i = 0; i < 10; i++)
            TagEntity(id: 'tag-$i', name: 'tag ${i + 1}'),
        ],
        CardEditorScenario.detailed => const <TagEntity>[
          TagEntity(id: 't1', name: 'TOPIK II'),
          TagEntity(id: 't2', name: 'noun'),
          TagEntity(id: 't3', name: 'people'),
        ],
        _ => const <TagEntity>[],
      });

  @override
  Stream<bool> watchCardFlag(String cardId) => Stream<bool>.value(false);

  @override
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) => getCard(cardId);

  @override
  Future<void> setCardFlag({
    required String cardId,
    required bool isFlagged,
  }) async {}

  @override
  Future<void> addCardTag({
    required String cardId,
    required TagName name,
  }) async {}

  @override
  Future<void> removeCardTag({
    required String cardId,
    required String tagId,
  }) async {}

  // ---- everything the editor never reaches --------------------------------

  Never _unused() => throw UnimplementedError(
    'the card editor does not read this; the catalog fake refuses it so a '
    'scenario that starts depending on it fails here rather than rendering '
    'something plausible',
  );

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) => _unused();

  @override
  Stream<List<CardListItemModel>> watchCardListItems(
    String deckId, {
    required int limit,
    CardListFilter filter = CardListFilter.all,
    CardListSort sort = CardListSort.newest,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) => _unused();

  @override
  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) => _unused();

  @override
  Stream<CardStateDistributionModel> watchCardStateDistribution(
    String deckId,
  ) => _unused();

  @override
  Future<bool> readDeckHoldsCards(String deckId) => _unused();

  @override
  Stream<int> watchCardCountByDeck(String deckId) => _unused();

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) => _unused();

  @override
  Future<void> deleteCard(String cardId) => _unused();

  @override
  Future<String> deleteCardForUndo(String cardId) => _unused();

  @override
  Future<void> moveCards({
    required List<String> cardIds,
    required String targetDeckId,
  }) => _unused();

  @override
  Future<void> deleteCards(List<String> cardIds) => _unused();

  @override
  Future<List<String>> deleteCardsForUndo(List<String> cardIds) => _unused();

  @override
  Future<void> setCardsFlag({
    required List<String> cardIds,
    required bool isFlagged,
  }) => _unused();

  @override
  Future<void> addTagToCards({
    required List<String> cardIds,
    required TagName name,
  }) => _unused();

  @override
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) =>
      _unused();

  @override
  Future<List<String>> readCardIdsMatching(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) => _unused();

  @override
  dynamic noSuchMethod(Invocation invocation) => _unused();
}
