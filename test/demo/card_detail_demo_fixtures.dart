import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/features/card/di/card_detail_repository_provider.dart';
import 'package:memox/features/card/domain/models/card_history_event_model.dart';
import 'package:memox/features/card/domain/models/card_history_page_model.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_action_model.dart';
import 'package:memox/features/study/domain/models/study_answer_kind_model.dart';

import '../features/card/presentation/support/fake_card_detail_repository.dart';
import '../support/study_render.dart';

/// The cards the Card Detail demo renders are drawn from.
///
/// **Shared by two files rather than copied into both.** The renders split when
/// the guard's size ceiling caught the single file; the fixtures did not, and a
/// second copy of `loaded()` is how two galleries of the same screen end up
/// describing two different cards.

FakeCardDetailRepository loaded({bool withHistory = true}) {
  final repository = FakeCardDetailRepository()
    ..seededDetail = fakeCardDetail(
      front: '사과',
      back: 'quả táo',
      example: '사과를 먹어요',
      hint: 'a fruit',
      pronunciation: 'sa-gwa',
      tagNames: <String>['noun', 'food'],
      isFlagged: true,
      currentBox: withHistory ? 2 : 1,
      learnedAt: withHistory
          ? fakeNow.subtract(const Duration(days: 12))
          : null,
      dueAt: withHistory ? fakeNow.add(const Duration(days: 2)) : null,
      lastAnsweredAt: withHistory ? fakeNow : null,
      answerCount: withHistory ? 2 : 0,
      lapseCount: withHistory ? 1 : 0,
    );
  repository.pages.add(
    withHistory
        ? CardHistoryPageModel(
            events: <CardHistoryEventModel>[
              // The newest turn: remembered, so the box goes up — which is
              // `fakeHistoryEvent`'s default 1 → 2, left unstated because the
              // analyzer rejects restating a default.
              fakeHistoryEvent(
                id: 'e1',
                nextDueAt: fakeNow.add(const Duration(days: 2)),
              ),
              fakeHistoryEvent(
                id: 'e2',
                action: StudyAction.forgotten,
                answeredAt: fakeNow.subtract(const Duration(days: 3)),
                // A forgotten turn sends the card back down the boxes. The
                // fixture used to promote it, which is the one thing the
                // colour on that row is claiming did not happen.
                previousBox: 2,
                nextBox: 1,
                nextDueAt: fakeNow.subtract(const Duration(days: 2)),
              ),
              fakeHistoryEvent(
                id: 'e3',
                kind: StudyAnswerKind.learning,
                answeredAt: fakeNow.subtract(const Duration(days: 12)),
                previousBox: null,
                nextBox: null,
              ),
            ],
            hasMore: false,
            nextCursor: null,
          )
        : CardHistoryPageModel.empty,
  );

  return repository;
}

FakeCardDetailRepository sm2() {
  final repository = FakeCardDetailRepository()
    ..seededDetail = fakeCardDetail(
      front: '사과',
      back: 'quả táo',
      schedulerType: SchedulerType.sm2,
      currentBox: null,
      easeFactor: 2.5,
      intervalDays: 6,
      repetitions: 2,
      learnedAt: fakeNow.subtract(const Duration(days: 12)),
      dueAt: fakeNow.add(const Duration(days: 6)),
      lastAnsweredAt: fakeNow,
      answerCount: 12,
      lapseCount: 2,
    )
    ..pages.add(
      CardHistoryPageModel(
        events: <CardHistoryEventModel>[
          fakeHistoryEvent(
            id: 's1',
            action: StudyAction.easy,
            previousBox: null,
            nextBox: null,
            previousEaseFactor: 2.36,
            nextEaseFactor: 2.5,
            previousIntervalDays: 3,
            nextIntervalDays: 6,
          ),
          fakeHistoryEvent(
            id: 's2',
            action: StudyAction.again,
            previousBox: null,
            nextBox: null,
            previousEaseFactor: 2.5,
            nextEaseFactor: 2.36,
            previousIntervalDays: 8,
            nextIntervalDays: 1,
          ),
        ],
        hasMore: false,
        nextCursor: null,
      ),
    );

  return repository;
}

Widget scope(
  FakeCardDetailRepository repository,
  Brightness brightness, {
  Locale? locale,
  double textScale = 1,
}) => ProviderScope(
  overrides: [cardDetailRepositoryProvider.overrideWithValue(repository)],
  child: ReviewApp(
    home: const CardDetailScreen(deckId: 'deck-1', cardId: 'card-1'),
    brightness: brightness,
    locale: locale,
    textScale: textScale,
  ),
);
