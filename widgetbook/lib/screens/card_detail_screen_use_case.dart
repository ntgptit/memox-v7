import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/entities/card_study_state_entity.dart';
import 'package:memox/features/card/domain/failures/card_not_found_failure.dart';
import 'package:memox/features/card/domain/models/card_detail_model.dart';
import 'package:memox/features/card/domain/models/card_history_cursor_model.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/domain/repositories/card_detail_repository.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';
import 'package:memox/features/study/domain/models/study_mode.dart';
import 'package:memox/features/study/domain/models/study_outcome_reason_model.dart';
import 'package:widgetbook/widgetbook.dart';

/// `CardDetailScreen` mounted whole, its one contract faked (UC-19).
///
/// The scenarios are the faces of M4.15 W3 that a person should look at rather
/// than assert: a card mid-schedule with two generations of history, a brand
/// new card whose history is empty, an sm2 card whose schedule speaks a
/// different vocabulary, a long Vietnamese meaning, and the two failure faces.
/// Paging is live — `Load more` really fetches the next page from the fake.
WidgetbookComponent cardDetailScreenComponent() {
  return WidgetbookComponent(
    name: 'CardDetailScreen',
    useCases: <WidgetbookUseCase>[
      WidgetbookUseCase(
        name: 'Playground',
        builder: (context) {
          final scenario = context.knobs.object.dropdown<CardDetailScenario>(
            label: 'scenario',
            options: CardDetailScenario.values,
            labelBuilder: (CardDetailScenario value) => value.label,
          );

          return _CardDetailDemo(
            key: ValueKey<Object>(scenario),
            scenario: scenario,
          );
        },
      ),
    ],
  );
}

/// The faces worth staging.
enum CardDetailScenario {
  eightBox('eight_box card, two learning cycles'),
  newCard('new card, no history yet'),
  sm2('sm2 card, ease and interval'),
  longContent('very long Vietnamese meaning'),
  notFound('card deleted from another screen'),
  readError('the read failed'),

  /// The read never lands, so the whole-screen spinner holds still — the only
  /// way a person can actually look at it. The reminder and study catalogs
  /// hold their loading faces open the same way.
  loading('loading (read never lands)'),

  /// The second history page never lands, so the inline loading-more spinner
  /// holds. Scroll down and tap Load more to reach it.
  pageStalls('loading-more holds (scroll down, then Load more)'),

  /// The band at the foot of the timeline, with events already above it
  /// (UC-19 E4). Scroll to the end to reach it — the first page lands, the
  /// second refuses.
  pageFails('a history page fails to load (scroll down, then Load more)');

  const CardDetailScenario(this.label);

  final String label;
}

class _CardDetailDemo extends StatelessWidget {
  const _CardDetailDemo({required this.scenario, super.key});

  final CardDetailScenario scenario;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        cardDetailRepositoryProvider.overrideWithValue(
          _CatalogDetailRepository(scenario),
        ),
      ],
      child: const CardDetailScreen(deckId: 'deck-1', cardId: 'card-1'),
    );
  }
}

/// A repository built from a scenario, with real paging behind `Load more`.
final class _CatalogDetailRepository implements CardDetailRepository {
  _CatalogDetailRepository(this.scenario);

  final CardDetailScenario scenario;

  @override
  Stream<CardDetailModel> watchCardDetail(String cardId) {
    if (scenario == CardDetailScenario.notFound) {
      return Stream<CardDetailModel>.error(
        const NotFoundFailure(
          message: 'That card no longer exists.',
          reason: CardNotFoundReason.cardGone,
        ),
      );
    }
    if (scenario == CardDetailScenario.readError) {
      return Stream<CardDetailModel>.error(
        const DatabaseFailure(message: 'read failed'),
      );
    }

    // Not `Stream.empty()`: an empty stream closes at once, and a closed
    // stream with no value is a state Riverpod may render differently from one
    // still waiting.
    if (scenario == CardDetailScenario.loading) {
      return StreamController<CardDetailModel>().stream;
    }

    return Stream<CardDetailModel>.value(_detail());
  }

