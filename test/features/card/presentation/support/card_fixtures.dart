import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/card_study_state_entity.dart';
import 'package:memox/features/card/domain/models/card_list_item_model.dart';
import 'package:memox/features/card/domain/models/card_state_model.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';

/// The card-shaped test data a presentation test hands to a fake.
///
/// Split out of `FakeCardRepository` when that file passed the 400-line guard,
/// and the seam is a real one: everything here builds a value, and nothing here
/// answers a repository call. A mixin rather than top-level functions so every
/// existing `fake.listItem(...)` call site keeps working unchanged.
mixin CardFixtures {
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

  /// A list item in a chosen display [state], built by handing `cardStateOf` a
  /// study state that resolves to it (BR-90/BR-91/BR-88).
  /// [dueAt] left null is a card that has never been scheduled, which is what
  /// the row draws no due badge for. A test that wants the badge has to say
  /// when — passing a date is the only way to get one.
  CardListItemModel listItem(
    String id, {
    String front = 'front',
    String back = 'back',
    bool isFlagged = false,
    CardState state = CardState.isNew,
    List<String> tagNames = const <String>[],
    DateTime? dueAt,
  }) => CardListItemModel(
    card: card(id, front: front, back: back, isFlagged: isFlagged),
    studyState: _reviewStateFor(id, state, dueAt),
    tagNames: tagNames,
  );

  CardStudyStateEntity _reviewStateFor(
    String cardId,
    CardState state,
    DateTime? dueAt,
  ) {
    // eight_box only — enough to place the card in each display band. `isNew`
    // is `learned_at IS NULL` (BR-90); the rest pick a box on BR-91's ladder.
    final (int answerCount, int box) = switch (state) {
      CardState.isNew => (0, 1),
      CardState.beginning => (3, 2),
      CardState.reviewing => (6, 5),
      CardState.mastered => (12, kMasteredBox),
    };

    return CardStudyStateEntity(
      cardId: cardId,
      schedulerType: SchedulerType.eightBox,
      schedulerVersion: 1,
      schedulerGeneration: 1,
      learnedAt: state == CardState.isNew ? null : DateTime.utc(2026),
      dueAt: dueAt,
      lastAnsweredAt: null,
      answerCount: answerCount,
      lapseCount: 0,
      currentBox: box,
      easeFactor: null,
      intervalDays: null,
      repetitions: null,
    );
  }
}
