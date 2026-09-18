import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/card_study_state_entity.dart';
import 'package:memox/features/card/domain/entities/tag_entity.dart';
import 'package:memox/features/card/domain/models/card_list_filter_model.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_list_sort_model.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/models/card_state_distribution_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/card/domain/models/card_text_model.dart';
import 'package:memox/features/card/domain/models/deck_context_model.dart';
import 'package:memox/features/card/domain/models/tag_filter_model.dart';
import 'package:memox/features/card/domain/models/tag_name_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// The faces of the card list worth staging (UC-04, M4.11 W1…W4).
enum CardListScenario {
  deck('a deck of 8 cards, all four states'),
  empty('empty deck, nothing added yet'),
  longContent('long Vietnamese content and many tags'),
  oneCard('a single card'),
  error('the read failed'),

  /// The read never lands, so the whole-screen spinner holds still. The detail
  /// and study catalogs hold their loading faces open the same way.
  loading('loading (read never lands)');

  const CardListScenario(this.label);

  final String label;
}

/// One deck's cards, faked, with the list rules re-implemented rather than
/// stubbed — the same choice `TagCatalogFake` makes and for the same reason.
///
/// The filter pills, the search field, the sort and the tag filter are the
/// screen's most-used controls, and a fake that returned one fixed list would
/// show them working while proving nothing. Here they really narrow the rows,
/// and the bulk actions (flag, delete, move, add tag) really change the store
/// and re-emit — so the selection bar, the counter line and the empty faces can
/// all be reached by using the screen instead of by switching scenarios.
///
/// **Tag ids are tag names here.** `TagFilter` selects by id while a row
/// carries only names (`CardListItemModel.tagNames`), and the catalog has no
/// separate tag table to join them through, so the fake makes them the same
/// string. Nothing on this screen can tell the difference; the tag *catalog*
/// screen, which does care, has its own fake.
final class CardListCatalogRepository implements CardRepository {
  CardListCatalogRepository(this.scenario)
    : _rows = <CardListItemModel>[..._seedFor(scenario)];

  final CardListScenario scenario;

  final List<CardListItemModel> _rows;

  /// Broadcast, and it carries no payload: every read below re-derives its own
  /// answer from `_rows`, so one tick is enough to move the list, all four
  /// counts and the deck total together — which is what makes them agree in the
  /// frame after a bulk write.
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// A read that answers now and again after every write.
  ///
  /// The two non-scenarios come first: `error` is the screen's body error face,
  /// and `loading` is a stream that never yields — not `Stream.empty()`, which
  /// closes at once, and a closed stream with no value is a state Riverpod may
  /// render differently from one still waiting.
  Stream<T> _live<T>(T Function() read) {
    if (scenario == CardListScenario.error) {
      return Stream<T>.error(const DatabaseFailure(message: 'read failed'));
    }
    if (scenario == CardListScenario.loading) {
      return StreamController<T>().stream;
    }

    return Stream<T>.multi((StreamController<T> controller) {
      controller.add(read());
      final StreamSubscription<void> sub = _changes.stream.listen(
        (_) => controller.add(read()),
      );
      controller.onCancel = sub.cancel;
    });
  }

  List<CardListItemModel> _select({
    required CardListFilter filter,
    required CardListSort sort,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    final String query = (searchTerm ?? '').trim().toLowerCase();
    final DateTime at = now ?? _now;

    final List<CardListItemModel> rows = _rows.where((CardListItemModel row) {
      final bool passesFilter = switch (filter) {
        CardListFilter.all => true,
        CardListFilter.due => row.dueAt == null || !row.dueAt!.isAfter(at),
        CardListFilter.isNew => row.state == CardState.isNew,
        CardListFilter.flagged => row.card.isFlagged,
      };
      if (!passesFilter) return false;

      if (query.isNotEmpty &&
          !row.card.front.toLowerCase().contains(query) &&
          !row.card.back.toLowerCase().contains(query)) {
        return false;
      }

      if (tags.isActive && !row.tagNames.any(tags.contains)) return false;

      return true;
    }).toList();

    // A card with no `due_at` is new and due immediately, so it sorts to the
    // front — the same NULLs-first order SQLite already gives `dueFirst`.
    rows.sort(
      (CardListItemModel a, CardListItemModel b) => switch (sort) {
        CardListSort.newest => b.card.createdAt.compareTo(a.card.createdAt),
        CardListSort.dueFirst => (a.dueAt ?? _epoch).compareTo(
          b.dueAt ?? _epoch,
        ),
      },
    );

    return rows;
  }

  int _indexOf(String cardId) =>
      _rows.indexWhere((CardListItemModel row) => row.card.id == cardId);

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
    return _live<List<CardListItemModel>>(
      () => _select(
        filter: filter,
        sort: sort,
        searchTerm: searchTerm,
        now: now,
        tags: tags,
      ).take(limit).toList(),
    );
  }