  @override
  Future<CardHistoryPageModel> loadCardHistoryPage(
    String cardId, {
    CardHistoryCursor? after,
  }) async {
    if (scenario == CardDetailScenario.newCard) {
      return CardHistoryPageModel.empty;
    }
    // **The second page refuses, not the first.** The band this opens sits at
    // the foot of a timeline with events already above it (UC-19 E4), and a
    // first-page failure would show the screen's whole-body error face
    // instead — a different state, already staged.
    if (scenario == CardDetailScenario.pageFails && after != null) {
      throw const DatabaseFailure(message: 'catalog: page refused');
    }
    // Held open rather than failed: the face under review is the inline
    // spinner itself, which only exists while the request is in flight.
    if (scenario == CardDetailScenario.pageStalls && after != null) {
      return Completer<CardHistoryPageModel>().future;
    }
    // A first page that says there is more, then a shorter second page — so
    // the catalog shows the load-more tail and the completion line in turn.
    final isSecond = after != null;
    final events = <CardHistoryEventModel>[
      for (var index = 0; index < (isSecond ? 2 : 4); index++)
        _event(index: index, isSecond: isSecond),
    ];

    return CardHistoryPageModel(
      events: events,
      hasMore: !isSecond,
      nextCursor: isSecond ? null : events.last.cursor,
    );
  }

  CardDetailModel _detail() {
    final isSm2 = scenario == CardDetailScenario.sm2;
    final isNew = scenario == CardDetailScenario.newCard;

    return CardDetailModel(
      card: CardEntity(
        id: 'card-1',
        deckId: 'deck-1',
        front: '안녕하세요',
        back: scenario == CardDetailScenario.longContent
            ? 'xin chào — một lời chào lịch sự dùng với người lớn tuổi hơn '
                  'hoặc người mới gặp lần đầu, và cũng là câu mở đầu chuẩn '
                  'trong hầu hết các tình huống trang trọng'
            : 'hello / xin chào',
        isFlagged: scenario == CardDetailScenario.eightBox,
        example: '안녕하세요, 만나서 반갑습니다',
        hint: isNew ? null : 'a polite greeting',
        pronunciation: 'annyeonghaseyo',
        createdAt: _now,
        updatedAt: _now,
      ),
      studyState: CardStudyStateEntity(
        cardId: 'card-1',
        schedulerType: isSm2 ? SchedulerType.sm2 : SchedulerType.eightBox,
        schedulerVersion: 1,
        schedulerGeneration: isNew ? 1 : 2,
        learnedAt: isNew ? null : _now.subtract(const Duration(days: 12)),
        dueAt: isNew ? null : _now.add(const Duration(days: 2)),
        lastAnsweredAt: isNew ? null : _now.subtract(const Duration(days: 1)),
        answerCount: isNew ? 0 : 7,
        lapseCount: isNew ? 0 : 1,
        currentBox: isSm2 ? null : (isNew ? 1 : 3),
        easeFactor: isSm2 ? 2.5 : null,
        intervalDays: isSm2 ? 6 : null,
        repetitions: isSm2 ? 3 : null,
      ),
      tagNames: isNew
          ? const <String>[]
          : const <String>['greeting', 'phrase', 'topik-i'],
    );
  }

  CardHistoryEventModel _event({required int index, required bool isSecond}) {
    // The second page is the previous learning cycle, so the catalog shows the
    // generation heading that BR-243 asks to be readable without colour.
    final generation = isSecond ? 1 : 2;
    final isLearning = isSecond;
    final isSm2 = scenario == CardDetailScenario.sm2;

    return CardHistoryEventModel(
      id: 'g$generation-$index',
      answeredAt: _now.subtract(Duration(days: index + (isSecond ? 30 : 1))),
      schedulerType: isSm2 ? SchedulerType.sm2 : SchedulerType.eightBox,
      schedulerGeneration: generation,
      kind: isLearning ? StudyAnswerKind.learning : StudyAnswerKind.scheduled,
      mode: isLearning ? StudyMode.fill : StudyMode.selfAssess,
      action: index.isEven ? StudyAction.remembered : StudyAction.forgotten,
      outcomeReason: index == 1 && !isLearning
          ? StudyOutcomeReason.timeout
          : null,
      usedHint: isLearning ? index.isEven : null,
      nextDueAt: isLearning ? null : _now.add(Duration(days: index + 1)),
      previousBox: isLearning || isSm2 ? null : 2,
      nextBox: isLearning || isSm2 ? null : 3,
      previousEaseFactor: isSm2 && !isLearning ? 2.5 : null,
      nextEaseFactor: isSm2 && !isLearning ? 2.6 : null,
      previousIntervalDays: isSm2 && !isLearning ? 1 : null,
      nextIntervalDays: isSm2 && !isLearning ? 6 : null,
    );
  }
}

/// A fixed instant — the catalog never reads the wall clock, so a screenshot
/// taken today and one taken next month show the same dates.
final DateTime _now = DateTime.utc(2026, 8, 14, 9, 41);
