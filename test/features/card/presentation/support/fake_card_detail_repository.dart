import 'dart:async';

import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/card_study_state_entity.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_history_cursor_model.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/domain/repositories/card_detail_repository.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';

/// A `CardDetailRepository` a presentation test drives by hand.
///
/// **Two methods to fake, which is the return on splitting the contract.** The
/// management contract has twenty-six, and a read-only screen is forbidden to
/// call twenty-four of them (BR-239) — faking those would be stubbing behaviour
/// the subject cannot reach.
///
/// The detail is a `StreamController` a test pushes into, so a screen can be
/// walked through loading → loaded → gone by emitting. Every history request is
/// recorded and answered from a queue, so a test can prove which cursor was
/// asked for and can hold two requests in flight at once.
final class FakeCardDetailRepository implements CardDetailRepository {
  final StreamController<CardDetailModel> _detail =
      StreamController<CardDetailModel>.broadcast();

  /// Seeded value, replayed to every subscriber — for a widget test that wants
  /// the loaded frame without pumping an event.
  CardDetailModel? seededDetail;

  /// Every cursor asked for, in order. `null` is the first page, so this is
  /// also the record of how many pages were requested.
  final List<CardHistoryCursor?> requestedCursors = <CardHistoryCursor?>[];

  /// Pages handed back in order; the last one is reused once the queue runs
  /// dry, so a test only queues the pages it cares about.
  final List<CardHistoryPageModel> pages = <CardHistoryPageModel>[];

  /// When set, the next history request throws it instead of returning.
  ///
  /// Typed as [Failure] rather than [Object]: the repository maps every Drift
  /// exception at its boundary, so a failure reaching a controller is always
  /// one of these — and a fake able to throw a raw `Object` would let a test
  /// prove behaviour against input production cannot produce.
  Failure? nextHistoryFailure;

  /// Holds the next history request open until completed, so a test can assert
  /// the in-flight state and fire a second request while the first is pending.
  Completer<void>? historyGate;

  void emitDetail(CardDetailModel detail) => _detail.add(detail);

  void emitDetailError(Object error) => _detail.addError(error);

  @override
  Stream<CardDetailModel> watchCardDetail(String cardId) {
    final seeded = seededDetail;
    if (seeded == null) return _detail.stream;

    // Seeded first, then whatever the test pushes — so a widget test gets the
    // loaded frame on the first pump and can still drive the card to gone.
    return Stream<CardDetailModel>.multi((listener) {
      listener.add(seeded);
      final subscription = _detail.stream.listen(
        listener.add,
        onError: listener.addError,
      );
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Future<CardHistoryPageModel> loadCardHistoryPage(
    String cardId, {
    CardHistoryCursor? after,
  }) async {
    requestedCursors.add(after);
    final gate = historyGate;
    if (gate != null) await gate.future;

    final failure = nextHistoryFailure;
    if (failure != null) {
      nextHistoryFailure = null;
      throw failure;
    }
    if (pages.isEmpty) return CardHistoryPageModel.empty;
    if (pages.length == 1) return pages.first;

    return pages.removeAt(0);
  }
}

/// A card whose content is under the test's control and whose schedule is the
/// one BR-09 gives a new card.
CardDetailModel fakeCardDetail({
  String id = 'card-1',
  String front = 'front',
  String back = 'back',
  String? example,
  String? hint,
  String? pronunciation,
  bool isFlagged = false,
  List<String> tagNames = const <String>[],
  SchedulerType schedulerType = SchedulerType.eightBox,
  DateTime? dueAt,
  DateTime? learnedAt,
  DateTime? lastAnsweredAt,
  int answerCount = 0,
  int lapseCount = 0,
  int? currentBox = 1,
  double? easeFactor,
  int? intervalDays,
  int? repetitions,
}) => CardDetailModel(
  card: CardEntity(
    id: id,
    deckId: 'deck-1',
    front: front,
    back: back,
    isFlagged: isFlagged,
    example: example,
    hint: hint,
    pronunciation: pronunciation,
    createdAt: fakeNow,
    updatedAt: fakeNow,
  ),
  studyState: CardStudyStateEntity(
    cardId: id,
    schedulerType: schedulerType,
    schedulerVersion: 1,
    schedulerGeneration: 1,
    learnedAt: learnedAt,
    dueAt: dueAt,
    lastAnsweredAt: lastAnsweredAt,
    answerCount: answerCount,
    lapseCount: lapseCount,
    currentBox: currentBox,
    easeFactor: easeFactor,
    intervalDays: intervalDays,
    repetitions: repetitions,
  ),
  tagNames: tagNames,
);

/// One history event, defaulted to an `eight_box` scheduled review.
CardHistoryEventModel fakeHistoryEvent({
  required String id,
  DateTime? answeredAt,
  SchedulerType schedulerType = SchedulerType.eightBox,
  int schedulerGeneration = 1,
  StudyAnswerKind kind = StudyAnswerKind.scheduled,
  StudyMode mode = StudyMode.selfAssess,
  StudyAction action = StudyAction.remembered,
  StudyOutcomeReason? outcomeReason,
  bool? usedHint,
  DateTime? nextDueAt,
  int? previousBox = 1,
  int? nextBox = 2,
  double? previousEaseFactor,
  double? nextEaseFactor,
  int? previousIntervalDays,
  int? nextIntervalDays,
}) => CardHistoryEventModel(
  id: id,
  answeredAt: answeredAt ?? fakeNow,
  schedulerType: schedulerType,
  schedulerGeneration: schedulerGeneration,
  kind: kind,
  mode: mode,
  action: action,
  outcomeReason: outcomeReason,
  usedHint: usedHint,
  nextDueAt: nextDueAt,
  previousBox: previousBox,
  nextBox: nextBox,
  previousEaseFactor: previousEaseFactor,
  nextEaseFactor: nextEaseFactor,
  previousIntervalDays: previousIntervalDays,
  nextIntervalDays: nextIntervalDays,
);

/// A page of [count] events, ids `e-0`, `e-1`, … one minute apart descending.
CardHistoryPageModel fakeHistoryPage({
  required int count,
  String prefix = 'e',
  bool hasMore = false,
  int schedulerGeneration = 1,
}) {
  final events = <CardHistoryEventModel>[
    for (var index = 0; index < count; index++)
      fakeHistoryEvent(
        id: '$prefix-$index',
        answeredAt: fakeNow.subtract(Duration(minutes: index)),
        schedulerGeneration: schedulerGeneration,
      ),
  ];

  return CardHistoryPageModel(
    events: events,
    hasMore: hasMore,
    nextCursor: hasMore && events.isNotEmpty ? events.last.cursor : null,
  );
}

/// A fixed instant. Presentation tests never read the wall clock.
final DateTime fakeNow = DateTime.utc(2026, 8, 14, 9, 41);