  @override
  Stream<int> watchFilteredCardCount(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) {
    return _live<int>(
      () => _select(
        filter: filter,
        sort: CardListSort.newest,
        searchTerm: searchTerm,
        now: now,
        tags: tags,
      ).length,
    );
  }

  @override
  Stream<int> watchCardCountByDeck(String deckId) =>
      _live<int>(() => _rows.length);

  @override
  Stream<DeckContextModel> watchDeckContext(String deckId) {
    return _live<DeckContextModel>(
      () => const DeckContextModel(
        deckName: 'Sơ cấp 1',
        ancestors: <DeckBreadcrumbSegment>[
          DeckBreadcrumbSegment(id: 'root', name: 'Tiếng Hàn'),
          DeckBreadcrumbSegment(id: 'unit', name: 'Bài 3 · Chào hỏi'),
        ],
      ),
    );
  }

  @override
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId) {
    return _live<List<CardMoveTarget>>(
      () => const <CardMoveTarget>[
        CardMoveTarget(
          deckId: 'deck-2',
          name: 'Sơ cấp 2',
          parentName: 'Tiếng Hàn',
        ),
        CardMoveTarget(
          deckId: 'deck-3',
          name: 'Ôn tập',
          parentName: 'Bài 3 · Chào hỏi',
        ),
      ],
    );
  }

  @override
  Future<List<String>> readCardIdsMatching(
    String deckId, {
    CardListFilter filter = CardListFilter.all,
    String? searchTerm,
    DateTime? now,
    TagFilter tags = TagFilter.none,
  }) async {
    // Select-all takes the whole filtered result, not the loaded window
    // (BR-167) — so this deliberately does not apply `limit`.
    return _select(
      filter: filter,
      sort: CardListSort.newest,
      searchTerm: searchTerm,
      now: now,
      tags: tags,
    ).map((CardListItemModel row) => row.card.id).toList();
  }

  @override
  Future<void> setCardsFlag({
    required List<String> cardIds,
    required bool isFlagged,
  }) async {
    for (final String id in cardIds) {
      final int index = _indexOf(id);
      if (index < 0) continue;
      final CardListItemModel row = _rows[index];
      _rows[index] = CardListItemModel(
        card: row.card.copyWith(isFlagged: isFlagged),
        studyState: row.studyState,
        tagNames: row.tagNames,
      );
    }
    _changes.add(null);
  }

  @override
  Future<void> addTagToCards({
    required List<String> cardIds,
    required TagName name,
  }) async {
    for (final String id in cardIds) {
      final int index = _indexOf(id);
      if (index < 0) continue;
      final CardListItemModel row = _rows[index];
      if (row.tagNames.contains(name.value)) continue;
      _rows[index] = CardListItemModel(
        card: row.card,
        studyState: row.studyState,
        tagNames: <String>[...row.tagNames, name.value],
      );
    }
    _changes.add(null);
  }

  /// All-or-nothing, like the real one (BR-166): the rows go in one pass and
  /// one tick, so the list never renders half a batch.
  @override
  Future<void> deleteCards(List<String> cardIds) async {
    _rows.removeWhere((CardListItemModel row) => cardIds.contains(row.card.id));
    _changes.add(null);
  }

  /// A move out of this deck, so from here it reads as a removal.
  @override
  Future<void> moveCards({
    required List<String> cardIds,
    required String targetDeckId,
  }) => deleteCards(cardIds);

  // ── Not reachable from this screen ───────────────────────────────────────
  // The card list never calls these: they belong to the editor, the detail
  // screen, the tag catalog and Trash, each of which has its own use-case and
  // its own fake. Throwing names the mistake at the call site instead of
  // returning a plausible empty answer that would quietly pass for data.

  Never _elsewhere(String member) => throw UnsupportedError(
    'CardListCatalogRepository does not serve $member',
  );

  @override
  Stream<List<CardEntity>> watchCardsByDeck(
    String deckId, {
    required int limit,
  }) => _elsewhere('watchCardsByDeck');

  @override
  Stream<CardStateDistributionModel> watchCardStateDistribution(
    String deckId,
  ) => _elsewhere('watchCardStateDistribution');

  @override
  Future<bool> readDeckHoldsCards(String deckId) =>
      _elsewhere('readDeckHoldsCards');

  @override
  Future<CardEntity> createCard({
    required String deckId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) => _elsewhere('createCard');

  @override
  Future<CardEntity> getCard(String cardId) => _elsewhere('getCard');

  @override
  Future<CardEntity> updateCard({
    required String cardId,
    required CardText front,
    required CardText back,
    CardDetailText? example,
    CardDetailText? hint,
    CardDetailText? pronunciation,
  }) => _elsewhere('updateCard');

  @override
  Future<void> deleteCard(String cardId) => _elsewhere('deleteCard');

  @override
  Future<String> deleteCardForUndo(String cardId) =>
      _elsewhere('deleteCardForUndo');

  @override
  Future<List<String>> deleteCardsForUndo(List<String> cardIds) =>
      _elsewhere('deleteCardsForUndo');

  @override
  Future<void> setCardFlag({required String cardId, required bool isFlagged}) =>
      _elsewhere('setCardFlag');

  @override
  Stream<bool> watchCardFlag(String cardId) => _elsewhere('watchCardFlag');

  @override
  Stream<List<TagEntity>> watchCardTags(String cardId) =>
      _elsewhere('watchCardTags');

  @override
  Future<void> addCardTag({required String cardId, required TagName name}) =>
      _elsewhere('addCardTag');

  @override
  Future<void> removeCardTag({required String cardId, required String tagId}) =>
      _elsewhere('removeCardTag');
}

/// A fixed instant — the catalog never reads the wall clock, so a screenshot
/// taken today and one taken next month show the same due labels.
final DateTime _now = DateTime.utc(2026, 8, 14, 9, 41);

/// Sorts a card with no `due_at` to the front of `dueFirst`.
final DateTime _epoch = DateTime.utc(1970);

List<CardListItemModel> _seedFor(CardListScenario scenario) {
  return switch (scenario) {
    CardListScenario.empty ||
    CardListScenario.error ||
    CardListScenario.loading => const <CardListItemModel>[],
    CardListScenario.oneCard => <CardListItemModel>[_deckSeed().first],
    CardListScenario.longContent => _longSeed(),
    CardListScenario.deck => _deckSeed(),
  };
}

/// Eight cards spread across the four display states (BR-89…BR-91), two
/// flagged and three tagged — enough for every filter pill to return a
/// different list and for the counter line to say something other than "8 of 8".
List<CardListItemModel> _deckSeed() {
  return <CardListItemModel>[
    _row(
      index: 0,
      front: '안녕하세요',
      back: 'xin chào',
      box: null,
      dueInDays: null,
      isFlagged: true,
      tagNames: <String>['greeting', 'topik-i'],
    ),
    _row(index: 1, front: '감사합니다', back: 'cảm ơn', box: null, dueInDays: null),
    _row(
      index: 2,
      front: '죄송합니다',
      back: 'xin lỗi',
      box: 2,
      dueInDays: -1,
      tagNames: <String>['greeting'],
    ),
    _row(index: 3, front: '괜찮아요', back: 'không sao', box: 2, dueInDays: 4),
    _row(
      index: 4,
      front: '어디예요?',
      back: 'ở đâu vậy?',
      box: 5,
      dueInDays: 9,
      isFlagged: true,
    ),
    _row(
      index: 5,
      front: '얼마예요?',
      back: 'bao nhiêu tiền?',
      box: 5,
      dueInDays: 12,
    ),
    _row(
      index: 6,
      front: '주세요',
      back: 'cho tôi xin',
      box: 8,
      dueInDays: 40,
      tagNames: <String>['phrase'],
    ),
    _row(index: 7, front: '맛있어요', back: 'ngon quá', box: 8, dueInDays: 63),
  ];
}

/// The wrapping case: content long enough to clip, and a tag strip long enough
/// to overflow its row.
List<CardListItemModel> _longSeed() {
  return <CardListItemModel>[
    _row(
      index: 0,
      front: '안녕하세요, 만나서 반갑습니다',
      back:
          'xin chào — một lời chào lịch sự dùng với người lớn tuổi hơn hoặc '
          'người mới gặp lần đầu, và cũng là câu mở đầu chuẩn trong hầu hết '
          'các tình huống trang trọng',
      box: 3,
      dueInDays: 2,
      isFlagged: true,
      tagNames: <String>['greeting', 'phrase', 'topik-i', 'trang-trọng'],
    ),
    _row(
      index: 1,
      front: '정말 죄송합니다만 다시 한번 말씀해 주시겠어요?',
      back:
          'thành thật xin lỗi, nhưng anh/chị có thể nói lại một lần nữa được '
          'không ạ?',
      box: null,
      dueInDays: null,
      tagNames: <String>['phrase', 'lịch-sự'],
    ),
  ];
}

CardListItemModel _row({
  required int index,
  required String front,
  required String back,
  required int? box,
  required int? dueInDays,
  bool isFlagged = false,
  List<String> tagNames = const <String>[],
}) {
  final DateTime created = _now.subtract(Duration(days: index + 1));

  return CardListItemModel(
    card: CardEntity(
      id: 'card-$index',
      deckId: 'deck-1',
      front: front,
      back: back,
      isFlagged: isFlagged,
      example: null,
      hint: null,
      pronunciation: null,
      createdAt: created,
      updatedAt: created,
    ),
    studyState: CardStudyStateEntity(
      cardId: 'card-$index',
      schedulerType: SchedulerType.eightBox,
      schedulerVersion: 1,
      schedulerGeneration: 1,
      learnedAt: box == null ? null : created,
      dueAt: dueInDays == null ? null : _now.add(Duration(days: dueInDays)),
      lastAnsweredAt: box == null ? null : created,
      answerCount: box ?? 0,
      lapseCount: 0,
      currentBox: box,
      easeFactor: null,
      intervalDays: null,
      repetitions: null,
    ),
    tagNames: tagNames,
  );
}
